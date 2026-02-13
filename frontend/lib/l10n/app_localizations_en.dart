// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginTitle => 'Login';

  @override
  String get loginSubtitle => 'Enter your credentials to continue';

  @override
  String get emailLabel => 'Email address';

  @override
  String get emailHint => 'example@medrush.pe';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get loginButton => 'Login';

  @override
  String get loggingIn => 'Logging in...';

  @override
  String get capsLockActive => 'Caps Lock on';

  @override
  String get rememberEmail => 'Remember email';

  @override
  String get serverConnectionError => 'No server connection';

  @override
  String get checkingConnection => 'Checking server connection...';

  @override
  String get sessionExpiredWarning =>
      'Your session has expired. Please login again.';

  @override
  String get downloadApkTooltip => 'Download APK for Android';

  @override
  String get connectionFailed => 'Could not connect to server';

  @override
  String connectionError(Object error) {
    return 'Connection error: $error';
  }
}
