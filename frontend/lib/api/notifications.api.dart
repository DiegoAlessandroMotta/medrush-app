import 'package:medrush/api/api_helper.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/api/endpoint_manager.dart';
import 'package:medrush/models/notificacion.model.dart';

class NotificationsApi {
  // Caché eliminado: la capa de repositorios administrará el caché si aplica.

  /// Obtiene todas las notificaciones del usuario autenticado
  static Future<List<Notificacion>> getUserNotifications() {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.get<Map<String, dynamic>>(
          EndpointManager.userNotifications,
        );

        if (response.data?['status'] == 'success') {
          final List<dynamic> notificationsData = response.data?['data'] ?? [];
          return notificationsData
              .map(
                  (json) => Notificacion.fromJson(json as Map<String, dynamic>))
              .toList();
        }

        return <Notificacion>[];
      },
      operationName: 'Obteniendo notificaciones del usuario',
    );
  }

  /// Obtiene notificaciones no leídas
  static Future<List<Notificacion>> getUnreadNotifications() {
    return ApiHelper.executeWithLogging(
      () async {
        final allNotifications = await getUserNotifications();
        return allNotifications
            .where((notification) => notification.fechaLectura == null)
            .toList();
      },
      operationName: 'Obteniendo notificaciones no leídas',
    );
  }

  /// Obtiene notificaciones recientes (últimas 10)
  static Future<List<Notificacion>> getRecentNotifications({int limit = 10}) {
    return ApiHelper.executeWithLogging(
      () async {
        final allNotifications = await getUserNotifications();
        return allNotifications.take(limit).toList();
      },
      operationName: 'Obteniendo $limit notificaciones recientes',
    );
  }

  /// Obtiene estadísticas de notificaciones
  static Future<Map<String, int>> getNotificationStats() {
    return ApiHelper.executeWithLogging(
      () async {
        final allNotifications = await getUserNotifications();

        final unreadCount =
            allNotifications.where((n) => n.fechaLectura == null).length;
        final readCount =
            allNotifications.where((n) => n.fechaLectura != null).length;
        final todayCount = allNotifications
            .where((n) => n.fechaCreacion
                .isAfter(DateTime.now().subtract(const Duration(days: 1))))
            .length;

        return <String, int>{
          'total': allNotifications.length,
          'unread': unreadCount,
          'read': readCount,
          'today': todayCount,
        };
      },
      operationName: 'Obteniendo estadísticas de notificaciones',
    );
  }
}
