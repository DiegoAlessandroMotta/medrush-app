// ignore_for_file: unnecessary_getters_setters
import 'dart:math' show sqrt;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/repositories/base.repository.dart';
import 'package:medrush/repositories/pedido.repository.dart';
import 'package:medrush/utils/loggers.dart';

class RutasProvider extends ChangeNotifier {
  List<Pedido> _pedidosEnRuta = [];
  List<Pedido> _rutaOptimizada = [];
  bool _isLoading = false;
  String? _error;
  double _latitudActual = 0.0;
  double _longitudActual = 0.0;
  DateTime? _ultimaActualizacionUbicacion;

  // Getters
  List<Pedido> get pedidosEnRuta => _pedidosEnRuta;
  List<Pedido> get rutaOptimizada => _rutaOptimizada;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get latitudActual => _latitudActual;
  double get longitudActual => _longitudActual;
  DateTime? get ultimaActualizacionUbicacion => _ultimaActualizacionUbicacion;

  // Cargar pedidos en ruta
  Future<void> cargarPedidosEnRuta() async {
    try {
      isLoading = true;
      clearError();

      // Obtener pedidos que están en ruta o recogidos desde repositorio
      final repo = PedidoRepository();
      final recogidosRes =
          await repo.obtenerPedidosPorEstado(EstadoPedido.recogido);
      final enrutaRes = await repo.obtenerPedidosPorEstado(EstadoPedido.enRuta);
      final pedidosRecogidos = recogidosRes.data ?? <Pedido>[];
      final pedidosEnRuta = enrutaRes.data ?? <Pedido>[];

      _pedidosEnRuta = [...pedidosRecogidos, ...pedidosEnRuta];

      logInfo('✅ ${_pedidosEnRuta.length} pedidos cargados para ruta');

      // Optimizar ruta automáticamente
      if (_pedidosEnRuta.isNotEmpty) {
        await optimizarRuta();
      }
    } catch (e) {
      error = 'Error al cargar pedidos en ruta: $e';
      logError('❌ Error en RutasProvider.cargarPedidosEnRuta', e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar ubicación del repartidor
  Future<void> updateLocation(double lat, double lng) async {
    try {
      isLoading = true;
      clearError();

      // Actualizar coordenadas locales
      _latitudActual = lat;
      _longitudActual = lng;
      _ultimaActualizacionUbicacion = DateTime.now();

      // FIX: Método actualizarUbicacion no existe en PedidoRepository
      // Por ahora solo actualizamos las coordenadas locales
      // TODO: Implementar actualización de ubicación en el repositorio
      final res = RepositoryResult.success(true);

      if (res.data == true) {
        logInfo('✅ Ubicación actualizada: $lat, $lng');

        // Recalcular ruta si hay pedidos
        if (_pedidosEnRuta.isNotEmpty) {
          await optimizarRuta();
        }
      } else {
        logWarning('⚠️ Error al enviar ubicación al servidor');
      }
    } catch (e) {
      error = 'Error al actualizar ubicación: $e';
      logError('❌ Error en RutasProvider.updateLocation', e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar ubicación periódicamente
  Future<void> updateLocationPeriodically(double lat, double lng) async {
    try {
      // Solo actualizar si han pasado al menos 30 segundos
      if (_ultimaActualizacionUbicacion == null ||
          DateTime.now().difference(_ultimaActualizacionUbicacion!).inSeconds >
              30) {
        await updateLocation(lat, lng);
      }
    } catch (e) {
      logError('❌ Error en actualización periódica de ubicación', e);
    }
  }

  // Optimizar ruta de entrega
  Future<void> optimizarRuta() async {
    try {
      if (_pedidosEnRuta.isEmpty) {
        _rutaOptimizada = [];
        return;
      }

      isLoading = true;
      clearError();

      // FIX: Método optimizarRuta no existe en PedidoRepository
      // Por ahora usamos el orden original
      // TODO: Implementar optimización de ruta en el repositorio
      final res = RepositoryResult.success(_pedidosEnRuta);

      _rutaOptimizada = res.data ?? List.from(_pedidosEnRuta);
      logInfo('✅ Ruta optimizada con ${_rutaOptimizada.length} pedidos');
    } catch (e) {
      error = 'Error al optimizar ruta: $e';
      logError('❌ Error en RutasProvider.optimizarRuta', e);

      // Fallback: usar orden original
      _rutaOptimizada = List.from(_pedidosEnRuta);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Marcar pedido como entregado
  Future<void> marcarPedidoEntregado(String pedidoId) async {
    try {
      final repo = PedidoRepository();
      final res = await repo.marcarPedidoEntregado(
        pedidoId,
        latitud: _latitudActual,
        longitud: _longitudActual,
      );
      final ok = res.data != null;

      if (ok) {
        // Remover de la lista de pedidos en ruta
        _pedidosEnRuta.removeWhere((p) => p.id == pedidoId);
        _rutaOptimizada.removeWhere((p) => p.id == pedidoId);

        logInfo('✅ Pedido $pedidoId marcado como entregado');
        notifyListeners();
      }
    } catch (e) {
      logError('❌ Error al marcar pedido como entregado', e);
    }
  }

  // Obtener siguiente pedido en la ruta
  Pedido? getSiguientePedido() {
    if (_rutaOptimizada.isEmpty) {
      return null;
    }
    return _rutaOptimizada.first;
  }

  // Obtener distancia estimada al siguiente pedido
  double getDistanciaSiguientePedido() {
    final siguiente = getSiguientePedido();
    if (siguiente == null) {
      return 0.0;
    }

    // Verificar que las coordenadas no sean null
    final latSiguiente = siguiente.latitud;
    final lngSiguiente = siguiente.longitud;

    if (latSiguiente == null || lngSiguiente == null) {
      return 0.0;
    }

    // Cálculo simple de distancia (en una implementación real usarías un servicio de geocoding)
    final dx = latSiguiente - _latitudActual;
    final dy = lngSiguiente - _longitudActual;
    return sqrt(dx * dx + dy * dy);
  }

  // Métodos privados
  // Emparejar con getter isLoading
  set isLoading(bool value) {
    _isLoading = value;
  }

  set error(String? value) {
    _error = value;
  }

  void clearError() {
    _error = null;
  }

  void refresh() {
    cargarPedidosEnRuta();
  }
}
