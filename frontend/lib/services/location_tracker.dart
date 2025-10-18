import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:medrush/utils/loggers.dart';

/// Servicio global para rastrear ubicación del repartidor en primer plano
/// y reportarla al backend solo cuando hay movimiento significativo.
class LocationTrackerService {
  LocationTrackerService._internal();
  static final LocationTrackerService _instance =
      LocationTrackerService._internal();
  static LocationTrackerService get instance => _instance;

  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;
  Position? _lastReportedPosition;

  // Configuración de movimiento significativo
  static const double _minDistanceToReport =
      100.0; // 100 metros mínimo para reportar
  static const Duration _minTimeBetweenReports =
      Duration(minutes: 5); // Máximo cada 5 minutos
  DateTime? _lastReportTime;

  // Funciones provistas por la app para acceder al estado actual
  String Function()? _getRepartidorId; // ID del usuario/repartidor autenticado
  Future<void> Function(double lat, double lng, String repartidorId)?
      _onLocationUpdate;

  bool get isRunning => _positionSubscription != null;

  Future<void> start({
    required String Function() getRepartidorId,
    Future<void> Function(double lat, double lng, String repartidorId)?
        onLocationUpdate,
  }) async {
    try {
      _getRepartidorId = getRepartidorId;
      _onLocationUpdate = onLocationUpdate;

      // Permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          logWarning('Permisos de ubicación denegados');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        logWarning('Permisos de ubicación denegados permanentemente');
        return;
      }

      // Stream de ubicación optimizado - solo cuando hay movimiento significativo
      _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy:
              LocationAccuracy.medium, // Reducir precisión para ahorrar batería
          distanceFilter:
              _minDistanceToReport.toInt(), // Solo cuando se mueva >= 100m
        ),
      ).listen((pos) {
        _lastPosition = pos;
        _checkAndReportLocation(pos);
      }, onError: (e) {
        logError('Error en stream de ubicación', e);
      });

      logInfo(
          'LocationTrackerService iniciado con reporte optimizado (movimiento >= ${_minDistanceToReport}m)');
    } catch (e) {
      logError('No se pudo iniciar LocationTrackerService', e);
    }
  }

  /// Verifica si debe reportar la ubicación basado en distancia y tiempo
  Future<void> _checkAndReportLocation(Position newPosition) async {
    try {
      if (_getRepartidorId == null) {
        return;
      }

      final repartidorId = _getRepartidorId!.call();
      if (repartidorId.isEmpty) {
        return;
      }

      final now = DateTime.now();
      bool shouldReport = false;

      // Primera posición o no hay posición reportada anteriormente
      if (_lastReportedPosition == null) {
        shouldReport = true;
        logInfo(
            '📍 Primera ubicación reportada: ${newPosition.latitude}, ${newPosition.longitude}');
      } else {
        // Calcular distancia desde la última posición reportada
        final distance = Geolocator.distanceBetween(
          _lastReportedPosition!.latitude,
          _lastReportedPosition!.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );

        // Verificar si ha pasado suficiente tiempo desde el último reporte
        final timeSinceLastReport = _lastReportTime != null
            ? now.difference(_lastReportTime!)
            : Duration.zero;

        // Reportar si se movió significativamente O si ha pasado mucho tiempo
        if (distance >= _minDistanceToReport ||
            timeSinceLastReport >= _minTimeBetweenReports) {
          shouldReport = true;
          logInfo(
              '📍 Movimiento significativo detectado: ${distance.toStringAsFixed(1)}m desde último reporte');
        }
      }

      if (shouldReport) {
        // Llamar al callback si está disponible
        if (_onLocationUpdate != null) {
          await _onLocationUpdate!(
              newPosition.latitude, newPosition.longitude, repartidorId);
        }

        // Actualizar estado interno
        _lastReportedPosition = newPosition;
        _lastReportTime = now;

        logInfo(
            '📍 Ubicación reportada: ${newPosition.latitude.toStringAsFixed(6)}, ${newPosition.longitude.toStringAsFixed(6)}');
      } else {
        logDebug('📍 Ubicación no reportada - movimiento insuficiente');
      }
    } catch (e) {
      logError('Error al verificar ubicación para reporte', e);
    }
  }

  Future<void> stop() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastPosition = null;
    _lastReportedPosition = null;
    _lastReportTime = null;
    _getRepartidorId = null;
    _onLocationUpdate = null;
    logInfo('🛑 LocationTrackerService detenido');
  }

  /// Obtiene la última posición conocida
  Position? get lastPosition => _lastPosition;

  /// Obtiene la última posición reportada
  Position? get lastReportedPosition => _lastReportedPosition;

  /// Fuerza un reporte inmediato de la ubicación actual
  Future<void> forceLocationReport() async {
    if (_lastPosition != null && _getRepartidorId != null) {
      final repartidorId = _getRepartidorId!.call();
      if (repartidorId.isNotEmpty) {
        await _checkAndReportLocation(_lastPosition!);
      }
    }
  }
}
