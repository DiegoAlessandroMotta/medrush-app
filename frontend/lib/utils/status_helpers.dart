import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/models/farmacia.model.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/models/usuario.model.dart';
import 'package:medrush/theme/theme.dart';

/// Helpers centralizados para mostrar estado y tipo de pedidos
class StatusHelpers {
  const StatusHelpers._();

  static String estadoPedidoTexto(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return 'Pendiente';
      case EstadoPedido.asignado:
        return 'Asignado';
      case EstadoPedido.recogido:
        return 'Recogido';
      case EstadoPedido.enRuta:
        return 'En Ruta';
      case EstadoPedido.entregado:
        return 'Entregado';
      case EstadoPedido.fallido:
        return 'Fallido';
      case EstadoPedido.cancelado:
        return 'Cancelado';
    }
  }

  static Color estadoPedidoColor(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return MedRushTheme.statusPending; // #FFA000 - Amarillo
      case EstadoPedido.asignado:
        return MedRushTheme.statusInProgress; // #006BBA - Azul en progreso
      case EstadoPedido.recogido:
        return const Color(0xFF9C27B0); // #9C27B0 - Morado
      case EstadoPedido.enRuta:
        return MedRushTheme.statusInProgress; // #006BBA - Azul en progreso
      case EstadoPedido.entregado:
        return MedRushTheme.statusCompleted; // #5F9041 - Verde completado
      case EstadoPedido.fallido:
        return MedRushTheme.statusFailed; // #D32F2F - Rojo
      case EstadoPedido.cancelado:
        return MedRushTheme.statusCancelled; // #757575 - Gris
    }
  }

  static IconData estadoPedidoIcon(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return LucideIcons.clock;
      case EstadoPedido.asignado:
        return LucideIcons.userCheck;
      case EstadoPedido.recogido:
        return LucideIcons.package;
      case EstadoPedido.enRuta:
        return LucideIcons.truck;
      case EstadoPedido.entregado:
        return LucideIcons.check;
      case EstadoPedido.fallido:
        return LucideIcons.x;
      case EstadoPedido.cancelado:
        return LucideIcons.x;
    }
  }

  static String tipoPedidoTexto(TipoPedido tipo) {
    switch (tipo) {
      case TipoPedido.medicamentos:
        return 'Medicamentos';
      case TipoPedido.insumosMedicos:
        return 'Insumos Médicos';
      case TipoPedido.equiposMedicos:
        return 'Equipos Médicos';
      case TipoPedido.medicamentosControlados:
        return 'Medicamentos Controlados';
    }
  }

  // ===== Repartidor =====
  static String estadoRepartidorTexto(EstadoRepartidor estado) {
    switch (estado) {
      case EstadoRepartidor.disponible:
        return 'Disponible';
      case EstadoRepartidor.enRuta:
        return 'En Ruta';
      case EstadoRepartidor.desconectado:
        return 'Desconectado';
    }
  }

  static Color estadoRepartidorColor(EstadoRepartidor estado) {
    switch (estado) {
      case EstadoRepartidor.disponible:
        return MedRushTheme.statusAvailable; // #5F9041 - Verde disponible
      case EstadoRepartidor.enRuta:
        return MedRushTheme.statusBusy; // #FF6F00 - Naranja en ruta
      case EstadoRepartidor.desconectado:
        return MedRushTheme.statusOffline; // #757575 - Gris desconectado
    }
  }

  static IconData estadoRepartidorIcon(EstadoRepartidor? estado) {
    if (estado == null) {
      return LucideIcons.circleQuestionMark;
    }

    switch (estado) {
      case EstadoRepartidor.disponible:
        return LucideIcons.check;
      case EstadoRepartidor.enRuta:
        return LucideIcons.route;
      case EstadoRepartidor.desconectado:
        return LucideIcons.circleX;
    }
  }

  // ===== Farmacia =====
  static String estadoFarmaciaTexto(EstadoFarmacia estado) {
    switch (estado) {
      case EstadoFarmacia.activa:
        return 'Activa';
      case EstadoFarmacia.inactiva:
        return 'Inactiva';
      case EstadoFarmacia.suspendida:
        return 'Suspendida';
      case EstadoFarmacia.enRevision:
        return 'En Revisión';
    }
  }

  static Color estadoFarmaciaColor(EstadoFarmacia estado) {
    switch (estado) {
      case EstadoFarmacia.activa:
        return MedRushTheme.statusCompleted; // Verde asparagus - activa
      case EstadoFarmacia.inactiva:
        return MedRushTheme.statusCancelled; // Gris - inactiva
      case EstadoFarmacia.suspendida:
        return MedRushTheme.statusFailed; // Rojo - suspendida
      case EstadoFarmacia.enRevision:
        return MedRushTheme.statusPending; // Amarillo - en revisión
    }
  }

  static IconData estadoFarmaciaIcon(EstadoFarmacia estado) {
    switch (estado) {
      case EstadoFarmacia.activa:
        return LucideIcons.check;
      case EstadoFarmacia.inactiva:
        return LucideIcons.x;
      case EstadoFarmacia.suspendida:
        return LucideIcons.pause;
      case EstadoFarmacia.enRevision:
        return LucideIcons.clock;
    }
  }

  // ===== Delegaciones para Theme (compatibilidad) =====
  static String estadoPedidoTextoString(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'asignado':
        return 'Asignado';
      case 'en_progreso':
        return 'En Progreso';
      case 'recogido':
        return 'Recogido';
      case 'en_ruta':
      case 'enruta':
        return 'En Ruta';
      case 'entregado':
      case 'completado':
        return 'Entregado';
      case 'fallido':
      case 'error':
        return 'Fallido';
      case 'cancelado':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  static Color colorPorEstadoPedidoString(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return MedRushTheme.statusPending;
      case 'asignado':
      case 'en_progreso':
        return MedRushTheme.statusInProgress;
      case 'recogido':
        return const Color(0xFF9C27B0); // Morado para recogido
      case 'en_ruta':
      case 'enruta':
        return MedRushTheme.statusInProgress;
      case 'entregado':
      case 'completado':
        return MedRushTheme.statusCompleted;
      case 'fallido':
      case 'error':
        return MedRushTheme.statusFailed;
      case 'cancelado':
        return MedRushTheme.statusCancelled;
      default:
        return MedRushTheme.textSecondary;
    }
  }

  static IconData iconoPorEstadoPedidoString(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return LucideIcons.clock;
      case 'asignado':
        return LucideIcons.userCheck;
      case 'en_progreso':
        return LucideIcons.truck;
      case 'recogido':
        return LucideIcons.package;
      case 'en_ruta':
      case 'enruta':
        return LucideIcons.truck;
      case 'entregado':
      case 'completado':
        return LucideIcons.check;
      case 'fallido':
      case 'error':
        return LucideIcons.x;
      case 'cancelado':
        return LucideIcons.x;
      default:
        return LucideIcons.circleQuestionMark;
    }
  }

  static Color colorPorEstadoRepartidorString(String status) {
    switch (status.toLowerCase()) {
      case 'disponible':
        return MedRushTheme.statusAvailable;
      case 'en_ruta':
      case 'enruta':
        return MedRushTheme.statusBusy;
      case 'desconectado':
      case 'offline':
        return MedRushTheme.statusOffline;
      default:
        return MedRushTheme.textSecondary;
    }
  }

  // ===== Formateo de Fechas =====
  static String formatearFechaRelativa(DateTime fecha) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final fechaComparar = DateTime(fecha.year, fecha.month, fecha.day);

    final diferencia = fechaComparar.difference(hoy).inDays;

    if (diferencia == 0) {
      return 'Hoy, ${_formatearHora(fecha)}';
    } else if (diferencia == 1) {
      return 'Mañana, ${_formatearHora(fecha)}';
    } else if (diferencia == -1) {
      return 'Ayer, ${_formatearHora(fecha)}';
    } else if (diferencia > 1 && diferencia <= 7) {
      return '${_obtenerNombreDia(fecha)}, ${_formatearHora(fecha)}';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}, ${_formatearHora(fecha)}';
    }
  }

  /// Formatea una fecha relativa optimizada (solo muestra año si es diferente al actual)
  static String formatearFechaRelativaOptimizada(DateTime fecha) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final fechaComparar = DateTime(fecha.year, fecha.month, fecha.day);

    final diferencia = fechaComparar.difference(hoy).inDays;

    if (diferencia == 0) {
      return 'Hoy, ${_formatearHora(fecha)}';
    } else if (diferencia == 1) {
      return 'Mañana, ${_formatearHora(fecha)}';
    } else if (diferencia == -1) {
      return 'Ayer, ${_formatearHora(fecha)}';
    } else if (diferencia > 1 && diferencia <= 7) {
      return '${_obtenerNombreDia(fecha)}, ${_formatearHora(fecha)}';
    } else {
      // Solo mostrar año si es diferente al actual
      final anoActual = ahora.year;
      if (fecha.year == anoActual) {
        return '${fecha.day}/${fecha.month}, ${_formatearHora(fecha)}';
      } else {
        return '${fecha.day}/${fecha.month}/${fecha.year}, ${_formatearHora(fecha)}';
      }
    }
  }

  /// Formatea una fecha en formato relativo personalizado (hace 1hr, hace 1hr 15min, hace 2 días, etc.)
  static String formatearFechaRelativaPersonalizada(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    // Si es en el futuro, mostrar como "en X tiempo"
    if (diferencia.isNegative) {
      final diferenciaFutura = fecha.difference(ahora);
      return _formatearDiferenciaPositiva(diferenciaFutura, esFuturo: true);
    }

    return _formatearDiferenciaPositiva(diferencia, esFuturo: false);
  }

  /// Formatea una fecha relativa mejorada con rangos específicos
  static String formatearFechaRelativaMejorada(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    // Si es en el futuro, mostrar como "en X tiempo"
    if (diferencia.isNegative) {
      final diferenciaFutura = fecha.difference(ahora);
      return _formatearDiferenciaMejorada(diferenciaFutura, esFuturo: true);
    }

    return _formatearDiferenciaMejorada(diferencia, esFuturo: false);
  }

  /// Formatea una diferencia de tiempo en formato legible
  static String _formatearDiferenciaPositiva(Duration diferencia,
      {required bool esFuturo}) {
    final prefix = esFuturo ? 'en ' : 'hace ';

    final dias = diferencia.inDays;
    final horas = diferencia.inHours % 24;
    final minutos = diferencia.inMinutes % 60;

    // Si lleva días, mostrar solo días y horas (sin minutos)
    if (dias > 0) {
      if (horas > 0) {
        return '$prefix${dias}d ${horas}h';
      } else {
        return '$prefix${dias}d';
      }
    }

    // Si lleva horas, mostrar horas y minutos
    if (horas > 0) {
      if (minutos > 0) {
        return '$prefix${horas}h ${minutos}min';
      } else {
        return '$prefix${horas}h';
      }
    }

    // Si solo lleva minutos
    if (minutos > 0) {
      return '$prefix${minutos}min';
    }

    // Si es muy reciente (menos de 1 minuto)
    return esFuturo ? 'en 1 min' : 'hace 1 min';
  }

  /// Formatea una diferencia de tiempo mejorada con rangos específicos
  static String _formatearDiferenciaMejorada(Duration diferencia,
      {required bool esFuturo}) {
    final prefix = esFuturo ? 'en ' : 'hace ';

    final totalDias = diferencia.inDays;
    final anos = totalDias ~/ 365;
    final diasRestantes = totalDias % 365;
    final meses = diasRestantes ~/ 30;
    final dias = diasRestantes % 30;
    final horas = diferencia.inHours % 24;
    final minutos = diferencia.inMinutes % 60;

    // Si lleva años, mostrar años y meses
    if (anos > 0) {
      if (meses > 0) {
        return '$prefix${anos}yr ${meses}m';
      } else {
        return '$prefix${anos}yr';
      }
    }

    // Si lleva meses, mostrar meses y días
    if (meses > 0) {
      if (dias > 0) {
        return '$prefix${meses}m ${dias}d';
      } else {
        return '$prefix${meses}m';
      }
    }

    // Si lleva días, mostrar días y horas
    if (dias > 0) {
      if (horas > 0) {
        return '$prefix${dias}d ${horas}h';
      } else {
        return '$prefix${dias}d';
      }
    }

    // Si lleva horas, mostrar horas y minutos
    if (horas > 0) {
      if (minutos > 0) {
        return '$prefix${horas}h ${minutos}min';
      } else {
        return '$prefix${horas}h';
      }
    }

    // Si solo lleva minutos
    if (minutos > 0) {
      return '$prefix${minutos}min';
    }

    // Si es muy reciente (menos de 1 minuto)
    return esFuturo ? 'en 1 min' : 'hace 1 min';
  }

  static String _formatearHora(DateTime fecha) {
    return '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  static String _obtenerNombreDia(DateTime fecha) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    return dias[fecha.weekday - 1];
  }

  static String formatearFechaConVentana(
      DateTime fechaInicio, DateTime fechaFin) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final fechaComparar =
        DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);

    final diferencia = fechaComparar.difference(hoy).inDays;

    String prefijoFecha;
    if (diferencia == 0) {
      prefijoFecha = 'Hoy';
    } else if (diferencia == 1) {
      prefijoFecha = 'Mañana';
    } else if (diferencia == -1) {
      prefijoFecha = 'Ayer';
    } else if (diferencia > 1 && diferencia <= 7) {
      prefijoFecha = _obtenerNombreDia(fechaInicio);
    } else {
      prefijoFecha =
          '${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year}';
    }

    final horaInicio = _formatearHora(fechaInicio);
    final horaFin = _formatearHora(fechaFin);

    return '$prefijoFecha, $horaInicio - $horaFin';
  }

  // ===== Formateo de Fechas Estándar =====

  /// Formatea una fecha en formato DD/MM/YYYY HH:MM
  static String formatearFechaCompleta(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${_formatearHora(fecha)}';
  }

  /// Formatea una fecha en formato DD/MM/YYYY HH:MM (solo muestra año si es diferente al actual)
  static String formatearFechaCompletaOptimizada(DateTime fecha) {
    final ahora = DateTime.now();
    final anoActual = ahora.year;

    if (fecha.year == anoActual) {
      return '${fecha.day}/${fecha.month} ${_formatearHora(fecha)}';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year} ${_formatearHora(fecha)}';
    }
  }

  /// Formatea una fecha en formato DD/MM/YYYY HH:MM con ceros a la izquierda
  static String formatearFechaCompletaConCeros(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${_formatearHora(fecha)}';
  }

  /// Formatea una fecha en formato YYYY-MM-DD para APIs
  static String formatearFechaAPI(DateTime fecha) {
    return '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
  }

  // ===== Formateo de Tiempo =====

  /// Formatea tiempo en minutos a horas y minutos
  static String formatearTiempo(int minutos) {
    // Si el tiempo es muy grande (probablemente en segundos), convertir a minutos
    int minutosFinales = minutos;
    if (minutos > 1440) {
      // Más de 24 horas en minutos, probablemente está en segundos
      minutosFinales = (minutos / 60).round();
    }

    // Validar que el tiempo sea razonable (máximo 24 horas = 1440 minutos)
    if (minutosFinales > 1440) {
      return 'Tiempo inválido';
    }

    final horas = minutosFinales ~/ 60;
    final minutosRestantes = minutosFinales % 60;

    if (horas > 0 && minutosRestantes > 0) {
      return '$horas ${horas == 1 ? 'hora' : 'horas'} $minutosRestantes ${minutosRestantes == 1 ? 'minuto' : 'minutos'}';
    } else if (horas > 0) {
      return '$horas ${horas == 1 ? 'hora' : 'horas'}';
    } else {
      return '$minutosFinales ${minutosFinales == 1 ? 'minuto' : 'minutos'}';
    }
  }

  /// Formatea tiempo en segundos a formato legible
  static String formatearTiempoSegundos(int segundos) {
    final horas = segundos ~/ 3600;
    final minutos = (segundos % 3600) ~/ 60;
    final segundosRestantes = segundos % 60;

    if (horas > 0) {
      return '${horas}h ${minutos}m ${segundosRestantes}s';
    } else if (minutos > 0) {
      return '${minutos}m ${segundosRestantes}s';
    } else {
      return '${segundosRestantes}s';
    }
  }

  // ===== Formateo de Números =====

  /// Formatea un número con decimales específicos
  static String formatearNumero(double numero, {int decimales = 2}) {
    return numero.toStringAsFixed(decimales);
  }

  /// Formatea un número como porcentaje
  static String formatearPorcentaje(double numero, {int decimales = 1}) {
    return '${numero.toStringAsFixed(decimales)}%';
  }

  /// Formatea un número con separadores de miles (formato estadounidense)
  static String formatearNumeroConSeparadores(double numero,
      {int decimales = 0}) {
    final formatter = NumberFormat('#,##0.${'0' * decimales}');
    return formatter.format(numero);
  }

  // ===== Formateo de Distancias =====

  /// Formatea distancia en metros a formato legible
  static String formatearDistancia(double metros) {
    if (metros < 1000) {
      return '${metros.toStringAsFixed(0)} m';
    } else {
      final km = metros / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  /// Formatea distancia en kilómetros
  static String formatearDistanciaKm(double km, {int decimales = 1}) {
    return '${km.toStringAsFixed(decimales)} km';
  }

  // ===== Formateo de Coordenadas =====

  /// Formatea coordenadas de latitud y longitud
  static String formatearCoordenadas(double latitud, double longitud,
      {int decimales = 6}) {
    return '${latitud.toStringAsFixed(decimales)}, ${longitud.toStringAsFixed(decimales)}';
  }

  /// Formatea coordenadas con precisión estándar (4 decimales)
  static String formatearCoordenadasEstandar(double latitud, double longitud) {
    return formatearCoordenadas(latitud, longitud, decimales: 4);
  }

  /// Formatea coordenadas con alta precisión (6 decimales)
  static String formatearCoordenadasAltaPrecision(
      double latitud, double longitud) {
    return formatearCoordenadas(latitud, longitud);
  }

  // ===== Formateo de Tamaños de Archivo =====

  /// Formatea tamaño de archivo en bytes a formato legible
  static String formatearTamanoArchivo(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  // ===== Formateo de IDs y Códigos =====

  /// Formatea un ID con ceros a la izquierda
  static String formatearIdConCeros(int id, {int digitos = 4}) {
    return id.toString().padLeft(digitos, '0');
  }

  /// Formatea un código de barras
  static String formatearCodigoBarras(
      String pedidoId, String farmaciaId, DateTime timestamp) {
    final timestampStr =
        timestamp.toIso8601String().replaceAll(RegExp(r'[^\d]'), '');
    return 'MR${pedidoId.padLeft(4, '0')}${farmaciaId.padLeft(3, '0')}${timestampStr.substring(8)}${timestampStr.substring(0, 6)}';
  }

  // ===== Sistema de Prioridad de Fechas =====

  /// Obtiene la fecha más relevante según el sistema de prioridad:
  /// Prioridad 1: fechaEntrega > Prioridad 2: fechaRecogida > Prioridad 3: fechaAsignacion
  /// Si no hay fechas disponibles, retorna un mensaje descriptivo según el estado
  static String obtenerFechaSegunPrioridad(Pedido pedido) {
    // Prioridad 1: fechaEntrega (si existe)
    if (pedido.fechaEntrega != null) {
      return formatearFechaCompletaOptimizada(pedido.fechaEntrega!);
    }

    // Prioridad 2: fechaRecogida (si no hay entrega)
    if (pedido.fechaRecogida != null) {
      return formatearFechaCompletaOptimizada(pedido.fechaRecogida!);
    }

    // Prioridad 3: fechaAsignacion (si no hay recogida ni entrega)
    if (pedido.fechaAsignacion != null) {
      return formatearFechaCompletaOptimizada(pedido.fechaAsignacion!);
    }

    // Fallback: mostrar mensaje según estado si no hay ninguna fecha
    return _obtenerMensajeFallbackPorEstado(pedido.estado);
  }

  /// Obtiene la fecha más relevante con formato personalizado
  static String obtenerFechaSegunPrioridadConFormato(
      Pedido pedido, String Function(DateTime) formateador) {
    // Prioridad 1: fechaEntrega (si existe)
    if (pedido.fechaEntrega != null) {
      return formateador(pedido.fechaEntrega!);
    }

    // Prioridad 2: fechaRecogida (si no hay entrega)
    if (pedido.fechaRecogida != null) {
      return formateador(pedido.fechaRecogida!);
    }

    // Prioridad 3: fechaAsignacion (si no hay recogida ni entrega)
    if (pedido.fechaAsignacion != null) {
      return formateador(pedido.fechaAsignacion!);
    }

    // Fallback: mostrar mensaje según estado si no hay ninguna fecha
    return _obtenerMensajeFallbackPorEstado(pedido.estado);
  }

  /// Obtiene solo la fecha (sin hora) según el sistema de prioridad
  static String obtenerFechaSegunPrioridadSoloFecha(Pedido pedido) {
    // Prioridad 1: fechaEntrega (si existe)
    if (pedido.fechaEntrega != null) {
      return formatearFechaAPI(pedido.fechaEntrega!);
    }

    // Prioridad 2: fechaRecogida (si no hay entrega)
    if (pedido.fechaRecogida != null) {
      return formatearFechaAPI(pedido.fechaRecogida!);
    }

    // Prioridad 3: fechaAsignacion (si no hay recogida ni entrega)
    if (pedido.fechaAsignacion != null) {
      return formatearFechaAPI(pedido.fechaAsignacion!);
    }

    // Fallback: mostrar mensaje según estado si no hay ninguna fecha
    return _obtenerMensajeFallbackPorEstado(pedido.estado);
  }

  /// Obtiene la fecha relativa según el sistema de prioridad
  static String obtenerFechaRelativaSegunPrioridad(Pedido pedido) {
    // Prioridad 1: fechaEntrega (si existe)
    if (pedido.fechaEntrega != null) {
      return formatearFechaRelativaMejorada(pedido.fechaEntrega!);
    }

    // Prioridad 2: fechaRecogida (si no hay entrega)
    if (pedido.fechaRecogida != null) {
      return formatearFechaRelativaMejorada(pedido.fechaRecogida!);
    }

    // Prioridad 3: fechaAsignacion (si no hay recogida ni entrega)
    if (pedido.fechaAsignacion != null) {
      return formatearFechaRelativaMejorada(pedido.fechaAsignacion!);
    }

    // Fallback: mostrar mensaje según estado si no hay ninguna fecha
    return _obtenerMensajeFallbackPorEstado(pedido.estado);
  }

  /// Obtiene la fecha relativa optimizada según el sistema de prioridad (solo muestra año si es diferente al actual)
  static String obtenerFechaRelativaSegunPrioridadOptimizada(Pedido pedido) {
    // Prioridad 1: fechaEntrega (si existe)
    if (pedido.fechaEntrega != null) {
      return formatearFechaRelativaOptimizada(pedido.fechaEntrega!);
    }

    // Prioridad 2: fechaRecogida (si no hay entrega)
    if (pedido.fechaRecogida != null) {
      return formatearFechaRelativaOptimizada(pedido.fechaRecogida!);
    }

    // Prioridad 3: fechaAsignacion (si no hay recogida ni entrega)
    if (pedido.fechaAsignacion != null) {
      return formatearFechaRelativaOptimizada(pedido.fechaAsignacion!);
    }

    // Fallback: mostrar mensaje según estado si no hay ninguna fecha
    return _obtenerMensajeFallbackPorEstado(pedido.estado);
  }

  /// Obtiene el tipo de fecha que se está mostrando según la prioridad
  static String obtenerTipoFechaMostrada(Pedido pedido) {
    if (pedido.fechaEntrega != null) {
      return 'Entrega';
    }
    if (pedido.fechaRecogida != null) {
      return 'Recogida';
    }
    if (pedido.fechaAsignacion != null) {
      return 'Asignación';
    }
    return 'Sin fecha';
  }

  /// Obtiene el icono correspondiente al tipo de fecha mostrada
  static IconData obtenerIconoTipoFechaMostrada(Pedido pedido) {
    if (pedido.fechaEntrega != null) {
      return LucideIcons.check;
    }
    if (pedido.fechaRecogida != null) {
      return LucideIcons.package;
    }
    if (pedido.fechaAsignacion != null) {
      return LucideIcons.userCheck;
    }
    return LucideIcons.clock;
  }

  /// Obtiene el color correspondiente al tipo de fecha mostrada
  static Color obtenerColorTipoFechaMostrada(Pedido pedido) {
    if (pedido.fechaEntrega != null) {
      return MedRushTheme.statusCompleted; // Verde para entrega
    }
    if (pedido.fechaRecogida != null) {
      return const Color(0xFF9C27B0); // Morado para recogida
    }
    if (pedido.fechaAsignacion != null) {
      return MedRushTheme.statusInProgress; // Azul para asignación
    }
    return MedRushTheme.textSecondary; // Gris para sin fecha
  }

  /// Obtiene mensaje fallback según el estado del pedido
  static String _obtenerMensajeFallbackPorEstado(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return 'Sin fecha';
      case EstadoPedido.asignado:
        return 'Recién asignado';
      case EstadoPedido.recogido:
        return 'Recién recogido';
      case EstadoPedido.enRuta:
        return 'En ruta';
      case EstadoPedido.entregado:
        return 'Recién entregado';
      case EstadoPedido.fallido:
        return 'Entrega fallida';
      case EstadoPedido.cancelado:
        return 'Cancelado';
    }
  }

  // ===== Motivos de Fallo =====

  /// Convierte MotivoFalla a string para el backend
  static String motivoFallaToBackend(MotivoFalla motivo) {
    switch (motivo) {
      case MotivoFalla.noSeEncontraba:
        return 'no_se_encontraba';
      case MotivoFalla.direccionIncorrecta:
        return 'direccion_incorrecta';
      case MotivoFalla.noRecibioLlamadas:
        return 'no_recibio_llamadas';
      case MotivoFalla.rechazoEntrega:
        return 'rechazo_entrega';
      case MotivoFalla.accesoDenegado:
        return 'acceso_denegado';
      case MotivoFalla.otro:
        return 'otro';
    }
  }

  /// Obtiene el texto legible del motivo de fallo
  static String motivoFallaTexto(MotivoFalla motivo) {
    switch (motivo) {
      case MotivoFalla.noSeEncontraba:
        return 'Cliente no se encontraba';
      case MotivoFalla.direccionIncorrecta:
        return 'Dirección incorrecta';
      case MotivoFalla.noRecibioLlamadas:
        return 'No recibió llamadas';
      case MotivoFalla.rechazoEntrega:
        return 'Rechazó la entrega';
      case MotivoFalla.accesoDenegado:
        return 'Acceso denegado';
      case MotivoFalla.otro:
        return 'Otro motivo';
    }
  }

  /// Obtiene el icono del motivo de fallo
  static IconData motivoFallaIcono(MotivoFalla motivo) {
    switch (motivo) {
      case MotivoFalla.noSeEncontraba:
        return LucideIcons.userX;
      case MotivoFalla.direccionIncorrecta:
        return LucideIcons.mapPinOff;
      case MotivoFalla.noRecibioLlamadas:
        return LucideIcons.phoneOff;
      case MotivoFalla.rechazoEntrega:
        return LucideIcons.x;
      case MotivoFalla.accesoDenegado:
        return LucideIcons.lock;
      case MotivoFalla.otro:
        return LucideIcons.info;
    }
  }

  /// Obtiene el color del motivo de fallo
  static Color motivoFallaColor(MotivoFalla motivo) {
    switch (motivo) {
      case MotivoFalla.noSeEncontraba:
        return MedRushTheme.statusFailed;
      case MotivoFalla.direccionIncorrecta:
        return MedRushTheme.statusFailed;
      case MotivoFalla.noRecibioLlamadas:
        return MedRushTheme.statusFailed;
      case MotivoFalla.rechazoEntrega:
        return MedRushTheme.statusFailed;
      case MotivoFalla.accesoDenegado:
        return MedRushTheme.statusFailed;
      case MotivoFalla.otro:
        return MedRushTheme.statusFailed;
    }
  }

  /// Lista todos los motivos de fallo disponibles
  static List<MotivoFalla> obtenerMotivosFallo() {
    return MotivoFalla.values;
  }
}
