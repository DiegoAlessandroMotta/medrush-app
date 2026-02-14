import 'package:flutter/material.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helpers centralizados para abrir URLs (Google Maps, tel, etc.).
class UrlLauncherHelper {
  UrlLauncherHelper._();

  static const String _googleMapsPlaceBase =
      'https://www.google.com/maps?q=';
  static const String _googleMapsDirBase =
      'https://www.google.com/maps/dir/?api=1';
  static const String _googleMapsSearchBase =
      'https://www.google.com/maps/search/?api=1';
  static const String _googleMapsGeoScheme = 'geo:';

  /// Uri para ver una ubicación en Google Maps (solo ver coordenadas).
  static Uri googleMapsPlaceUri(double lat, double lng) =>
      Uri.parse('$_googleMapsPlaceBase$lat,$lng');

  /// Uri para iniciar navegación hacia [lat], [lng].
  static Uri googleMapsDirectionUri(double lat, double lng) =>
      Uri.parse(
          '$_googleMapsDirBase&destination=$lat,$lng&travelmode=driving');

  /// Uri para navegación cuando ya tienes el destino como "lat,lng".
  static Uri googleMapsDirectionUriFromDestination(String destination) =>
      Uri.parse('$_googleMapsDirBase&destination=$destination&travelmode=driving');

  /// Uri para búsqueda por dirección o texto.
  static Uri googleMapsSearchUri(String queryEncoded) =>
      Uri.parse('$_googleMapsSearchBase&query=$queryEncoded');

  /// Uri fallback para app de mapas (esquema geo:).
  static Uri googleMapsGeoUri(double lat, double lng) =>
      Uri.parse('$_googleMapsGeoScheme$lat,$lng?q=$lat,$lng');

  /// Abre Google Maps en la ubicación [lat], [lng].
  /// Prueba la URL web y, si falla, el esquema [geo:].
  /// Si [context] y [errorMessage] se pasan y no se pudo abrir, muestra el error.
  static Future<bool> openGoogleMapsPlace(
    double lat,
    double lng, {
    BuildContext? context,
    String? errorMessage,
  }) async {
    try {
      final url = googleMapsPlaceUri(lat, lng);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      }
      final fallback = googleMapsGeoUri(lat, lng);
      if (await canLaunchUrl(fallback)) {
        await launchUrl(fallback);
        return true;
      }
    } catch (e) {
      debugPrint('UrlLauncherHelper.openGoogleMapsPlace: $e');
    }
    if (context != null && context.mounted && errorMessage != null) {
      NotificationService.showError(errorMessage, context: context);
    }
    return false;
  }

  /// Abre Google Maps en modo navegación hacia [lat], [lng].
  static Future<bool> openGoogleMapsDirection(
    double lat,
    double lng, {
    BuildContext? context,
    String? errorMessage,
  }) {
    return _launchUri(
      googleMapsDirectionUri(lat, lng),
      context: context,
      errorMessage: errorMessage,
    );
  }

  /// Abre Google Maps en modo navegación con [destination] ya formateado ("lat,lng").
  static Future<bool> openGoogleMapsDirectionWithDestination(
    String destination, {
    BuildContext? context,
    String? errorMessage,
  }) {
    return _launchUri(
      googleMapsDirectionUriFromDestination(destination),
      context: context,
      errorMessage: errorMessage,
    );
  }

  /// Abre Google Maps con búsqueda por dirección o texto [addressQuery].
  static Future<bool> openGoogleMapsSearch(
    String addressQuery, {
    BuildContext? context,
    String? errorMessage,
  }) {
    final encoded = Uri.encodeComponent(addressQuery);
    return _launchUri(
      googleMapsSearchUri(encoded),
      context: context,
      errorMessage: errorMessage,
    );
  }

  static Future<bool> _launchUri(
    Uri uri, {
    BuildContext? context,
    String? errorMessage,
  }) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint('UrlLauncherHelper: $e');
    }
    if (context != null && context.mounted && errorMessage != null) {
      NotificationService.showError(errorMessage, context: context);
    }
    return false;
  }
}
