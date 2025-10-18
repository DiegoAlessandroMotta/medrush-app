import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/api/pedidos.api.dart';
import 'package:medrush/api/rutas.api.dart';
import 'package:medrush/api/ubicaciones_repartidor.api.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/providers/auth.provider.dart';
import 'package:medrush/screens/repartidor/modules/pedidos/pedidos_detalle_repartidor.dart';
import 'package:medrush/screens/repartidor/modules/ruta_map/ruta_map_widgets.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/services/polyline_decoding.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class RutaMapScreen extends StatefulWidget {
  const RutaMapScreen({super.key});

  @override
  State<RutaMapScreen> createState() => _RutaMapScreenState();
}

class _RutaMapScreenState extends State<RutaMapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Map<String, BitmapDescriptor> _numberIconCache = {};
  StreamSubscription<Position>? _positionSub;
  Timer? _tapTimer;
  Timer? _locationReportTimer;
  int _tapCount = 0;

  List<Pedido> _rutaOptimizada = [];
  final Map<String, LegInfo> _legInfoByPedidoId = {};

  // Cache del rutaId para evitar llamadas innecesarias
  String? _cachedRutaId;
  DateTime? _lastRutaIdFetch;

  // Polyline del servidor (si está disponible)
  String? _serverPolylineEncoded;

  // Pedidos que tienen polylines (para mostrar en gris los que están en cola)
  final Set<String> _pedidosConPolyline = {};

  // Cache de polylines movido a PolylineDecodingService

  // Constantes para límites de Google Directions API
  static const int _maxWaypointsGoogleAPI =
      25; // Límite de Google Directions API

  // Constantes para fuente de polylines
  static const String _polylineSourceServer = 'SERVER';
  static const String _polylineSourceGoogle = 'GOOGLE';

  // Configuración de polyline (puede ser configurada por el usuario)
  String _polylineSource =
      _polylineSourceGoogle; // Por defecto: usar Google Directions API
  // Se usa precisión estándar polyline5 (1e5) de forma fija

  bool _isLoading = true;
  String? _error;
  Position? _currentPosition;

  // Estados de carga parciales para UI
  bool _isLoadingMarkers = false;
  bool _isLoadingPolylines = false;

  // Configuración del mapa
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-12.0464, -77.0428), // Lima, Perú
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _tapTimer?.cancel();
    _locationReportTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Determina si debemos refrescar el rutaId cacheado
  /// Cache válido por 5 minutos
  bool _shouldRefreshRutaId() {
    if (_lastRutaIdFetch == null) {
      return true;
    }

    final now = DateTime.now();
    final difference = now.difference(_lastRutaIdFetch!);

    // Refrescar si han pasado más de 5 minutos
    return difference.inMinutes >= 5;
  }

  /// Cuenta las ubicaciones de recogida únicas en una lista de pedidos
  int _contarUbicacionesRecojoUnicas(List<Pedido> pedidos) {
    final ubicaciones = <String>{};
    for (final pedido in pedidos) {
      if (pedido.latitudRecojo != null && pedido.longitudRecojo != null) {
        final key = '${pedido.latitudRecojo},${pedido.longitudRecojo}';
        ubicaciones.add(key);
      }
    }
    return ubicaciones.length;
  }

  /// Cuenta las ubicaciones de entrega únicas en una lista de pedidos
  int _contarUbicacionesEntregaUnicas(List<Pedido> pedidos) {
    final ubicaciones = <String>{};
    for (final pedido in pedidos) {
      if (pedido.latitudEntrega != null && pedido.longitudEntrega != null) {
        final key = '${pedido.latitudEntrega},${pedido.longitudEntrega}';
        ubicaciones.add(key);
      }
    }
    return ubicaciones.length;
  }

  // Funciones de caché movidas a PolylineDecodingService

  Future<void> _initializeMap() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      // Obtener ubicación actual
      await _getCurrentLocation();
      // Suscribir a cambios de ubicación (solo para actualizar marcador)
      _listenLocationUpdates();

      // Mostrar el mapa de inmediato
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Paso 2: cargar ruta optimizada (sin bloquear la UI)
      await _loadRutaOptimizada();

      if (_rutaOptimizada.isNotEmpty) {
        logInfo('${_rutaOptimizada.length} pedidos en ruta optimizada');

        // Paso 3: marcar inicialmente todos los pedidos (sin polylines)
        await _crearMarcadoresIniciales();

        // Paso 4: calcular polylines en segundo plano y refrescar marcadores
        // No esperamos; mejor UX
        unawaited(() async {
          try {
            await _obtenerPolylinesConDirectionsAPI();
            await _crearMarcadoresYPolylines();
          } catch (e) {
            logError('Error calculando polylines en segundo plano', e);
          }
        }());

        // Iniciar reporte periódico de ubicación
        _startPeriodicLocationReporting();
      } else {
        logInfo('No hay ruta optimizada disponible');
      }

      logInfo('Inicialización no bloqueante completada');
    } catch (e) {
      logError('Error al inicializar mapa de rutas', e);
      if (mounted) {
        setState(() {
          _error = 'Error al cargar el mapa: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Crea marcadores rápidos (sin distinguir polylines) para mejorar TTI
  Future<void> _crearMarcadoresIniciales() async {
    _isLoadingMarkers = true;
    if (mounted) {
      setState(() {});
    }
    _markers.clear();

    // Marcador de ubicación actual si existe
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(
              title: 'Mi Ubicación', snippet: 'Ubicación actual'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    for (int i = 0; i < _rutaOptimizada.length; i++) {
      final pedido = _rutaOptimizada[i];
      final orden = pedido.ordenOptimizado ?? (i + 1);
      final latLngEntrega =
          LatLng(pedido.latitudEntrega ?? 0.0, pedido.longitudEntrega ?? 0.0);

      final iconEntrega = await _getNumberedIcon(orden);

      _markers.add(
        Marker(
          markerId: MarkerId('entrega_fast_${pedido.id}'),
          position: latLngEntrega,
          infoWindow: InfoWindow(
            title: '$orden) Entrega - ${pedido.pacienteNombre}',
            snippet: pedido.direccionEntrega,
          ),
          icon: iconEntrega,
        ),
      );
    }

    if (mounted) {
      _isLoadingMarkers = false;
      setState(() {});
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos de ubicación denegados permanentemente');
      }

      // Obtener ubicación actual
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      logInfo(
          'Ubicación actual obtenida: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
    } catch (e) {
      logError('Error al obtener ubicación actual', e);
      // Continuar sin ubicación actual
    }
  }

  void _listenLocationUpdates() {
    _positionSub?.cancel();
    final stream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Solo reportar cuando se mueva >= 100m
      ),
    );
    _positionSub = stream.listen((pos) {
      _currentPosition = pos;

      // Debug: Verificar si se está llamando el método
      logInfo(
          'Stream de ubicación recibido: ${pos.latitude}, ${pos.longitude}');

      // Solo reportar ubicación al backend si hay pedidos en estado EN_RUTA
      final pedidosEnRuta = _rutaOptimizada
          .where((p) => p.estado == EstadoPedido.enRuta)
          .toList();
      if (pedidosEnRuta.isNotEmpty) {
        logInfo(
            'Reportando ubicación por cambio de posición (pedidos en ruta: ${pedidosEnRuta.length})');
        _reportLocationToBackend(pos);
      } else {
        logInfo(
            'Saltando reporte de ubicación - no hay pedidos en estado EN_RUTA');
      }

      // Actualizar marcador de ubicación actual
      if (mounted) {
        setState(() {
          // Solo actualizar el marcador de ubicación actual
        });
      }
    });
  }

  /// Reporta la ubicación del repartidor al backend y detecta proximidad a puntos de recogida
  Future<void> _reportLocationToBackend(Position position) async {
    try {
      logInfo('Intentando reportar ubicación al backend...');

      // Solo reportar si hay pedidos en ruta optimizada
      if (_rutaOptimizada.isEmpty) {
        logWarning('No hay pedidos en ruta optimizada para reportar ubicación');
        return;
      }

      // 1. Verificar proximidad a puntos de recogida para pedidos asignados
      await _verificarProximidadRecogida(position);

      // 2. Buscar pedidos en estado EN_RUTA para reportar ubicación
      final pedidosEnRuta = _rutaOptimizada
          .where((p) => p.estado == EstadoPedido.enRuta)
          .toList();

      if (pedidosEnRuta.isEmpty) {
        logInfo('No hay pedidos en estado EN_RUTA para reportar ubicación');
        return;
      }

      // Usar el primer pedido en ruta para reportar ubicación
      final pedidoEnRuta = pedidosEnRuta.first;
      logInfo('Pedidos en ruta: ${pedidosEnRuta.length}');
      logInfo(
          'Pedido seleccionado: ${pedidoEnRuta.id} - Estado: ${pedidoEnRuta.estado}');

      // Obtener el ID del repartidor desde el AuthProvider
      if (!mounted) {
        return;
      }
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final repartidorId = authProvider.usuario?.id;

      if (repartidorId == null) {
        logWarning('No se pudo obtener ID del repartidor autenticado');
        return;
      }

      logInfo('Repartidor ID: $repartidorId');
      logInfo(
          'Reportando ubicación: ${position.latitude}, ${position.longitude}');

      await UbicacionesRepartidorApi.registrarUbicacionRepartidor(
        pedidoId: pedidoEnRuta.id,
        repartidorId: repartidorId,
        latitud: position.latitude,
        longitud: position.longitude,
      );

      logInfo(
          'Ubicación reportada exitosamente para pedido ${pedidoEnRuta.id}');
    } catch (e) {
      logError('Error al reportar ubicación al backend', e);
    }
  }

  /// Inicia el reporte periódico de ubicación cada 180 segundos (más eficiente)
  void _startPeriodicLocationReporting() {
    _locationReportTimer?.cancel();
    _locationReportTimer =
        Timer.periodic(const Duration(seconds: 180), (_) async {
      if (_currentPosition != null && _rutaOptimizada.isNotEmpty) {
        // 1. Verificar proximidad a puntos de recogida para pedidos asignados
        await _verificarProximidadRecogida(_currentPosition!);

        // 2. Verificar alejamiento de puntos de recogida para pedidos recogidos
        await _verificarAlejamientoRecogida(_currentPosition!);

        // 3. Solo reportar si hay pedidos en estado EN_RUTA
        final pedidosEnRuta = _rutaOptimizada
            .where((p) => p.estado == EstadoPedido.enRuta)
            .toList();
        if (pedidosEnRuta.isNotEmpty) {
          logInfo('⏰ Reporte periódico de ubicación (cada 180 segundos)');
          await _reportLocationToBackend(_currentPosition!);
        } else {
          logInfo(
              '⏰ Saltando reporte periódico - no hay pedidos en estado EN_RUTA');
        }
      }
    });
    logInfo('Reporte periódico de ubicación iniciado (cada 180 segundos)');
  }

  /// Verifica si el repartidor está cerca de algún punto de recogida y marca como recogido
  Future<void> _verificarProximidadRecogida(Position position) async {
    const double radioProximidad = 50.0; // 50 metros de radio

    for (final pedido in _rutaOptimizada) {
      // Solo verificar pedidos asignados que tengan coordenadas de recogida
      if (pedido.estado == EstadoPedido.asignado &&
          pedido.latitudRecojo != null &&
          pedido.longitudRecojo != null) {
        final distancia = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          pedido.latitudRecojo!,
          pedido.longitudRecojo!,
        );

        logInfo(
            'Distancia a recogida ${pedido.id}: ${StatusHelpers.formatearDistancia(distancia)}');

        // Si está dentro del radio de proximidad, marcar como recogido
        if (distancia <= radioProximidad) {
          logInfo(
              '¡Repartidor cerca del punto de recogida! Marcando pedido ${pedido.id} como recogido');

          try {
            await _marcarPedidoComoRecogido(pedido.id);
            logInfo(
                'Pedido ${pedido.id} marcado como RECOGIDO automáticamente');
          } catch (e) {
            logError('Error al marcar pedido como recogido', e);
          }
        }
      }
    }
  }

  /// Marca un pedido como recogido
  Future<void> _marcarPedidoComoRecogido(String pedidoId) async {
    try {
      await PedidosApi.marcarPedidoRecogido(pedidoId);
      logInfo('Pedido $pedidoId marcado como RECOGIDO');
    } catch (e) {
      logError('Error al marcar pedido como recogido', e);
      rethrow;
    }
  }

  /// Verifica si el repartidor se ha alejado de puntos de recogida y marca como "En Ruta"
  Future<void> _verificarAlejamientoRecogida(Position position) async {
    const double radioAlejamiento =
        100.0; // 100 metros de radio para considerar alejamiento

    for (final pedido in _rutaOptimizada) {
      // Solo verificar pedidos recogidos que tengan coordenadas de recogida
      if (pedido.estado == EstadoPedido.recogido &&
          pedido.latitudRecojo != null &&
          pedido.longitudRecojo != null) {
        final distancia = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          pedido.latitudRecojo!,
          pedido.longitudRecojo!,
        );

        logInfo(
            'Distancia desde recogida ${pedido.id}: ${StatusHelpers.formatearDistancia(distancia)}');

        // Si se ha alejado del punto de recogida, marcar como "En Ruta"
        if (distancia > radioAlejamiento) {
          logInfo(
              '¡Repartidor alejado del punto de recogida! Marcando pedido ${pedido.id} como En Ruta');

          try {
            await _cambiarEstadoPedidoAEnRuta(pedido.id);
            logInfo('Pedido ${pedido.id} marcado como EN_RUTA automáticamente');
          } catch (e) {
            logError('Error al marcar pedido como En Ruta', e);
          }
        }
      }
    }
  }

  /// Cambia el estado de un pedido a EN_RUTA
  Future<void> _cambiarEstadoPedidoAEnRuta(String pedidoId) async {
    try {
      // Cambiar estado a EN_RUTA
      await PedidosApi.marcarPedidoEnRuta(pedidoId);

      logInfo('Pedido $pedidoId marcado como EN_RUTA');
    } catch (e) {
      logError('Error al marcar pedido como EN_RUTA', e);
      rethrow;
    }
  }

  Future<void> _loadRutaOptimizada() async {
    try {
      String? rutaId = _cachedRutaId;

      // Solo obtener ruta actual si no tenemos el rutaId en cache o ha pasado mucho tiempo
      if (rutaId == null || _shouldRefreshRutaId()) {
        logInfo('Obteniendo ruta actual del repartidor...');

        try {
          // Usar el endpoint /api/rutas/current que devuelve la última ruta asignada
          final rutaActualData = await RutasOptimizadasApi.getRutaActual();

          if (rutaActualData != null && rutaActualData['ruta'] != null) {
            final rutaData = rutaActualData['ruta'] as Map<String, dynamic>;
            rutaId = rutaData['id'] as String;
            _cachedRutaId = rutaId;
            _lastRutaIdFetch = DateTime.now();
            logInfo('Ruta actual encontrada y cacheada: $rutaId');

            // Extraer polyline del servidor si está disponible
            _serverPolylineEncoded = rutaData['polyline_encoded'] as String?;
            if (_serverPolylineEncoded != null) {
              logInfo(
                  '📐 Polyline del servidor disponible: ${_serverPolylineEncoded!.length} caracteres');
            } else {
              logInfo('No hay polyline_encoded en la respuesta del servidor');
            }

            // Procesar pedidos directamente desde la respuesta del endpoint current
            final pedidosRutaData =
                rutaActualData['pedidos'] as List<dynamic>? ?? [];
            _procesarPedidosRuta(pedidosRutaData.cast<Map<String, dynamic>>());
            return;
          } else {
            logWarning('No hay ruta actual asignada al repartidor');
            _rutaOptimizada = [];
            return;
          }
        } catch (e) {
          logError('Error al obtener ruta actual del repartidor', e);
          // Si falla el endpoint current, mostrar error
          _rutaOptimizada = [];
          return;
        }
      } else {
        logInfo('Usando rutaId cacheado: $rutaId');
      }

      // Obtener pedidos de la ruta optimizada (ya ordenados por el backend)
      final pedidosRutaData = await RutasOptimizadasApi.getPedidosRuta(
        rutaId: rutaId,
      );

      if (pedidosRutaData.isNotEmpty) {
        _procesarPedidosRuta(pedidosRutaData);
      } else {
        _rutaOptimizada = [];
        logWarning('No hay pedidos en la ruta activa');
      }
    } catch (e) {
      logError('Error al cargar ruta optimizada', e);
      _rutaOptimizada = [];
    }
  }

  /// Procesa los pedidos de la ruta
  void _procesarPedidosRuta(List<Map<String, dynamic>> pedidosRutaData) {
    // Convertir datos de la API a objetos Pedido
    final todosLosPedidos = pedidosRutaData.map((pedidoData) {
      // Mapear ubicaciones de recogida y entrega
      final ubicacionRecojo =
          pedidoData['ubicacion_recojo'] as Map<String, dynamic>?;
      final ubicacionEntrega =
          pedidoData['ubicacion_entrega'] as Map<String, dynamic>?;
      final entregas = pedidoData['entregas'] as Map<String, dynamic>? ?? {};

      final pedidoMapeado = <String, dynamic>{
        'id': pedidoData['id'],
        'codigo_barra': pedidoData['codigo_barra'],
        'paciente_nombre': pedidoData['paciente_nombre'],
        'paciente_telefono': pedidoData['paciente_telefono'],
        'observaciones': pedidoData['observaciones'],
        'tipo_pedido': pedidoData['tipo_pedido'],
        'estado': pedidoData['estado'],
        'direccion_entrega': pedidoData['direccion_entrega_linea_1'],
        'ubicacion_recojo': ubicacionRecojo,
        'ubicacion_entrega': ubicacionEntrega,
        'orden_optimizado': entregas['orden_optimizado'],
        'orden_personalizado': entregas['orden_personalizado'],
        'orden_recojo': entregas['orden_recojo'],
        'optimizado': entregas['optimizado'] ?? false,
      };

      final pedido = Pedido.fromJson(pedidoMapeado);
      return pedido;
    }).toList();

    // Usar TODOS los pedidos para marcadores (no limitar por waypoints)
    _rutaOptimizada = todosLosPedidos;

    // Calcular estadísticas para logging
    final ubicacionesRecojoUnicas =
        _contarUbicacionesRecojoUnicas(todosLosPedidos);
    final ubicacionesEntregaUnicas =
        _contarUbicacionesEntregaUnicas(todosLosPedidos);

    logInfo(
        '${_rutaOptimizada.length} pedidos en ruta optimizada (TODOS los pedidos se muestran)');
    logInfo(
        'Ubicaciones únicas: $ubicacionesRecojoUnicas recogidas, $ubicacionesEntregaUnicas entregas');
    logInfo(
        'Polylines limitadas a 25 waypoints, pero marcadores muestran todos los pedidos');
  }

  Future<void> _crearMarcadoresYPolylines() async {
    _markers.clear();

    // Debug: verificar estado de polylines
    logInfo('Creando marcadores - Fuente: $_polylineSource');
    logInfo(
        'Pedidos con polyline: ${_pedidosConPolyline.length}/${_rutaOptimizada.length}');
    logInfo('IDs con polyline: ${_pedidosConPolyline.toList()}');

    // Marcador de ubicación actual
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(
            title: 'Mi Ubicación',
            snippet: 'Ubicación actual',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Agrupar pedidos por ubicación de recogida para evitar superposición
    final Map<String, List<Pedido>> pedidosPorRecojo = {};

    for (int i = 0; i < _rutaOptimizada.length; i++) {
      final pedido = _rutaOptimizada[i];
      if (pedido.latitudRecojo != null && pedido.longitudRecojo != null) {
        final key = '${pedido.latitudRecojo},${pedido.longitudRecojo}';
        pedidosPorRecojo.putIfAbsent(key, () => []).add(pedido);
      }
    }

    // Crear marcadores de recogida agrupados
    for (final entry in pedidosPorRecojo.entries) {
      final pedidos = entry.value;
      final primerPedido = pedidos.first;
      final latLngRecojo =
          LatLng(primerPedido.latitudRecojo!, primerPedido.longitudRecojo!);

      // Crear icono con todos los números
      final numeros = pedidos
          .map((p) => p.ordenOptimizado ?? (_rutaOptimizada.indexOf(p) + 1))
          .toList();
      final iconRecojo = await _getRecojoIconAgrupado(numeros);

      // Crear info window con todos los pedidos
      final titulo = numeros.length == 1
          ? '${numeros.first}) Recogida - ${primerPedido.pacienteNombre}'
          : 'Recogida (${numeros.length} pedidos)';
      final snippet = numeros.length == 1
          ? 'Punto de recogida'
          : 'Pedidos: ${numeros.join(', ')}';

      _markers.add(
        Marker(
          markerId: MarkerId('recojo_${primerPedido.id}'),
          position: latLngRecojo,
          infoWindow: InfoWindow(
            title: titulo,
            snippet: snippet,
          ),
          icon: iconRecojo,
        ),
      );
    }

    // Marcadores de entrega individuales
    for (int i = 0; i < _rutaOptimizada.length; i++) {
      final pedido = _rutaOptimizada[i];

      // Usar el orden optimizado del backend, o fallback a índice + 1
      final orden = pedido.ordenOptimizado ?? (i + 1);

      // Debug: verificar el orden
      if (kDebugMode) {
        debugPrint(
            '[Map] Pedido ${i + 1}: ${pedido.pacienteNombre} - ordenOptimizado: ${pedido.ordenOptimizado} - usando orden: $orden');
      }

      // Marcador de entrega
      final latLngEntrega =
          LatLng(pedido.latitudEntrega ?? 0.0, pedido.longitudEntrega ?? 0.0);

      // Determinar el icono basado en si tiene polyline o no
      BitmapDescriptor iconEntrega;
      final tienePolyline = _pedidosConPolyline.contains(pedido.id);

      if (_polylineSource == _polylineSourceGoogle && !tienePolyline) {
        // Pedido en cola (sin polyline) - icono gris
        iconEntrega = await _getNumberedIconGrey(orden);
        logInfo(
            'Marcador GRIS para pedido $orden (${pedido.pacienteNombre}) - sin polyline');
      } else {
        // Pedidos con polyline - icono azul (todos iguales)
        iconEntrega = await _getNumberedIcon(orden);
        logInfo(
            'Marcador AZUL para pedido $orden (${pedido.pacienteNombre}) - con polyline');
      }

      // Debug: verificar icono de entrega
      if (kDebugMode) {
        final tienePolyline = _pedidosConPolyline.contains(pedido.id);
        debugPrint(
            '[Map] Creando marcador de entrega $orden para ${pedido.pacienteNombre} - tienePolyline: $tienePolyline - fuente: $_polylineSource');
      }

      _markers.add(
        Marker(
          markerId: MarkerId('entrega_${pedido.id}'),
          position: latLngEntrega,
          infoWindow: InfoWindow(
            title: '$orden) Entrega - ${pedido.pacienteNombre}',
            snippet: _buildSnippetForPedido(pedido),
          ),
          icon: iconEntrega,
        ),
      );
    }

    if (mounted) {
      _isLoadingMarkers = false;
      setState(() {});
    }
    if (kDebugMode) {
      debugPrint(
          '[Map] markers=${_markers.length} polylines=${_polylines.length} rutaOptimizada=${_rutaOptimizada.length}');

      // Debug detallado de polylines en el mapa
      for (int i = 0; i < _polylines.length; i++) {
        final polyline = _polylines.elementAt(i);
        debugPrint(
            '[Map] Polyline $i: ${polyline.polylineId.value} - ${polyline.points.length} puntos');
      }
    }
  }

  /// Obtiene polylines usando Google Directions API (solo para dibujar, no optimizar)
  Future<void> _obtenerPolylinesConDirectionsAPI() async {
    if (_rutaOptimizada.isEmpty || _currentPosition == null) {
      return;
    }

    try {
      _isLoadingPolylines = true;
      if (mounted) {
        setState(() {});
      }
      logInfo('Dibujando polylines con Google Directions API...');

      // Limpiar polylines existentes
      _polylines.clear();

      // Siempre usar Google Directions API (limitado a 12 pedidos)
      await _crearPolylinesDiferenciadas();

      if (mounted) {
        _isLoadingPolylines = false;
        setState(() {});
      }
    } catch (e) {
      logError('Error al dibujar polylines', e);
      // Sin fallback - solo usar Google Directions API
      if (mounted) {
        _isLoadingPolylines = false;
        setState(() {});
      }
    }
  }

  Future<BitmapDescriptor> _getNumberedIcon(int number) async {
    final String cacheKey = number.toString();
    if (_numberIconCache.containsKey(cacheKey)) {
      return _numberIconCache[cacheKey]!;
    }
    const int size = 36; // tamaño más pequeño como los de cola
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()
      ..color = MedRushTheme.primaryBlue; // azul para entrega

    // Fondo círculo
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.2, paint);

    // Texto número más pequeño
    final ui.ParagraphBuilder pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 16, // texto más pequeño como los de cola
        fontWeight: FontWeight.w600,
      ),
    )
      ..pushStyle(ui.TextStyle(color: const Color(0xFFFFFFFF)))
      ..addText(number.toString());

    final ui.Paragraph paragraph = pb.build()
      ..layout(ui.ParagraphConstraints(width: size.toDouble()));
    canvas.drawParagraph(paragraph, Offset(0, (size - paragraph.height) / 2));

    final ui.Image image = await recorder.endRecording().toImage(size, size);
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List list = bytes!.buffer.asUint8List();
    final icon = BitmapDescriptor.bytes(list);
    _numberIconCache[cacheKey] = icon;
    return icon;
  }

  /// Crea iconos para puntos de recogida agrupados (múltiples números)
  Future<BitmapDescriptor> _getRecojoIconAgrupado(List<int> numbers) async {
    final String cacheKey = 'recojo_agrupado_${numbers.join('_')}';
    if (_numberIconCache.containsKey(cacheKey)) {
      return _numberIconCache[cacheKey]!;
    }

    const int size = 60; // Más grande para el texto
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()
      ..color = const Color(0xFF9C27B0); // morado para recogida

    // Fondo círculo
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.2, paint);

    // Texto "Recoger (X)"
    final ui.ParagraphBuilder pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 11, // Tamaño para que quepa bien
        fontWeight: FontWeight.w600,
      ),
    )
      ..pushStyle(ui.TextStyle(color: const Color(0xFFFFFFFF)))
      ..addText('Recoger (${numbers.length})');

    final ui.Paragraph paragraph = pb.build()
      ..layout(ui.ParagraphConstraints(width: size.toDouble()));
    canvas.drawParagraph(paragraph, Offset(0, (size - paragraph.height) / 2));

    final ui.Image image = await recorder.endRecording().toImage(size, size);
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List list = bytes!.buffer.asUint8List();
    final icon = BitmapDescriptor.bytes(list);
    _numberIconCache[cacheKey] = icon;
    return icon;
  }

  /// Crea iconos numerados grises para pedidos en cola (sin polyline)
  Future<BitmapDescriptor> _getNumberedIconGrey(int number) async {
    final String cacheKey = 'grey_$number';
    if (_numberIconCache.containsKey(cacheKey)) {
      return _numberIconCache[cacheKey]!;
    }
    const int size = 36;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()
      ..color = const Color(0xFF9E9E9E); // gris para pedidos en cola

    // Fondo círculo
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.2, paint);

    // Texto número
    final ui.ParagraphBuilder pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    )
      ..pushStyle(ui.TextStyle(color: const Color(0xFFFFFFFF)))
      ..addText(number.toString());

    final ui.Paragraph paragraph = pb.build()
      ..layout(ui.ParagraphConstraints(width: size.toDouble()));
    canvas.drawParagraph(paragraph, Offset(0, (size - paragraph.height) / 2));

    final ui.Image image = await recorder.endRecording().toImage(size, size);
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List list = bytes!.buffer.asUint8List();
    final icon = BitmapDescriptor.bytes(list);
    _numberIconCache[cacheKey] = icon;
    return icon;
  }

  /// Navega inteligentemente según el estado del pedido
  Future<void> _navegarARutaCompleta(Pedido pedido) async {
    try {
      logInfo(
          'Iniciando navegación inteligente para pedido ${pedido.id} - Estado: ${pedido.estado}');

      String destination = '';
      String action = '';

      // Lógica inteligente según el estado del pedido
      switch (pedido.estado) {
        case EstadoPedido.asignado:
          // Solo navegar al punto de recogida
          if (pedido.latitudRecojo != null && pedido.longitudRecojo != null) {
            destination = '${pedido.latitudRecojo},${pedido.longitudRecojo}';
            action = 'recogida';
            logInfo(
                'Navegando a punto de RECOGIDA: ${pedido.latitudRecojo}, ${pedido.longitudRecojo}');
          } else {
            logWarning('No hay coordenadas de recogida para pedido asignado');
            _mostrarErrorNavegacion('No hay ubicación de recogida disponible');
            return;
          }

        case EstadoPedido.recogido:
        case EstadoPedido.enRuta:
          // Solo navegar al punto de entrega
          if (pedido.latitudEntrega != null && pedido.longitudEntrega != null) {
            destination = '${pedido.latitudEntrega},${pedido.longitudEntrega}';
            action = 'entrega';
            logInfo(
                'Navegando a punto de ENTREGA: ${pedido.latitudEntrega}, ${pedido.longitudEntrega}');
          } else {
            logWarning('No hay coordenadas de entrega para pedido recogido');
            _mostrarErrorNavegacion('No hay ubicación de entrega disponible');
            return;
          }

        case EstadoPedido.pendiente:
          // Para pedidos pendientes, intentar recogida primero
          if (pedido.latitudRecojo != null && pedido.longitudRecojo != null) {
            destination = '${pedido.latitudRecojo},${pedido.longitudRecojo}';
            action = 'recogida';
            logInfo(
                'Navegando a punto de RECOGIDA (pendiente): ${pedido.latitudRecojo}, ${pedido.longitudRecojo}');
          } else if (pedido.latitudEntrega != null &&
              pedido.longitudEntrega != null) {
            destination = '${pedido.latitudEntrega},${pedido.longitudEntrega}';
            action = 'entrega';
            logInfo(
                'Navegando a punto de ENTREGA (pendiente): ${pedido.latitudEntrega}, ${pedido.longitudEntrega}');
          } else {
            logWarning('No hay coordenadas válidas para pedido pendiente');
            _mostrarErrorNavegacion('No hay ubicaciones válidas para navegar');
            return;
          }

        case EstadoPedido.entregado:
        case EstadoPedido.fallido:
        case EstadoPedido.cancelado:
          logWarning(
              'No se puede navegar a pedido con estado: ${pedido.estado}');
          _mostrarErrorNavegacion('Este pedido ya fue procesado');
          return;
      }

      if (destination.isEmpty) {
        logWarning('No se pudo determinar el destino de navegación');
        _mostrarErrorNavegacion('No hay ubicación válida para navegar');
        return;
      }

      // Construir URL de Google Maps
      final url =
          'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving';

      logInfo('🌐 Abriendo Google Maps para $action: $url');

      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        logInfo('Google Maps abierto exitosamente para $action');
      } else {
        logError('No se pudo abrir Google Maps');
        _mostrarErrorNavegacion('No se pudo abrir Google Maps');
      }
    } catch (e) {
      logError('Error en navegación', e);
      _mostrarErrorNavegacion('Error al abrir la navegación');
    }
  }

  /// Muestra un error de navegación
  void _mostrarErrorNavegacion(String mensaje) {
    if (mounted) {
      NotificationService.showError(
        mensaje,
        context: context,
      );
    }
  }

  void _verDetallePedido(Pedido pedido) {
    logInfo('Ver detalles del pedido #${pedido.id}');

    showMaterialModalBottomSheet(
      context: context,
      expand: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PedidoDetalleScreen(pedidoId: pedido.id),
    );
  }

  Future<void> _recargarRuta() async {
    try {
      logInfo('Recargando ruta optimizada...');

      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      // Limpiar datos existentes
      _rutaOptimizada.clear();
      _legInfoByPedidoId.clear();
      _markers.clear();
      _polylines.clear();
      _pedidosConPolyline.clear();

      // Limpiar cache para forzar recarga completa
      _cachedRutaId = null;
      _lastRutaIdFetch = null;
      _serverPolylineEncoded = null;

      // Limpiar cache de polylines
      PolylineDecodingService.clearPolylineCache();
      logInfo('🧹 Cache de polylines limpiado para recarga completa');

      // Recargar ruta optimizada
      await _loadRutaOptimizada();

      if (_rutaOptimizada.isNotEmpty) {
        logInfo('${_rutaOptimizada.length} pedidos recargados');

        // Recrear polylines primero, luego marcadores
        await _obtenerPolylinesConDirectionsAPI();
        await _crearMarcadoresYPolylines();
      } else {
        logWarning('No hay pedidos en la ruta después de recargar');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Mostrar mensaje de éxito
      if (mounted) {
        NotificationService.showSuccess(
          'Ruta recargada: ${_rutaOptimizada.length} pedidos',
          context: context,
          duration: const Duration(seconds: 2),
        );
      }

      logInfo('Ruta recargada exitosamente');
    } catch (e) {
      logError('Error al recargar ruta', e);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error al recargar: $e';
        });

        NotificationService.showError(
          'Error al recargar ruta: $e',
          context: context,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  /// Re-optimiza la ruta actual usando Google Route Optimization API
  Future<void> _reOptimizarRuta() async {
    if (_cachedRutaId == null) {
      logWarning('No hay ruta activa para re-optimizar');
      return;
    }

    try {
      logInfo('Re-optimizando ruta: $_cachedRutaId');

      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Obtener horarios de jornada (usar horarios por defecto)
      final now = DateTime.now();
      final inicioJornada =
          DateTime(now.year, now.month, now.day, 8).toIso8601String();
      final finJornada =
          DateTime(now.year, now.month, now.day, 18).toIso8601String();

      // Llamar a la API de re-optimización
      await RutasOptimizadasApi.reOptimizarRuta(
        rutaId: _cachedRutaId!,
        inicioJornada: inicioJornada,
        finJornada: finJornada,
      );

      // Recargar la ruta con el nuevo orden optimizado
      await _recargarRuta();

      if (mounted) {
        NotificationService.showInfo(
          'Ruta re-optimizada: ${_rutaOptimizada.length} pedidos',
          context: context,
          duration: const Duration(seconds: 3),
        );
      }

      logInfo('Ruta re-optimizada exitosamente');
    } catch (e) {
      logError('Error al re-optimizar ruta', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        NotificationService.showError(
          'Error al re-optimizar: $e',
          context: context,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  /// Pobla la información de leg para cada pedido con polyline (fallback)
  void _poblarLegInfoParaPedidos() {
    _legInfoByPedidoId.clear();

    if (_rutaOptimizada.isEmpty) {
      return;
    }

    // Calcular tiempos estimados basados en la distancia real entre pedidos
    int tiempoAcumulativo = 0;

    for (int i = 0; i < _rutaOptimizada.length; i++) {
      final pedido = _rutaOptimizada[i];

      // Solo agregar leg info para pedidos que tienen polyline
      if (_pedidosConPolyline.contains(pedido.id)) {
        // Calcular distancia real al siguiente pedido
        double distanciaKm = 0.0;
        int tiempoEstimado = 5; // Tiempo base mínimo

        if (i < _rutaOptimizada.length - 1) {
          // Calcular distancia al siguiente pedido
          final pedidoActual = pedido;
          final pedidoSiguiente = _rutaOptimizada[i + 1];

          if (pedidoActual.latitudEntrega != null &&
              pedidoActual.longitudEntrega != null &&
              pedidoSiguiente.latitudEntrega != null &&
              pedidoSiguiente.longitudEntrega != null) {
            distanciaKm = Geolocator.distanceBetween(
                  pedidoActual.latitudEntrega!,
                  pedidoActual.longitudEntrega!,
                  pedidoSiguiente.latitudEntrega!,
                  pedidoSiguiente.longitudEntrega!,
                ) /
                1000.0; // Convertir a km
          }
        } else {
          // Último pedido - distancia desde el anterior
          if (i > 0) {
            final pedidoAnterior = _rutaOptimizada[i - 1];
            if (pedidoAnterior.latitudEntrega != null &&
                pedidoAnterior.longitudEntrega != null &&
                pedido.latitudEntrega != null &&
                pedido.longitudEntrega != null) {
              distanciaKm = Geolocator.distanceBetween(
                    pedidoAnterior.latitudEntrega!,
                    pedidoAnterior.longitudEntrega!,
                    pedido.latitudEntrega!,
                    pedido.longitudEntrega!,
                  ) /
                  1000.0; // Convertir a km
            }
          }
        }

        // Calcular tiempo basado en distancia (velocidad promedio 30 km/h en ciudad)
        if (distanciaKm > 0) {
          tiempoEstimado =
              (distanciaKm / 30.0 * 60).round(); // Convertir a minutos
          tiempoEstimado = tiempoEstimado.clamp(3, 25); // Entre 3 y 25 minutos
        } else {
          tiempoEstimado = 8; // Tiempo por defecto si no hay distancia
        }

        tiempoAcumulativo += tiempoEstimado;

        final legInfo = LegInfo(
          StatusHelpers.formatearDistanciaKm(distanciaKm), // distanceText
          '$tiempoEstimado min', // durationText
          tiempoEstimado * 60, // durationSeconds
          '$tiempoAcumulativo min', // cumulativeDurationText
          tiempoAcumulativo * 60, // cumulativeDurationSeconds
        );

        _legInfoByPedidoId[pedido.id] = legInfo;
        logInfo(
            'Leg info para pedido ${pedido.id}: ${legInfo.distanceText}, ${legInfo.durationText}, ${legInfo.cumulativeDurationText}');
      }
    }

    logInfo('Leg info poblada para ${_legInfoByPedidoId.length} pedidos');
  }

  /// Cambia el orden personalizado de un pedido
  Future<void> _cambiarOrdenPedido(Pedido pedido, int nuevoOrden) async {
    try {
      logInfo('📝 Cambiando orden del pedido ${pedido.id} a $nuevoOrden');

      // Actualizar orden personalizado en el backend
      await RutasOptimizadasApi.actualizarOrdenPersonalizado(
        pedidoId: pedido.id,
        ordenPersonalizado: nuevoOrden,
      );

      // Recargar la ruta para reflejar el cambio
      await _recargarRuta();

      if (mounted) {
        NotificationService.showSuccess(
          'Orden actualizado: Pedido #${pedido.id} → Posición $nuevoOrden',
          context: context,
          duration: const Duration(seconds: 2),
        );
      }

      logInfo('Orden del pedido actualizado exitosamente');
    } catch (e) {
      logError('Error al cambiar orden del pedido', e);
      if (mounted) {
        NotificationService.showError(
          'Error al cambiar orden: $e',
          context: context,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  /// Muestra un diálogo para cambiar el orden de un pedido
  void _mostrarDialogoCambiarOrden(Pedido pedido) {
    final controller = TextEditingController();
    final ordenActual =
        pedido.ordenPersonalizado ?? pedido.ordenOptimizado ?? 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cambiar orden - Pedido #${pedido.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Paciente: ${pedido.pacienteNombre}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Nuevo orden',
                hintText: 'Orden actual: $ordenActual',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nuevoOrden = int.tryParse(controller.text);
              if (nuevoOrden != null && nuevoOrden > 0) {
                Navigator.of(context).pop();
                await _cambiarOrdenPedido(pedido, nuevoOrden);
              } else {
                NotificationService.showWarning(
                  'Por favor ingresa un número válido',
                  context: context,
                );
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        _positionSub?.cancel();
      },
      child: Scaffold(
        backgroundColor: MedRushTheme.backgroundPrimary,
        body: _isLoading
            ? _buildLoadingState()
            : _error != null
                ? _buildErrorState()
                : _buildMapContent(),
      ),
    );
  }

  /// Crea polylines usando la fuente seleccionada (servidor o Google Directions API)
  Future<void> _crearPolylinesDiferenciadas() async {
    if (_rutaOptimizada.isEmpty) {
      return;
    }

    _polylines.clear();

    if (_polylineSource == _polylineSourceServer &&
        _serverPolylineEncoded != null) {
      // Usar polyline del servidor
      await _crearPolylinesDesdeServidor();
    } else {
      // Usar Google Directions API
      await _crearRutaOptimizadaConWaypoints();
    }

    logInfo(
        'Ruta optimizada creada: ${_polylines.length} polylines (fuente: $_polylineSource)');

    // Debug detallado de polylines usando el servicio
    PolylineDecodingService.logMultiplePolylines(_polylines.toList());
  }

  /// Crea polylines usando el polyline_encoded del servidor
  Future<void> _crearPolylinesDesdeServidor() async {
    if (_serverPolylineEncoded == null || _serverPolylineEncoded!.isEmpty) {
      logWarning('No hay polyline del servidor disponible');
      return;
    }

    try {
      logInfo('📐 Decodificando polyline del servidor...');

      // Limpiar pedidos con polyline para recalcular
      _pedidosConPolyline.clear();

      // Decodificar polyline del servidor
      final polylinePoints =
          PolylineDecodingService.decodePolylineManual(_serverPolylineEncoded!);

      if (polylinePoints.isNotEmpty) {
        _polylines.add(
          PolylineDecodingService.createServerPolyline(
              'ruta_servidor', polylinePoints),
        );
        logInfo(
            'Polyline del servidor creada con ${polylinePoints.length} puntos');

        // Marcar TODOS los pedidos como que tienen polyline (servidor incluye todos)
        for (final pedido in _rutaOptimizada) {
          _pedidosConPolyline.add(pedido.id);
        }
        logInfo(
            'Todos los ${_rutaOptimizada.length} pedidos marcados como con polyline (servidor)');

        // Poblar información de leg para todos los pedidos
        _poblarLegInfoParaPedidos();
      } else {
        logWarning(
            'No se pudieron decodificar puntos del polyline del servidor');
      }
    } catch (e) {
      logError('Error al decodificar polyline del servidor', e);
    }
  }

  /// Crea una ruta optimizada usando una sola llamada a Google Directions API con waypoints
  Future<void> _crearRutaOptimizadaConWaypoints() async {
    if (_currentPosition == null) {
      return;
    }

    try {
      // 1. Preparar waypoints únicos (evitar duplicados)
      final List<LatLng> waypoints = [];
      final Set<String> ubicacionesUnicas = {};
      final Set<String> ubicacionesRecojoUnicas = {};

      // Agregar ubicación de recogida (si es única)
      final ubicacionRecojo = LatLng(
        _rutaOptimizada.first.latitudRecojo ?? 0.0,
        _rutaOptimizada.first.longitudRecojo ?? 0.0,
      );
      final keyRecojo = StatusHelpers.formatearCoordenadasAltaPrecision(
          ubicacionRecojo.latitude, ubicacionRecojo.longitude);
      if (!ubicacionesUnicas.contains(keyRecojo)) {
        waypoints.add(ubicacionRecojo);
        ubicacionesUnicas.add(keyRecojo);
        ubicacionesRecojoUnicas.add(keyRecojo);
      }

      // Limpiar pedidos con polyline para recalcular
      _pedidosConPolyline.clear();

      // Agregar ubicaciones de entrega en orden optimizado (limitado a 25 waypoints)
      int waypointsAgregados = 0;
      for (final pedido in _rutaOptimizada) {
        if (pedido.latitudEntrega != null && pedido.longitudEntrega != null) {
          final ubicacionEntrega = LatLng(
            pedido.latitudEntrega!,
            pedido.longitudEntrega!,
          );
          final keyEntrega = StatusHelpers.formatearCoordenadasAltaPrecision(
              ubicacionEntrega.latitude, ubicacionEntrega.longitude);

          if (!ubicacionesUnicas.contains(keyEntrega)) {
            waypoints.add(ubicacionEntrega);
            ubicacionesUnicas.add(keyEntrega);
            waypointsAgregados++;

            // Marcar este pedido como que tiene polyline (solo los que se incluyen en waypoints)
            _pedidosConPolyline.add(pedido.id);

            // Limitar a 25 waypoints totales (incluyendo ubicación actual + recogida)
            if (waypoints.length >= _maxWaypointsGoogleAPI) {
              logInfo(
                  'Límite de $_maxWaypointsGoogleAPI waypoints alcanzado. Solo los primeros $waypointsAgregados pedidos tendrán polyline.');
              break;
            }
          }
        }
      }

      logInfo(
          'Creando ruta optimizada con ${waypoints.length} waypoints únicos');
      logInfo('Ubicaciones únicas totales: ${ubicacionesUnicas.length}');
      logInfo(
          'Ubicaciones de recogida únicas: ${ubicacionesRecojoUnicas.length}');
      logInfo(
          'Pedidos con polyline: ${_pedidosConPolyline.length}/${_rutaOptimizada.length}');

      // 2. Crear ruta principal con Google Directions API
      final origen =
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

      // Si hay menos de 2 waypoints, no crear polyline
      if (waypoints.length < 2) {
        logInfo('Menos de 2 waypoints, no se puede crear polyline');
        return;
      }

      final destino = waypoints.last;
      final waypointsIntermedios = waypoints.length > 2
          ? waypoints.sublist(1, waypoints.length - 1)
          : <LatLng>[];

      logInfo('Origen: ${origen.latitude}, ${origen.longitude}');
      logInfo('Destino: ${destino.latitude}, ${destino.longitude}');
      logInfo('Waypoints intermedios: ${waypointsIntermedios.length}');

      logInfo('Llamando a _obtenerPolylineConWaypoints...');
      final polylinePoints = await _obtenerPolylineConWaypoints(
        origen: origen,
        destino: destino,
        waypoints: waypointsIntermedios,
      );
      logInfo(
          '_obtenerPolylineConWaypoints completado. Puntos: ${polylinePoints.length}');

      if (polylinePoints.isNotEmpty) {
        _polylines.add(
          PolylineDecodingService.createOptimizedPolyline(
              'ruta_optimizada', polylinePoints),
        );
        logInfo('Ruta optimizada creada con ${polylinePoints.length} puntos');

        // Obtener información inteligente de tiempos según estado de pedidos
        final legInfoMap = await PolylineDecodingService.getSmartRouteInfo(
          origen: origen,
          pedidos: _rutaOptimizada,
          pedidosConPolyline: _pedidosConPolyline,
        );
        _legInfoByPedidoId.addAll(legInfoMap);
      }

      // 3. Crear polyline de recogida (morado) solo si hay múltiples ubicaciones de recogida
      logInfo(
          'Evaluando condición: ubicacionesRecojoUnicas.length (${ubicacionesRecojoUnicas.length}) > 1');
      if (ubicacionesRecojoUnicas.isNotEmpty) {
        logInfo(
            '🟣 Creando polyline de recogida separada (múltiples ubicaciones de recogida)');
        await _crearPolylineRecogidaConDirections(_rutaOptimizada);
      }
    } catch (e) {
      logError('Error creando ruta optimizada: $e');
      logError('Stack trace: ${StackTrace.current}');
      // Sin fallback - solo usar Google Directions API
    }
  }

  /// Crea polyline de recogida usando Google Directions API
  Future<void> _crearPolylineRecogidaConDirections(List<Pedido> pedidos) async {
    if (_currentPosition == null) {
      return;
    }

    final List<LatLng> puntosRecojo = [
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
    ]

        // Agregar ubicación actual como origen

        ;

    // Agregar puntos de recogida únicos (evitar duplicados)
    for (final pedido in pedidos) {
      if (pedido.latitudRecojo != null && pedido.longitudRecojo != null) {
        final punto = LatLng(pedido.latitudRecojo!, pedido.longitudRecojo!);
        // Solo agregar si no existe ya (tolerancia de 0.0001 grados ≈ 11 metros)
        if (!puntosRecojo.any((p) =>
            (p.latitude - punto.latitude).abs() < 0.0001 &&
            (p.longitude - punto.longitude).abs() < 0.0001)) {
          puntosRecojo.add(punto);
        }
      }
    }

    // Siempre usar Google Directions API para obtener la ruta real
    if (puntosRecojo.length > 1) {
      try {
        final polylinePoints =
            await _obtenerPolylineConDirectionsAPI(puntosRecojo);
        if (polylinePoints.isNotEmpty) {
          _polylines.add(
            PolylineDecodingService.createPickupPolyline(
                'ruta_recojo', polylinePoints),
          );
          logInfo(
              '🟢 Polyline de recogida creada con Google Directions API: ${polylinePoints.length} puntos');
        }
      } catch (e) {
        logError('Error al crear polyline de recogida con Directions API', e);
        // Sin fallback - solo usar Google Directions API
      }
    } else if (puntosRecojo.length == 2) {
      // Si solo hay 2 puntos, usar Google Directions API también
      try {
        final polylinePoints =
            await _obtenerPolylineConDirectionsAPI(puntosRecojo);
        if (polylinePoints.isNotEmpty) {
          _polylines.add(
            PolylineDecodingService.createSimplePickupPolyline(
                'ruta_recojo_simple', polylinePoints),
          );
          logInfo(
              '🟢 Polyline de recogida simple creada con Google Directions API');
        }
      } catch (e) {
        logError('Error al crear polyline simple de recogida', e);
      }
    }
  }

  /// Obtiene polyline usando Google Directions API con waypoints optimizados
  Future<List<LatLng>> _obtenerPolylineConWaypoints({
    required LatLng origen,
    required LatLng destino,
    required List<LatLng> waypoints,
  }) {
    return PolylineDecodingService.getPolylineWithWaypoints(
      origen: origen,
      destino: destino,
      waypoints: waypoints,
    );
  }

  Future<List<LatLng>> _obtenerPolylineConDirectionsAPI(
      List<LatLng> waypoints) {
    return PolylineDecodingService.getPolylineWithDirectionsAPI(waypoints);
  }

  // Función _extraerInformacionDeRuta movida a PolylineDecodingService

  // Función _formatDuration movida a PolylineDecodingService

  // Web-only JS helpers eliminados: Android/iOS usan REST

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: MedRushTheme.primaryGreen,
          ),
          SizedBox(height: MedRushTheme.spacingLg),
          Text(
            'Cargando mapa de rutas...',
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeBodyLarge,
              color: MedRushTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.triangleAlert,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: MedRushTheme.spacingLg),
          const Text(
            'Error al cargar el mapa',
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeTitleLarge,
              fontWeight: MedRushTheme.fontWeightBold,
              color: MedRushTheme.textPrimary,
            ),
          ),
          const SizedBox(height: MedRushTheme.spacingMd),
          Text(
            _error ?? 'Error desconocido',
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeBodyMedium,
              color: MedRushTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MedRushTheme.spacingLg),
          ElevatedButton.icon(
            onPressed: _initializeMap,
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MedRushTheme.primaryGreen,
              foregroundColor: MedRushTheme.textInverse,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent() {
    return Column(
      children: [
        // Mapa
        Expanded(
          child: Stack(
            children: [
              AbsorbPointer(
                absorbing: false,
                child: GoogleMap(
                  initialCameraPosition: _initialPosition,
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    logInfo('Controlador del mapa inicializado');
                  },
                  onTap: (LatLng position) {
                    // Manejar toque en el mapa
                    logInfo(
                        'Toque en mapa: ${position.latitude}, ${position.longitude}');
                  },
                ),
              ),
              // Overlay de carga flotante para procesos parciales
              if (_isLoadingMarkers || _isLoadingPolylines)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: MedRushTheme.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: MedRushTheme.borderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isLoadingMarkers && _isLoadingPolylines
                              ? 'Cargando marcadores y rutas...'
                              : _isLoadingMarkers
                                  ? 'Cargando marcadores...'
                                  : 'Calculando rutas...',
                          style: const TextStyle(
                            fontSize: MedRushTheme.fontSizeBodySmall,
                            color: MedRushTheme.textPrimary,
                            fontWeight: MedRushTheme.fontWeightMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_rutaOptimizada.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 110, // subir un poco más para despegar del navbar
                  child: RutaMapCarousel(
                    rutaOptimizada: _rutaOptimizada,
                    legInfoByPedidoId: _legInfoByPedidoId,
                    onCardTap: _handleCardTap,
                    onFocusMeAndPedido: _focusMeAndPedido,
                    onNavegarAEntrega: _navegarARutaCompleta,
                    formatDistanceFromMe: _formatDistanceFromMe,
                  ),
                ),
              // Botón desplegable con acciones
              Positioned(
                top: 12,
                right: 12,
                child: _buildFloatingActionMenu(),
              ),
            ],
          ),
        ),

        // Sin lista fija; se abre con modal sheet (botón arriba)
      ],
    );
  }

  /// Construye el menú de acciones flotante
  Widget _buildFloatingActionMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'reload':
            _recargarRuta();
          case 'list':
            _openEntregasSheet();
          case 'reoptimize':
            if (_cachedRutaId != null) {
              _reOptimizarRuta();
            }
          case 'polyline_source':
            _togglePolylineSource();
        }
      },
      itemBuilder: (context) => [
        // Botón de recarga
        const PopupMenuItem(
          value: 'reload',
          child: Row(
            children: [
              Icon(
                LucideIcons.rotateCcw,
                color: MedRushTheme.primaryGreen,
                size: 18,
              ),
              SizedBox(width: 12),
              Text('Recargar ruta'),
            ],
          ),
        ),
        // Botón de re-optimización (solo si hay ruta activa)
        if (_cachedRutaId != null)
          const PopupMenuItem(
            value: 'reoptimize',
            child: Row(
              children: [
                Icon(
                  LucideIcons.refreshCw,
                  color: MedRushTheme.primaryBlue,
                  size: 18,
                ),
                SizedBox(width: 12),
                Text('Re-optimizar ruta'),
              ],
            ),
          ),
        // Configuración de fuente de polyline
        PopupMenuItem(
          value: 'polyline_source',
          child: Row(
            children: [
              const Icon(
                LucideIcons.database,
                color: MedRushTheme.primaryGreen,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Fuente de polylines'),
                    Text(
                      _polylineSource == _polylineSourceServer
                          ? 'Servidor (${_serverPolylineEncoded?.length ?? 0} chars)'
                          : 'Google Directions API',
                      style: const TextStyle(
                        fontSize: 12,
                        color: MedRushTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Botón de lista de entregas (solo si hay pedidos)
        if (_rutaOptimizada.isNotEmpty)
          PopupMenuItem(
            value: 'list',
            child: Row(
              children: [
                const Icon(
                  LucideIcons.list,
                  color: MedRushTheme.primaryBlue,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text('Ver entregas (${_rutaOptimizada.length})'),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.all(MedRushTheme.spacingMd),
        decoration: BoxDecoration(
          color: MedRushTheme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          LucideIcons.ellipsis,
          color: MedRushTheme.textPrimary,
          size: 20,
        ),
      ),
    );
  }

  void _openEntregasSheet() {
    if (_rutaOptimizada.isEmpty) {
      return;
    }
    showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return RutaMapList(
          rutaOptimizada: _rutaOptimizada,
          pedidosEnCola: const [], // Ya no hay pedidos en cola
          pedidosConPolyline: _pedidosConPolyline,
          legInfoByPedidoId: _legInfoByPedidoId,
          onCardTap: _handleCardTap,
          onFocusPedido: _focusOnPedido,
          onNavegarAEntrega: _navegarARutaCompleta,
          onVerDetallePedido: _verDetallePedido,
          onChangeOrder: _mostrarDialogoCambiarOrden,
          onReOptimizarRuta: _reOptimizarRuta,
          formatDistanceFromMe: _formatDistanceFromMe,
        );
      },
    );
  }

  void _handleCardTap(Pedido pedido) {
    _tapCount += 1;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 275), () async {
      final count = _tapCount;
      _tapCount = 0;
      if (count >= 3) {
        await _focusRemainingRouteFrom(pedido);
      } else if (count == 2) {
        await _focusMeAndPedido(pedido);
      } else {
        await _focusOnPedido(pedido);
      }
    });
  }

  Future<void> _focusRemainingRouteFrom(Pedido pedido) async {
    if (_mapController == null) {
      return;
    }

    // Construir bounds con mi ubicación + destinos restantes
    final startIndex = _rutaOptimizada.indexWhere((p) => p.id == pedido.id);
    if (startIndex < 0) {
      await _focusOnPedido(pedido);
      return;
    }

    final points = <LatLng>[];
    if (_currentPosition != null) {
      points
          .add(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
    }
    for (int i = startIndex; i < _rutaOptimizada.length; i++) {
      final p = _rutaOptimizada[i];
      if (p.latitudEntrega != null && p.longitudEntrega != null) {
        points.add(LatLng(p.latitudEntrega!, p.longitudEntrega!));
      }
    }

    if (points.length < 2) {
      await _focusOnPedido(pedido);
      return;
    }

    double south = points.first.latitude;
    double north = points.first.latitude;
    double west = points.first.longitude;
    double east = points.first.longitude;
    for (final p in points) {
      if (p.latitude < south) {
        south = p.latitude;
      }
      if (p.latitude > north) {
        north = p.latitude;
      }
      if (p.longitude < west) {
        west = p.longitude;
      }
      if (p.longitude > east) {
        east = p.longitude;
      }
    }
    final bounds = LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 72),
      );
    } catch (_) {
      await _focusOnPedido(pedido);
    }
  }

  Future<void> _focusMeAndPedido(Pedido pedido) async {
    if (_mapController == null) {
      return;
    }
    final LatLng destino =
        LatLng(pedido.latitudEntrega ?? 0.0, pedido.longitudEntrega ?? 0.0);
    final LatLng? origen = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : null;

    if (origen == null) {
      // Si no hay ubicación actual, solo enfocar el pedido
      await _focusOnPedido(pedido);
      return;
    }

    final double south = (origen.latitude < destino.latitude)
        ? origen.latitude
        : destino.latitude;
    final double north = (origen.latitude > destino.latitude)
        ? origen.latitude
        : destino.latitude;
    final double west = (origen.longitude < destino.longitude)
        ? origen.longitude
        : destino.longitude;
    final double east = (origen.longitude > destino.longitude)
        ? origen.longitude
        : destino.longitude;

    final bounds = LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  String? _formatDistanceFromMe(Pedido pedido) {
    if (_currentPosition == null) {
      return null;
    }
    final meters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      pedido.latitudEntrega ?? 0.0,
      pedido.longitudEntrega ?? 0.0,
    );
    final km = meters / 1000.0;
    return km < 1.0
        ? StatusHelpers.formatearDistancia(meters)
        : StatusHelpers.formatearDistanciaKm(km);
  }

  String _buildSnippetForPedido(Pedido pedido) {
    final info = _legInfoByPedidoId[pedido.id];
    final desdeMi = _formatDistanceFromMe(pedido);

    // Construir snippet con información esencial (InfoWindow tiene limitaciones)
    final List<String> parts = [];

    // Dirección de entrega
    if (pedido.direccionEntrega.isNotEmpty) {
      parts.add('Dirección: ${pedido.direccionEntrega}');
    }

    // Tipo de pedido
    final tipoTexto = StatusHelpers.tipoPedidoTexto(pedido.tipoPedido);
    parts.add('Tipo: $tipoTexto');

    // Información de ruta (si está disponible)
    if (info != null) {
      parts
        ..add(
            'Tiempo: ${info.durationText} (siguiente) | ${info.cumulativeDurationText} (total)')
        ..add(
            'Distancia: ${info.distanceText}${desdeMi != null ? ' • $desdeMi desde ti' : ''}');
    } else if (desdeMi != null) {
      parts.add('Distancia: $desdeMi desde ti');
    }

    // Observaciones (si existen)
    if (pedido.observaciones != null && pedido.observaciones!.isNotEmpty) {
      parts.add('Observaciones: ${pedido.observaciones}');
    }

    return parts.join('\n');
  }

  Future<void> _focusOnPedido(Pedido pedido) async {
    final LatLng latLng =
        LatLng(pedido.latitudEntrega ?? 0.0, pedido.longitudEntrega ?? 0.0);
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 15.5),
      );
      // Mostrar InfoWindow si existe el marcador
      _mapController!.showMarkerInfoWindow(MarkerId('pedido_${pedido.id}'));
    }

    // SnackBar removido - estorbaba en el grid
  }

  /// Configura la fuente de polyline (SERVIDOR o GOOGLE)
  void _configurarFuentePolyline(String fuente) {
    if (_polylineSource != fuente) {
      _polylineSource = fuente;
      logInfo('📐 Fuente de polyline cambiada a: $fuente');

      // Limpiar cache para forzar regeneración con nueva fuente
      PolylineDecodingService.clearPolylineCache();
      logInfo('🧹 Cache de polylines limpiado para nueva fuente');

      // Regenerar polylines con nueva fuente
      if (_rutaOptimizada.isNotEmpty) {
        _obtenerPolylinesConDirectionsAPI();
        _crearMarcadoresYPolylines();
      }
    }
  }

  void _togglePolylineSource() {
    final String nuevaFuente;
    if (_polylineSource == _polylineSourceGoogle &&
        _serverPolylineEncoded != null &&
        _serverPolylineEncoded!.isNotEmpty) {
      nuevaFuente = _polylineSourceServer;
    } else {
      nuevaFuente = _polylineSourceGoogle;
    }

    _configurarFuentePolyline(nuevaFuente);

    // Feedback ligero en UI
    if (mounted) {
      NotificationService.showInfo(
        nuevaFuente == _polylineSourceServer
            ? 'Usando polylines del servidor'
            : 'Usando Google Directions API',
        context: context,
        duration: const Duration(seconds: 2),
      );
    }
  }
}
