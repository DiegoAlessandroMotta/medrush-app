import 'package:medrush/api/api_helper.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/api/endpoint_manager.dart';
import 'package:medrush/models/farmacia.model.dart';
import 'package:medrush/models/pagination.model.dart';
import 'package:medrush/utils/loggers.dart';

class FarmaciasApi {
  // Caché removido en APIs; gestionado por repositorios

  // Obtener todas las farmacias
  // NOTA: El backend devuelve resultados paginados, este método obtiene solo la primera página
  static Future<List<Farmacia>> getAllFarmacias() {
    return ApiHelper.getList<Farmacia>(
      EndpointManager.farmacias,
      fromJson: Farmacia.fromJson,
      operationName: 'Obteniendo todas las farmacias (primera página)',
    );
  }

  /// Obtiene todas las farmacias con paginación completa
  static Future<List<Farmacia>> getAllFarmaciasCompletas() async {
    final List<Farmacia> todasFarmacias = [];
    int pagina = 1;
    bool hayMasPaginas = true;

    while (hayMasPaginas) {
      try {
        final response = await BaseApi.getPaginated<Farmacia>(
          EndpointManager.farmacias,
          fromJson: Farmacia.fromJson,
          page: pagina,
          perPage: 100, // Máximo por página para reducir llamadas
        );

        todasFarmacias.addAll(response.items);

        // Verificar si hay más páginas
        hayMasPaginas = pagina < response.pagination.lastPage;
        pagina++;
      } catch (e) {
        logError('Error obteniendo farmacias página $pagina', e);
        break;
      }
    }

    return todasFarmacias;
  }

  // Obtener farmacia por ID con caché inteligente
  static Future<Farmacia?> getFarmaciaById(String id) {
    return ApiHelper.getSingle<Farmacia>(
      EndpointManager.farmaciaById(id),
      fromJson: Farmacia.fromJson,
      operationName: 'Buscando farmacia por ID: $id',
    );
  }

  // Obtener farmacias por ciudad
  static Future<List<Farmacia>> getFarmaciasByCity(String city) {
    return ApiHelper.getList<Farmacia>(
      EndpointManager.farmacias,
      fromJson: Farmacia.fromJson,
      queryParameters: {'ciudad': city},
      operationName: 'Obteniendo farmacias por ciudad: $city',
    );
  }

  // Obtener farmacias por cadena
  static Future<List<Farmacia>> getFarmaciasByCadena(String cadena) {
    return ApiHelper.getList<Farmacia>(
      EndpointManager.farmacias,
      fromJson: Farmacia.fromJson,
      queryParameters: {'cadena': cadena},
      operationName: 'Obteniendo farmacias por cadena: $cadena',
    );
  }

  // Obtener farmacias con delivery 24h
  static Future<List<Farmacia>> getFarmaciasDelivery24h() {
    return ApiHelper.getList<Farmacia>(
      EndpointManager.farmacias,
      fromJson: Farmacia.fromJson,
      queryParameters: {'delivery_24h': true},
      operationName: 'Obteniendo farmacias con delivery 24h',
    );
  }

  // Crear nueva farmacia
  static Future<Farmacia> createFarmacia(Farmacia farmacia) {
    // Omitir ID si el backend lo genera
    final data = Map<String, dynamic>.from(farmacia.toJson())..remove('id');
    return ApiHelper.postSingle<Farmacia>(
      EndpointManager.farmacias,
      data: data,
      fromJson: Farmacia.fromJson,
      operationName: 'Creando nueva farmacia: ${farmacia.nombre}',
    );
  }

  // Actualizar farmacia
  static Future<Farmacia> updateFarmacia(Farmacia farmacia) {
    return ApiHelper.patchSingle<Farmacia>(
      EndpointManager.farmaciaById(farmacia.id),
      data: farmacia.toJson(),
      fromJson: Farmacia.fromJson,
      operationName: 'Actualizando farmacia: ${farmacia.nombre}',
    );
  }

  // Buscar farmacias por nombre
  static Future<List<Farmacia>> searchFarmacias(String nombre) {
    return ApiHelper.getList<Farmacia>(
      EndpointManager.farmacias,
      fromJson: Farmacia.fromJson,
      queryParameters: {'search': nombre},
      operationName: 'Buscando farmacias con: "$nombre"',
    );
  }

  // Eliminar farmacia
  static Future<bool> deleteFarmacia(String id) {
    return ApiHelper.deleteItem(
      EndpointManager.farmaciaById(id),
      operationName: 'Eliminando farmacia: $id',
    );
  }

  /// Obtener farmacias con paginación
  static Future<PaginatedResponse<Farmacia>> getFarmaciasPaginated({
    int page = 1,
    int perPage = EndpointManager.defaultPageSize,
    String? orderBy,
    String orderDirection = 'desc',
    String? search,
    String? city,
    String? cadena,
    bool? delivery24h,
    String? estado,
  }) async {
    try {
      logInfo('Obteniendo farmacias paginadas: página $page');

      // Si no está en caché, consulta la API
      logInfo('Consultando farmacias paginadas desde API...');

      final result = await BaseApi.execute(() async {
        final filters = <String, dynamic>{};

        // Agregar filtros adicionales
        if (search != null) {
          filters['search'] = search;
        }
        if (city != null) {
          filters['ciudad'] = city;
        }
        if (cadena != null) {
          filters['cadena'] = cadena;
        }
        if (delivery24h != null) {
          filters['delivery_24h'] = delivery24h;
        }
        if (estado != null) {
          filters['estado'] = estado;
        }

        final response = await BaseApi.getPaginated<Farmacia>(
          EndpointManager.farmacias,
          fromJson: Farmacia.fromJson,
          page: page,
          perPage: perPage,
          filters: filters,
          orderBy: orderBy,
          orderDirection: orderDirection,
        );

        return response;
      }, errorMessage: 'Error al obtener farmacias paginadas');

      logInfo('✓ Farmacias paginadas obtenidas');

      return result;
    } catch (e) {
      logError('Error al obtener farmacias paginadas', e);
      rethrow;
    }
  }
}
