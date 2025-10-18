import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';

class NotificationService {
  static const Duration _defaultDuration = Duration(seconds: 3);
  static const Duration _longDuration = Duration(seconds: 5);

  // Toast de éxito
  static void showSuccess(String message,
      {Duration? duration, BuildContext? context}) {
    logInfo('Toast de éxito: $message');

    // Usar siempre ScaffoldMessenger que es más confiable
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: MedRushTheme.primaryGreen,
          duration: duration ?? _defaultDuration,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      logError('Context es null, no se puede mostrar el toast');
    }
  }

  // Toast de error
  static void showError(String message,
      {Duration? duration, BuildContext? context}) {
    logError('Toast de error: $message');

    // Usar siempre ScaffoldMessenger que es más confiable
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[400],
          duration: duration ?? _longDuration,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      logError('Context es null, no se puede mostrar el toast');
    }
  }

  // Toast de advertencia
  static void showWarning(String message,
      {Duration? duration, BuildContext? context}) {
    logInfo('Toast de advertencia: $message');

    // Usar siempre ScaffoldMessenger que es más confiable
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange[400],
          duration: duration ?? _defaultDuration,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      logError('Context es null, no se puede mostrar el toast');
    }
  }

  // Toast de información
  static void showInfo(String message,
      {Duration? duration, BuildContext? context}) {
    logInfo('Toast de información: $message');

    // Usar siempre ScaffoldMessenger que es más confiable
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.blue[400],
          duration: duration ?? _defaultDuration,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      logError('Context es null, no se puede mostrar el toast');
    }
  }

  // Toast personalizado
  static void showCustom({
    required String message,
    Color? backgroundColor,
    Color? textColor,
    Duration? duration,
    ToastGravity gravity = ToastGravity.TOP,
  }) {
    logInfo('🎨 Toast personalizado: $message');
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      timeInSecForIosWeb: duration?.inSeconds ?? _defaultDuration.inSeconds,
      backgroundColor: backgroundColor ?? MedRushTheme.primaryGreen,
      textColor: textColor ?? Colors.white,
      fontSize: MedRushTheme.fontSizeBodyMedium,
      webShowClose: true,
      webBgColor: (backgroundColor ?? MedRushTheme.primaryGreen).toString(),
      webPosition: gravity == ToastGravity.TOP ? "top" : "bottom",
    );
  }

  // Cancelar todos los toasts
  static void cancelAll() {
    Fluttertoast.cancel();
    logInfo('Todos los toasts cancelados');
  }

  // Verificar si hay toasts activos
  static bool get isToastVisible {
    // fluttertoast no tiene un método directo para verificar esto
    // pero podemos usar un flag interno si es necesario
    return false;
  }
}
