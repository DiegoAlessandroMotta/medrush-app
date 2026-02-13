import 'package:csv/csv.dart';
import 'package:medrush/models/farmacia.model.dart';
import 'package:uuid/uuid.dart';

class FarmaciaCsv {
  static const List<String> headers = [
    'id',
    'nombre',
    'razon_social',
    'ruc',
    'direccion',
    'city',
    'state',
    'zip_code',
    'telefono',
    'email',
    'latitud',
    'longitud',
    'estado',
    'cadena',
    'horario_atencion',
    'delivery_24h',
    'contacto_responsable',
    'telefono_responsable',
    'fecha_registro',
    'fecha_ultima_actualizacion',
  ];

  static String toCsv(List<Farmacia> farmacias) {
    final List<List<dynamic>> rows = [List<String>.from(headers)];
    for (final farmacia in farmacias) {
      rows.add([
        farmacia.id,
        farmacia.nombre,
        farmacia.razonSocial,
        farmacia.ruc,
        farmacia.direccion,
        farmacia.city,
        farmacia.state ?? '',
        farmacia.zipCode ?? '',
        farmacia.telefono,
        farmacia.email ?? '',
        farmacia.latitud,
        farmacia.longitud,
        farmacia.estado.name,
        farmacia.cadena,
        farmacia.horarioAtencion ?? '',
        farmacia.delivery24h,
        farmacia.contactoResponsable ?? '',
        farmacia.telefonoResponsable ?? '',
        farmacia.fechaRegistro.toIso8601String(),
        farmacia.fechaUltimaActualizacion?.toIso8601String() ?? '',
      ]);
    }
    // Usar la nueva API de csv 7.x
    return csv.encode(rows);
  }

  static List<Farmacia> fromCsv(String csvContent) {
    // Usar la nueva API de csv 7.x
    // Configurar para no parsear números automáticamente (como en la versión anterior)
    final codec = CsvCodec(
      lineDelimiter: '\n',
    );
    final List<List<dynamic>> data = codec.decode(csvContent);

    if (data.isEmpty) {
      return [];
    }

    final firstRow =
        data.first.map((e) => e.toString().trim().toLowerCase()).toList();
    final bool hasHeader = _looksLikeHeader(firstRow);
    final header = hasHeader
        ? data.first.map((e) => e.toString().trim()).toList()
        : headers;
    final int startIndex = hasHeader ? 1 : 0;

    final Map<String, int> indexByName = {};
    for (var i = 0; i < header.length; i++) {
      indexByName[header[i].toLowerCase()] = i;
    }

    final List<Farmacia> result = [];
    final uuid = const Uuid();

    for (var r = startIndex; r < data.length; r++) {
      final row = data[r];
      if (row.isEmpty || row.every((c) => c.toString().trim().isEmpty)) {
        continue;
      }

      String getValue(String name) {
        final idx = indexByName[name];
        if (idx == null || idx >= row.length) {
          return '';
        }
        return row[idx].toString().trim();
      }

      double parseDouble(String value) {
        final v = value.replaceAll(',', '.');
        final parsed = double.tryParse(v);
        if (parsed == null) {
          throw FormatException('Valor numérico inválido: "$value"');
        }
        return parsed;
      }

      bool parseBoolFlexible(String value) {
        final v = value.toLowerCase();
        return v == 'true' ||
            v == '1' ||
            v == 'si' ||
            v == 'sí' ||
            v == 'yes' ||
            v == 'y';
      }

      EstadoFarmacia parseEstado(String value) {
        final v = value.toLowerCase();
        for (final e in EstadoFarmacia.values) {
          if (e.name.toLowerCase() == v) {
            return e;
          }
        }
        return EstadoFarmacia.activa;
      }

      final now = DateTime.now();

      final id = getValue('id').isEmpty ? uuid.v4() : getValue('id');
      final nombre = getValue('nombre');
      final razonSocial = getValue('razon_social');
      final ruc = getValue('ruc');
      final direccion = getValue('direccion');
      final distrito =
          getValue('city').isEmpty ? getValue('distrito') : getValue('city');
      final provincia =
          getValue('state').isEmpty ? getValue('provincia') : getValue('state');
      final departamento = getValue('zip_code').isEmpty
          ? getValue('departamento')
          : getValue('zip_code');
      final telefono = getValue('telefono');
      final email = getValue('email');
      final latitud = parseDouble(getValue('latitud'));
      final longitud = parseDouble(getValue('longitud'));
      final estado = parseEstado(getValue('estado'));
      final cadena = getValue('cadena');
      final horarioAtencion = getValue('horario_atencion');
      final delivery24h = parseBoolFlexible(getValue('delivery_24h'));
      final contactoResponsable = getValue('contacto_responsable');
      final telefonoResponsable = getValue('telefono_responsable');
      final fechaRegistroStr = getValue('fecha_registro');
      final fechaUltimaActStr = getValue('fecha_ultima_actualizacion');

      final fechaRegistro = fechaRegistroStr.isEmpty
          ? now
          : DateTime.tryParse(fechaRegistroStr) ?? now;
      final fechaUltimaActualizacion = fechaUltimaActStr.isEmpty
          ? null
          : DateTime.tryParse(fechaUltimaActStr);

      if (nombre.isEmpty || direccion.isEmpty || telefono.isEmpty) {
        continue;
      }

      result.add(
        Farmacia(
          id: id,
          nombre: nombre,
          razonSocial: razonSocial,
          ruc: ruc,
          direccion: direccion,
          city: distrito.isEmpty ? 'Unknown' : distrito,
          state: provincia.isEmpty ? null : provincia,
          zipCode: departamento.isEmpty ? null : departamento,
          telefono: telefono,
          email: email.isEmpty ? null : email,
          latitud: latitud,
          longitud: longitud,
          estado: estado,
          cadena: cadena,
          horarioAtencion: horarioAtencion.isEmpty ? null : horarioAtencion,
          delivery24h: delivery24h,
          contactoResponsable:
              contactoResponsable.isEmpty ? null : contactoResponsable,
          telefonoResponsable:
              telefonoResponsable.isEmpty ? null : telefonoResponsable,
          fechaRegistro: fechaRegistro,
          fechaUltimaActualizacion: fechaUltimaActualizacion,
        ),
      );
    }

    return result;
  }

  static bool _looksLikeHeader(List<String> firstRow) {
    int matches = 0;
    for (final h in headers) {
      if (firstRow.contains(h.toLowerCase())) {
        matches++;
      }
    }
    return matches >= 5;
  }

  static String templateCsv() {
    final sample = StringBuffer()
      ..writeln(headers.join(','))
      ..writeln([
        '',
        'Farmacia Demo',
        'MedRush SAC',
        '20123456789',
        'Av. Siempre Viva 742',
        'Lima',
        'Lima',
        'Lima',
        '+51 123456789',
        'demo@farmacia.com',
        '-12.0464',
        '-77.0428',
        'activa',
        'InkaFarma',
        'Lun-Dom 08:00-22:00',
        'true',
        'Juan Perez',
        '+51 987654321',
        '',
        '',
      ].join(','));
    return sample.toString();
  }
}
