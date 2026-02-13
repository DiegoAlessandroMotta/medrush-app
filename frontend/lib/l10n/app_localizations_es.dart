// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get loginTitle => 'Iniciar Sesión';

  @override
  String get loginSubtitle => 'Ingresa tus credenciales para continuar';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get emailHint => 'ejemplo@medrush.pe';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordHint => 'Ingresa tu contraseña';

  @override
  String get loginButton => 'Iniciar Sesión';

  @override
  String get loggingIn => 'Iniciando sesión...';

  @override
  String get capsLockActive => 'Bloq Mayús activado';

  @override
  String get rememberEmail => 'Recordar correo';

  @override
  String get serverConnectionError => 'Sin conexión al servidor';

  @override
  String get checkingConnection => 'Verificando conexión al servidor...';

  @override
  String get sessionExpiredWarning =>
      'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';

  @override
  String get downloadApkTooltip => 'Descargar APK para Android';

  @override
  String get connectionFailed => 'No se pudo conectar al servidor';

  @override
  String connectionError(Object error) {
    return 'Error de conexión: $error';
  }
}
