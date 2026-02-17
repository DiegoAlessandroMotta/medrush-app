import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:medrush/api/auth.api.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/api/fcm.api.dart';
import 'package:medrush/api/repartidores.api.dart';
import 'package:medrush/models/usuario.model.dart';
import 'package:medrush/services/fcm_service.dart';
import 'package:medrush/services/location_tracker.dart';
import 'package:medrush/utils/loggers.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  Usuario? _usuario;
  String? _error;
  Map<String, String>? _lastClientInfo;

  AuthState get state => _state;
  Usuario? get usuario => _usuario;
  String? get error => _error;
  bool get isLoggedIn => _state == AuthState.authenticated && _usuario != null;
  Map<String, String>? get clientInfo => _lastClientInfo;

  // Método para obtener el rol del usuario
  String get userRole {
    if (_usuario == null) {
      return '';
    }

    switch (_usuario!.tipoUsuario) {
      case TipoUsuario.administrador:
        return 'admin';
      case TipoUsuario.repartidor:
        return 'repartidor';
    }
  }

  AuthProvider() {
    logInfo(
        '🔐 AuthProvider inicializado - verificando estado de autenticación...');
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      _setState(AuthState.loading);

      // Verificar si hay un token guardado
      final token = await BaseApi.getToken();
      if (token == null || token.isEmpty) {
        logInfo('🔐 No se encontró token en storage');
        _setState(AuthState.unauthenticated);
        return;
      }

      // Restaurar token en BaseApi
      BaseApi.setAuthToken(token);
      logInfo('🔐 Token restaurado desde storage');

      // Verificar si el token está expirado haciendo una request simple
      logInfo('🔐 Verificando validez del token...');
      final isValid = await BaseApi.isTokenValid();

      if (!isValid) {
        logWarning('⚠️ Token expirado o inválido');
        // Si el token está expirado, limpiar y redirigir al login
        await _clearUserData();
        _setState(AuthState.unauthenticated);
        return;
      }

      // Token válido, cargar perfil del usuario
      try {
        final me = await AuthApi.getMe(token);
        // El backend envuelve en { status, message, data: user }
        final laravelUser = (me['data'] ?? me) as Map<String, dynamic>;
        _usuario = _mapLaravelUserToUsuario(laravelUser);
        _setState(AuthState.authenticated);
        logInfo('✅ Token válido - Perfil cargado desde /auth/me');
        return;
      } catch (e) {
        logWarning('⚠️ Error al cargar perfil: $e');
        // Si falla cargar el perfil, limpiar y redirigir al login
        await _clearUserData();
        _setState(AuthState.unauthenticated);
        return;
      }
    } catch (e) {
      logError('❌ Error al verificar autenticación: $e');
      _setState(AuthState.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _setState(AuthState.loading);
      _clearError();

      // Obtener información detallada del dispositivo para Laravel Sanctum
      final deviceName = await _getDetailedDeviceName();
      logInfo('🔐 Iniciando sesión con dispositivo: $deviceName');

      // Usar la nueva API de autenticación
      //
      final response = await AuthApi.login(
        email: email,
        password: password,
        deviceName: deviceName,
      );

      // Verificar que la respuesta sea exitosa
      if (response['status'] == 'success') {
        final userData = response['data']['user'] as Map<String, dynamic>;
        final accessToken = response['data']['access_token'] as String;

        logInfo('✅ Login exitoso, procesando datos del usuario');

        // Guardar el token de acceso
        await BaseApi.storeToken(accessToken);

        // Configurar el token en BaseApi para requests futuros
        BaseApi.setAuthToken(accessToken);

        // Crear objeto Usuario desde la respuesta del servidor Laravel
        _usuario = _mapLaravelUserToUsuario(userData);
        // Iniciar tracking de ubicación si es repartidor
        if (_usuario!.esRepartidor) {
          await LocationTrackerService.instance.start(
            getRepartidorId: () => _usuario?.id ?? '',
          );
        }

        // Inicializar y registrar FCM token (opcional, no bloquea login)
        if (kIsWeb) {
          // En web, FCM puede tener problemas, lo hacemos opcional con timeout
          try {
            await Future.any([
              FcmService()
                  .initialize()
                  .then((_) => FcmService().registerToken()),
              Future.delayed(
                  const Duration(seconds: 5)), // Timeout de 5 segundos
            ]);
            logInfo('✅ FCM token registrado exitosamente en web');
          } catch (e) {
            logWarning('⚠️ FCM no disponible en web (timeout o error): $e');
            // No fallar el login por error de FCM en web
          }
        } else {
          // En móvil, FCM es más confiable
          try {
            await FcmService().initialize();
            await FcmService().registerToken();
            logInfo('✅ FCM token registrado exitosamente en móvil');
          } catch (e) {
            logError('❌ Error al registrar FCM token en móvil', e);
            // No fallar el login por error de FCM
          }
        }

        // Guardar datos del usuario
        await _saveUserData(_usuario!);

        // Guardar el email para el próximo login
        await BaseApi.storeLastUsedEmail(email);

        if (_usuario?.esRepartidor == true) {
          try {
            await RepartidoresApi.updateEstadoRepartidor(
                _usuario!.id, 'disponible');
            logInfo('👤 Estado del repartidor actualizado a disponible');
          } catch (e) {
            logError('❌ Error al actualizar estado del repartidor', e);
          }
        }

        _setState(AuthState.authenticated);
        return true;
      } else {
        _setError('Error en la respuesta del servidor');
        _setState(AuthState.unauthenticated);
        return false;
      }
    } catch (e) {
      logError('❌ Error en login: $e');
      final errorMessage = BaseApi.extractErrorMessage(e);
      _setError(errorMessage);
      _setState(AuthState.error);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      _setState(AuthState.loading);

      // Obtener token actual antes de limpiar
      final token = await BaseApi.getToken();

      if (_usuario?.esRepartidor == true) {
        try {
          await RepartidoresApi.updateEstadoRepartidor(
              _usuario!.id, 'desconectado');
          logInfo('👤 Estado del repartidor actualizado a desconectado');
        } catch (e) {
          logError('❌ Error al actualizar estado del repartidor al salir', e);
        }
      }

      // Detener tracking de ubicación
      await LocationTrackerService.instance.stop();

      // Limpiar FCM en backend y local
      try {
        if (token != null) {
          // Eliminar token FCM del backend
          await FcmApi.deleteCurrentSessionToken();
          logInfo('✅ Token FCM eliminado del backend');
        }

        // Limpiar FCM service local
        FcmService().dispose();
        logInfo('✅ FCM service limpiado localmente');
      } catch (e) {
        logError('❌ Error al limpiar FCM service', e);
      }

      // Hacer logout en el backend si hay token
      if (token != null) {
        try {
          await AuthApi.logout(token);
          logInfo('✅ Logout exitoso en el backend');
        } catch (e) {
          logWarning('⚠️ Error en logout del backend (continuando): $e');
        }
      }

      // Limpiar datos locales
      await _clearUserData();
      _usuario = null;
      _setState(AuthState.unauthenticated);
    } catch (e) {
      _setError('Error al cerrar sesión: $e');
      _setState(AuthState.error);
    }
  }

  Future<bool> refreshProfile() async {
    try {
      if (!isLoggedIn || _usuario == null) {
        logWarning('⚠️ No se puede refrescar perfil: usuario no autenticado');
        return false;
      }

      logInfo('👤 Refrescando perfil del usuario...');

      // Llamar al endpoint /auth/me para obtener datos actualizados
      final response = await BaseApi.get<Map<String, dynamic>>('/auth/me');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;

        if (data['status'] == 'success' && data['data'] != null) {
          // Mapear el usuario actualizado
          final updatedUser =
              Usuario.fromJson(data['data'] as Map<String, dynamic>);

          // Actualizar el usuario en memoria
          _usuario = updatedUser;

          logInfo('✅ Perfil refrescado exitosamente');
          return true;
        } else {
          final error = data['message'] ?? 'Error desconocido del servidor';
          logError('❌ Error del servidor al refrescar perfil: $error');
          return false;
        }
      } else {
        logError('❌ Error HTTP ${response.statusCode} al refrescar perfil');
        return false;
      }
    } catch (e) {
      logError('❌ Error al refrescar perfil', e);
      _setError('Error al actualizar perfil: $e');
      return false;
    }
  }

  Future<bool> updateProfile({
    String? nombre,
    String? telefono,
    String? foto,
    String? email,
  }) async {
    try {
      if (!isLoggedIn || _usuario == null) {
        return false;
      }

      final usuarioActualizado = _usuario!.copyWith(
        nombre: nombre,
        telefono: telefono,
        foto: foto,
        email: email,
      );

      // Si es repartidor, actualizar en el backend
      if (_usuario!.esRepartidor) {
        final result = await RepartidoresApi.updateRepartidor(
          usuarioActualizado,
          emailOriginal: _usuario!.email,
        );

        if (result != null) {
          _usuario = result;
          await _saveUserData(_usuario!);
          notifyListeners();
          return true;
        } else {
          _setError('No se pudo actualizar el perfil en el servidor');
          return false;
        }
      }

      // Por ahora, solo actualizamos localmente para no repartidores
      _usuario = usuarioActualizado;

      await _saveUserData(_usuario!);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar perfil: $e');
      return false;
    }
  }

  Future<void> _saveUserData(Usuario usuario) async {
    try {
      await BaseApi.storeUserData(_usuario!.toJson());

      logInfo('💾 Datos de usuario guardados en storage: ${usuario.nombre}');
    } catch (e) {
      logError('❌ Error al guardar datos de usuario: $e');
    }
  }

  Future<void> _clearUserData() async {
    try {
      // Limpiar token y datos de usuario
      await BaseApi.clearAuthData();

      // Limpiar token de BaseApi
      BaseApi.clearAuthToken();

      logInfo('🧹 Datos de sesión limpiados completamente');
    } catch (e) {
      logError('❌ Error al limpiar datos de usuario: $e');
    }
  }

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _state = AuthState.error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Mapea la respuesta del servidor Laravel al modelo Usuario del frontend
  Usuario _mapLaravelUserToUsuario(Map<String, dynamic> laravelUser) {
    try {
      logInfo('🔄 Mapeando usuario de Laravel a modelo Usuario');

      // Mapear campos básicos
      final id = laravelUser['id'] as String;
      final name = laravelUser['name'] as String;
      final email = laravelUser['email'] as String;
      final isActive = laravelUser['is_active'] as bool;

      // Mapear roles a tipo de usuario
      final roles = (laravelUser['roles'] as List<dynamic>).cast<String>();
      final TipoUsuario tipoUsuario = _mapRolesToTipoUsuario(roles);

      // Mapear perfil específico según el rol
      EstadoRepartidor? estadoRepartidor;
      String? telefono;
      String? licenciaNumero;
      DateTime? licenciaVencimiento;
      String? licenciaImagenUrl;
      String? seguroVehiculoUrl;
      String? vehiculoPlaca;
      String? vehiculoMarca;
      String? vehiculoModelo;
      String? farmaciaId;

      if (tipoUsuario == TipoUsuario.repartidor &&
          laravelUser['perfil_repartidor'] != null) {
        final perfil = laravelUser['perfil_repartidor'] as Map<String, dynamic>;
        estadoRepartidor = _mapEstadoRepartidor(perfil['estado'] as String?);
        telefono = perfil['telefono'] as String?;
        licenciaNumero = perfil['licencia_numero'] as String?;
        licenciaVencimiento = perfil['licencia_vencimiento'] != null
            ? DateTime.parse(perfil['licencia_vencimiento'] as String)
            : null;
        licenciaImagenUrl = perfil['licencia_imagen_url'] as String?;
        seguroVehiculoUrl = perfil['seguro_vehiculo_url'] as String?;
        vehiculoPlaca = perfil['vehiculo_placa'] as String?;
        vehiculoMarca = perfil['vehiculo_marca'] as String?;
        vehiculoModelo = perfil['vehiculo_modelo'] as String?;
        farmaciaId = perfil['farmacia_id'] as String?;
      }

      // Crear y retornar el usuario mapeado
      final usuario = Usuario(
        id: id,
        nombre: name,
        email: email,
        password: '', // No se envía desde el servidor por seguridad
        tipoUsuario: tipoUsuario,
        activo: isActive,
        foto: laravelUser['avatar'] as String?,
        telefono: telefono,
        estadoRepartidor: estadoRepartidor,
        licenciaNumero: licenciaNumero,
        licenciaVencimiento: licenciaVencimiento,
        licenciaImagenUrl: licenciaImagenUrl,
        seguroVehiculoUrl: seguroVehiculoUrl,
        vehiculoPlaca: vehiculoPlaca,
        vehiculoMarca: vehiculoMarca,
        vehiculoModelo: vehiculoModelo,
        farmaciaId: farmaciaId,
        createdAt: laravelUser['created_at'] != null
            ? DateTime.parse(laravelUser['created_at'] as String)
            : null,
        updatedAt: laravelUser['updated_at'] != null
            ? DateTime.parse(laravelUser['updated_at'] as String)
            : null,
      );

      logInfo(
          '✅ Usuario mapeado exitosamente: ${usuario.nombre} (${usuario.tipoUsuario.name})');
      return usuario;
    } catch (e) {
      logError('❌ Error al mapear usuario de Laravel: $e');
      rethrow;
    }
  }

  /// Mapea los roles de Laravel al enum TipoUsuario
  TipoUsuario _mapRolesToTipoUsuario(List<String> roles) {
    if (roles.contains('administrador')) {
      return TipoUsuario.administrador;
    } else if (roles.contains('repartidor')) {
      return TipoUsuario.repartidor;
    } else if (roles.contains('farmacia')) {
      // Las farmacias ahora son administradores
      return TipoUsuario.administrador;
    } else {
      return TipoUsuario.repartidor; // Por defecto
    }
  }

  /// Mapea el estado del repartidor de Laravel al enum EstadoRepartidor
  EstadoRepartidor? _mapEstadoRepartidor(String? estado) {
    if (estado == null) {
      return null;
    }

    switch (estado.toLowerCase()) {
      case 'disponible':
        return EstadoRepartidor.disponible;
      case 'en_ruta':
        return EstadoRepartidor.enRuta;
      case 'desconectado':
        return EstadoRepartidor.desconectado;
      default:
        return EstadoRepartidor.disponible;
    }
  }

  /// Obtiene información detallada del dispositivo para Laravel Sanctum
  Future<String> _getDetailedDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      // Web (Edge/Chrome/Safari/Firefox)
      if (kIsWeb) {
        final web = await deviceInfo.webBrowserInfo;
        final browser = web.browserName.name; // e.g., chrome, edge
        final platform = web.platform ?? 'web';
        final ua = web.userAgent ?? '';
        _lastClientInfo = {
          'platform': platform,
          'browser': browser,
          'userAgent': ua,
        };
        // Construimos un nombre legible y estable sin identificar de forma única al usuario
        return 'Web $browser ($platform)';
      }

      // Plataformas móviles
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _lastClientInfo = {
          'platform': 'android',
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'version': androidInfo.version.release,
        };
        return '${androidInfo.brand} ${androidInfo.model} (Android ${androidInfo.version.release})';
      }
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _lastClientInfo = {
          'platform': 'ios',
          'name': iosInfo.name,
          'model': iosInfo.model,
          'version': iosInfo.systemVersion,
        };
        return '${iosInfo.name} ${iosInfo.model} (iOS ${iosInfo.systemVersion})';
      }

      // Otras plataformas (no se usan en este proyecto)
      _lastClientInfo = {'platform': 'other'};
      return 'Flutter App';
    } catch (e) {
      logWarning(
          '⚠️ No se pudo obtener información detallada del dispositivo: $e');
      // Fallback sin tocar Platform en Web
      _lastClientInfo = {'platform': kIsWeb ? 'web' : 'mobile'};
      return kIsWeb ? 'Web' : 'Mobile';
    }
  }
}
