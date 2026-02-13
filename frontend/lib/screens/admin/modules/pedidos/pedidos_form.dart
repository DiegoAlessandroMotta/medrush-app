import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/models/farmacia.model.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/models/usuario.model.dart';
import 'package:medrush/repositories/base.repository.dart';
import 'package:medrush/repositories/farmacia.repository.dart';
import 'package:medrush/repositories/pedido.repository.dart';
import 'package:medrush/repositories/repartidor.repository.dart';
import 'package:medrush/services/geocoding_service.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:medrush/utils/validators.dart';
import 'package:medrush/widgets/mapa_widget.dart';

// Ancho máximo del bottom sheet en desktop para mejorar legibilidad
const double _kMaxDesktopSheetWidth = 980;

class EntregasForm extends StatefulWidget {
  final void Function(Pedido pedido) onSave;
  final Pedido? initialData;

  const EntregasForm({super.key, required this.onSave, this.initialData});

  @override
  State<EntregasForm> createState() => _EntregasFormState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<void Function(Pedido pedido)>.has(
          'onSave', onSave))
      ..add(DiagnosticsProperty<Pedido?>('initialData', initialData));
  }
}

class _EntregasFormState extends State<EntregasForm> {
  final _formKey = GlobalKey<FormState>();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _latLng;
  Timer? _debounce;

  // Controladores de texto
  final TextEditingController _codigoBarraController = TextEditingController();
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _direccionLinea1Controller =
      TextEditingController();
  final TextEditingController _direccionLinea2Controller =
      TextEditingController();
  final TextEditingController _distritoController = TextEditingController();
  final TextEditingController _estadoRegionController = TextEditingController();
  final TextEditingController _codigoPostalController = TextEditingController();
  final TextEditingController _codigoAccesoController = TextEditingController();
  final TextEditingController _observacionesController =
      TextEditingController();

  // Listas para dropdowns
  List<Farmacia> _farmacias = [];
  List<Usuario> _repartidores = [];

  // Valores seleccionados
  Farmacia? _farmaciaSeleccionada;
  Usuario? _repartidorSeleccionado;
  Usuario? _repartidorInicial; // Para detectar cambios
  EstadoPedido _estadoSeleccionado = EstadoPedido.pendiente;
  TipoPedido _tipoSeleccionado = TipoPedido.medicamentos;
  bool _requiereFirmaEspecial = false;

  // Lista de medicamentos
  List<Map<String, dynamic>> _medicamentos = [];

  // Estados de carga
  bool _isLoading = false;
  bool _isFarmaciasLoading = true;
  bool _isRepartidoresLoading = true;

  // Repositorio para operaciones de pedidos
  final PedidoRepository _pedidoRepository = PedidoRepository();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadDropdownData();
  }

  @override
  void didUpdateWidget(EntregasForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si los datos iniciales cambiaron, actualizar el formulario
    if (widget.initialData?.id != oldWidget.initialData?.id ||
        widget.initialData?.repartidorId !=
            oldWidget.initialData?.repartidorId) {
      _initializeData();
      _loadDropdownData();
    }
  }

  @override
  void dispose() {
    _codigoBarraController.dispose();
    _clienteController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionLinea1Controller.dispose();
    _direccionLinea2Controller.dispose();
    _distritoController.dispose();
    _estadoRegionController.dispose();
    _codigoPostalController.dispose();
    _codigoAccesoController.dispose();
    _observacionesController.dispose();
    _mapController?.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  LatLng? _buildLatLngFromControllers() {
    if (_latLng != null) {
      return _latLng;
    }
    return null;
  }

  void _abrirMapaPantallaCompleta() {
    final puntoInicial = _buildLatLngFromControllers();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapaPantallaCompleta(
          puntoInicial: puntoInicial,
          titulo: AppLocalizations.of(context).selectDeliveryLocationTitle,
          onUbicacionSeleccionada: (coordenadas, geocodingResult) {
            setState(() {
              _latLng = coordenadas;

              if (geocodingResult != null) {
                // Reemplazar dirección línea 1 (siempre que haya datos)
                if (geocodingResult.addressLine1.isNotEmpty) {
                  _direccionLinea1Controller.text =
                      geocodingResult.addressLine1;
                }

                // Reemplazar ciudad (siempre que haya datos)
                if (geocodingResult.city.isNotEmpty) {
                  _distritoController.text = geocodingResult.city;
                }

                // Reemplazar estado/región (siempre que haya datos)
                if (geocodingResult.state.isNotEmpty) {
                  _estadoRegionController.text = geocodingResult.state;
                }

                // Reemplazar código postal (siempre que haya datos)
                if (geocodingResult.postalCode.isNotEmpty) {
                  _codigoPostalController.text = geocodingResult.postalCode;
                }
              }
            });
          },
        ),
      ),
    );
  }

  void _initializeData() {
    if (widget.initialData != null) {
      final pedido = widget.initialData!;
      _codigoBarraController.text = pedido.codigoBarra;
      _clienteController.text = pedido.pacienteNombre;
      _telefonoController.text = pedido.pacienteTelefono;
      _emailController.text = pedido.pacienteEmail ?? '';
      _direccionLinea1Controller.text = pedido.direccionEntrega;
      _direccionLinea2Controller.text = pedido.direccionDetalle ?? '';
      _distritoController.text = pedido.distritoEntrega;
      _codigoAccesoController.text = pedido.codigoAcceso ?? '';
      _observacionesController.text = pedido.observaciones ?? '';
      _estadoSeleccionado = pedido.estado;
      _tipoSeleccionado = pedido.tipoPedido;
      _requiereFirmaEspecial = pedido.requiereFirmaEspecial;
      _medicamentos = List.from(pedido.medicamentos);
      if (pedido.latitudEntrega != null && pedido.longitudEntrega != null) {
        _latLng = LatLng(pedido.latitudEntrega!, pedido.longitudEntrega!);
      }
      _markers.add(Marker(
        markerId: const MarkerId('entrega'),
        position: _latLng!,
        infoWindow: InfoWindow(title: 'Pedido #${pedido.id}'),
      ));
    }
    // Generar código automáticamente si es nuevo o no viene en los datos iniciales
    if (_codigoBarraController.text.trim().isEmpty) {
      _codigoBarraController.text = _generateBarcodeCode();
    }
  }

  Future<void> _loadDropdownData() async {
    try {
      logInfo('Cargando datos para formulario de entregas');

      // Cargar farmacias y repartidores en paralelo usando helpers centralizados
      final farmaciasFuture = FarmaciaRepository.loadFarmaciasWithState(
        errorMessage: AppLocalizations.of(context).errorLoadingPharmaciesForForm,
      );
      final repartidorRepo = RepartidorRepository();
      final repartidoresFuture = repartidorRepo.getRepartidoresActivos();

      final farmaciasResult = await farmaciasFuture;
      final repartidoresRes = await repartidoresFuture;

      setState(() {
        _farmacias = farmaciasResult['farmacias'] as List<Farmacia>;
        _repartidores = repartidoresRes.data ?? [];
        _isFarmaciasLoading = farmaciasResult['isLoading'] as bool;
        _isRepartidoresLoading = false;

        // Si hay datos iniciales, seleccionar farmacia y repartidor
        if (widget.initialData != null) {
          _farmaciaSeleccionada = _farmacias.firstWhere(
            (f) => f.id == widget.initialData!.farmaciaId,
            orElse: () => _farmacias.first,
          );

          if (widget.initialData!.repartidorId != null) {
            try {
              _repartidorSeleccionado = _repartidores.firstWhere(
                (r) => r.id == widget.initialData!.repartidorId,
              );
              _repartidorInicial =
                  _repartidorSeleccionado; // Guardar repartidor inicial
            } catch (e) {
              // Si no se encuentra el repartidor, dejarlo como null
              _repartidorSeleccionado = null;
              _repartidorInicial = null;
              logInfo(
                  'Repartidor con ID ${widget.initialData!.repartidorId} no encontrado en la lista');
            }
          } else {
            _repartidorSeleccionado = null;
            _repartidorInicial = null;
          }
        }
      });

      logInfo(
          'Datos cargados: ${_farmacias.length} farmacias, ${_repartidores.length} repartidores');
    } catch (e) {
      logError('Error al cargar datos del formulario', e);
      setState(() {
        _isFarmaciasLoading = false;
        _isRepartidoresLoading = false;
      });

      if (mounted) {
        NotificationService.showError(
            AppLocalizations.of(context).errorLoadingData(e),
            context: context);
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_farmaciaSeleccionada == null) {
      NotificationService.showError(
          AppLocalizations.of(context).selectPharmacyRequired,
          context: context);
      return;
    }

    if (_latLng == null) {
      NotificationService.showError(
          AppLocalizations.of(context).selectLocationOnMap,
          context: context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isEditing = widget.initialData != null;
      logInfo('${isEditing ? 'Actualizando' : 'Creando'} pedido/entrega');

      // Preparar datos para el backend
      final pedidoData = <String, dynamic>{
        'farmacia_id': _farmaciaSeleccionada!.id,
        'paciente_nombre': _clienteController.text.trim(),
        'paciente_telefono':
            Validators.formatPhoneToE164(_telefonoController.text.trim()),
        'direccion_entrega_linea_1': _direccionLinea1Controller.text.trim(),
        'ciudad_entrega': _distritoController.text.trim(),
        'ubicacion_entrega': {
          'latitude': _latLng!.latitude,
          'longitude': _latLng!.longitude,
        },
        'tipo_pedido': _mapTipoPedidoToBackend(_tipoSeleccionado),
        'medicamentos': _medicamentos.isNotEmpty
            ? _medicamentos
                .map((m) => '${m['nombre']} x${m['cantidad']}')
                .join(', ')
            : null,
        'requiere_firma_especial': _requiereFirmaEspecial,
      };

      // Campos opcionales
      if (_emailController.text.trim().isNotEmpty) {
        pedidoData['paciente_email'] = _emailController.text.trim();
      }
      if (_direccionLinea2Controller.text.trim().isNotEmpty) {
        pedidoData['direccion_entrega_linea_2'] =
            _direccionLinea2Controller.text.trim();
      }
      if (_estadoRegionController.text.trim().isNotEmpty) {
        pedidoData['estado_region_entrega'] =
            _estadoRegionController.text.trim();
      }
      if (_codigoPostalController.text.trim().isNotEmpty) {
        pedidoData['codigo_postal_entrega'] =
            _codigoPostalController.text.trim();
      }
      if (_codigoAccesoController.text.trim().isNotEmpty) {
        pedidoData['codigo_acceso_edificio'] =
            _codigoAccesoController.text.trim();
      }
      if (_observacionesController.text.trim().isNotEmpty) {
        pedidoData['observaciones'] = _observacionesController.text.trim();
      }

      // NO incluir repartidor_id en pedidoData para ediciones
      // Se manejará por separado con el endpoint específico
      if (!isEditing && _repartidorSeleccionado != null) {
        pedidoData['repartidor_id'] = _repartidorSeleccionado!.id;
      }

      // Llamar al repositorio apropiado
      RepositoryResult<Pedido?> result;
      if (isEditing) {
        result = await _pedidoRepository.actualizarPedido(
          widget.initialData!.id,
          pedidoData,
        );
      } else {
        result = await _pedidoRepository.crearPedido(pedidoData);
      }

      if (!mounted) {
        return;
      }

      if (result.success && result.data != null) {
        logInfo('Pedido ${isEditing ? 'actualizado' : 'creado'} exitosamente');

        // Si es edición y el repartidor cambió, usar endpoint específico
        if (isEditing && _hasRepartidorChanged()) {
          await _handleRepartidorChange(result.data!);
          // _handleRepartidorChange ya llama a widget.onSave con datos actualizados
        } else {
          // Mostrar mensaje de éxito
          NotificationService.showSuccess(
            isEditing
                ? AppLocalizations.of(context).orderUpdatedSuccess
                : AppLocalizations.of(context).orderCreatedSuccess,
            context: context,
          );

          // Llamar al callback para notificar al padre
          widget.onSave(result.data!);
        }
      } else {
        logError(
            'Error al ${isEditing ? 'actualizar' : 'crear'} pedido: ${result.error}');

        final l10n = AppLocalizations.of(context);
        NotificationService.showError(
          '${isEditing ? l10n.errorUpdatingOrder : l10n.errorCreatingOrder}: ${result.error ?? l10n.unknownError}',
          context: context,
        );
      }
    } catch (e) {
      logError('❌ Error al guardar pedido', e);

      if (mounted) {
        NotificationService.showError(
            AppLocalizations.of(context).errorSavingOrder(e),
            context: context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kMaxDesktopSheetWidth),
        child: Material(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            child: Column(
              children: [
                // Header con drag handle y botón de cerrar
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  decoration: const BoxDecoration(
                    color: MedRushTheme.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              MedRushTheme.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Header con título y botón de cerrar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.initialData != null
                                      ? AppLocalizations.of(context).editDelivery
                                      : AppLocalizations.of(context).newDelivery,
                                  style: const TextStyle(
                                    fontSize: MedRushTheme.fontSizeTitleLarge,
                                    fontWeight: MedRushTheme.fontWeightBold,
                                    color: MedRushTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.initialData != null
                                      ? '${AppLocalizations.of(context).orderIdShort}${widget.initialData!.id}'
                                      : AppLocalizations.of(context).creatingNewDelivery,
                                  style: const TextStyle(
                                    fontSize: MedRushTheme.fontSizeBodySmall,
                                    color: MedRushTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              LucideIcons.x,
                              color: MedRushTheme.textSecondary,
                              size: 24,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: MedRushTheme.backgroundSecondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Contenido del formulario
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth > 768;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: MedRushTheme.spacingMd),

                              // Campos en layout responsivo
                              if (isDesktop) ...[
                                // Layout de 2 columnas para desktop
                                _buildDesktopLayout(),
                              ] else ...[
                                // Layout de 1 columna para móvil
                                _buildMobileLayout(),
                              ],

                              const SizedBox(height: MedRushTheme.spacingLg),

                              // Sección de dirección (siempre en columna completa)
                              _buildDireccionSection(),

                              const SizedBox(height: MedRushTheme.spacingLg),

                              // Sección de medicamentos
                              _buildMedicamentosSection(),

                              const SizedBox(height: MedRushTheme.spacingMd),

                              // Requiere Firma Especial
                              _buildFirmaEspecialSection(),

                              const SizedBox(height: MedRushTheme.spacingMd),

                              // Observaciones (opcional)
                              TextFormField(
                                controller: _observacionesController,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context).observationsOptionalLabel,
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(LucideIcons.fileText),
                                ),
                                minLines: 1,
                                maxLines: 3,
                              ),
                              const SizedBox(height: MedRushTheme.spacingLg),

                              // Botón de guardar
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : _handleSave,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(LucideIcons.save),
                                label: Text(_isLoading
                                    ? AppLocalizations.of(context).saving
                                    : AppLocalizations.of(context).saveDelivery),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MedRushTheme.primaryGreen,
                                  foregroundColor: MedRushTheme.textInverse,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),

                              // Espacio extra al final para evitar que el contenido se corte
                              const SizedBox(height: MedRushTheme.spacingXl),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onAddressChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (value.trim().isEmpty) {
        return;
      }
      try {
        final results = await geocoding.locationFromAddress(value);
        if (results.isNotEmpty) {
          final r = results.first;
          _latLng = LatLng(r.latitude, r.longitude);
          _markers
            ..clear()
            ..add(const Marker(markerId: MarkerId('entrega'))
                .copyWith(positionParam: _latLng));
          _mapController
              ?.animateCamera(CameraUpdate.newLatLngZoom(_latLng!, 15));
          setState(() {});
        }
      } catch (e) {
        logInfo('⚠️ Geocoding falló para "$value": $e');
      }
    });
  }

  Widget _buildTelefonoField() {
    return TextFormField(
      controller: _telefonoController,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).phoneRequiredLabel,
        hintText: AppLocalizations.of(context).phoneHint,
        helperText: '10 dígitos',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(LucideIcons.phone),
        prefixText: '+1 ',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(15),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppLocalizations.of(context).phoneRequired;
        }

        final soloNumeros = Validators.removeNonDigits(value);
        if (soloNumeros.length < 10 || soloNumeros.length > 12) {
          return AppLocalizations.of(context).phoneLengthBetween;
        }

        return null;
      },
      onChanged: (_) => setState(() {}),
    );
  }

  Future<void> _reverseGeocodeAndFill(LatLng pos) async {
    try {
      final result =
          await GeocodingService.reverseGeocode(pos.latitude, pos.longitude);

      if (result != null) {
        // Reemplazar dirección línea 1 (siempre que haya datos)
        if (result.addressLine1.isNotEmpty) {
          _direccionLinea1Controller.text = result.addressLine1;
        }

        // Reemplazar ciudad (siempre que haya datos)
        if (result.city.isNotEmpty) {
          _distritoController.text = result.city;
        }

        // Reemplazar estado/región (siempre que haya datos)
        if (result.state.isNotEmpty) {
          _estadoRegionController.text = result.state;
        }

        // Reemplazar código postal (siempre que haya datos)
        if (result.postalCode.isNotEmpty) {
          _codigoPostalController.text = result.postalCode;
        }
      }
      setState(() {});
    } catch (e) {
      logInfo('⚠️ Reverse geocoding falló: $e');
    }
  }

  String _generateBarcodeCode() {
    final DateTime now = DateTime.now();
    final String yy =
        StatusHelpers.formatearIdConCeros(now.year % 100, digitos: 2);
    final String mm = StatusHelpers.formatearIdConCeros(now.month, digitos: 2);
    final String dd = StatusHelpers.formatearIdConCeros(now.day, digitos: 2);
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random random = Random.secure();
    final String suffix =
        List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
    final String code = '$yy$mm$dd$suffix';
    logInfo('Código de barras generado para entrega: $code');
    return code;
  }

  /// Mapea el enum TipoPedido del frontend al formato esperado por el backend
  String _mapTipoPedidoToBackend(TipoPedido tipo) {
    switch (tipo) {
      case TipoPedido.medicamentos:
        return 'medicamentos';
      case TipoPedido.insumosMedicos:
        return 'insumos_medicos';
      case TipoPedido.equiposMedicos:
        return 'equipos_medicos';
      case TipoPedido.medicamentosControlados:
        return 'medicamentos_controlados';
    }
  }

  /// Detecta si el repartidor ha cambiado desde la carga inicial
  bool _hasRepartidorChanged() {
    if (widget.initialData == null) {
      return false; // No es edición
    }

    final repartidorInicialId = _repartidorInicial?.id;
    final repartidorActualId = _repartidorSeleccionado?.id;

    return repartidorInicialId != repartidorActualId;
  }

  /// Maneja el cambio de repartidor usando el endpoint específico
  Future<void> _handleRepartidorChange(Pedido pedido) async {
    try {
      logInfo('Cambiando repartidor del pedido ${pedido.id}');

      RepositoryResult<Pedido?> result;

      if (_repartidorSeleccionado == null) {
        // Si se desasignó el repartidor, usar endpoint de retirar
        result = await _pedidoRepository.retirarRepartidor(pedido.id);
        if (!mounted) {
          return;
        }
        if (result.success) {
          logInfo('✅ Repartidor retirado exitosamente');
        } else {
          logError('❌ Error al retirar repartidor: ${result.error}');
          if (!mounted) {
            return;
          }
          final l10n = AppLocalizations.of(context);
          NotificationService.showError(
            '${l10n.errorUnassigningDriver}: ${result.error ?? l10n.unknownError}',
            context: context,
          );
          return; // Salir si hay error
        }
      } else {
        // Si se asignó/reasignó repartidor, usar endpoint de asignar
        result = await _pedidoRepository.asignarPedido(
          pedido.id,
          _repartidorSeleccionado!.id,
        );
        if (!mounted) {
          return;
        }
        if (result.success) {
          logInfo('✅ Repartidor asignado exitosamente');
        } else {
          logError('❌ Error al asignar repartidor: ${result.error}');
          if (!mounted) {
            return;
          }
          final l10n = AppLocalizations.of(context);
          NotificationService.showError(
            '${l10n.errorAssigningDriver}: ${result.error ?? l10n.unknownError}',
            context: context,
          );
          return; // Salir si hay error
        }
      }

      // Obtener datos actualizados del pedido después del cambio
      await _refreshPedidoData(pedido.id);
    } catch (e) {
      logError('❌ Error al cambiar repartidor', e);
      if (!mounted) {
        return;
      }
      NotificationService.showError(
        AppLocalizations.of(context).errorChangingDriver(e),
        context: context,
      );
    }
  }

  /// Obtiene los datos actualizados del pedido y actualiza el formulario
  Future<void> _refreshPedidoData(String pedidoId) async {
    try {
      logInfo('Obteniendo datos actualizados del pedido $pedidoId');

      final result = await _pedidoRepository.obtenerPorId(pedidoId);
      if (!mounted) {
        return;
      }

      if (result.success && result.data != null) {
        final pedidoActualizado = result.data!;

        // Actualizar el repartidor seleccionado con los datos frescos
        if (pedidoActualizado.repartidorId != null) {
          _repartidorSeleccionado = _repartidores.firstWhere(
            (r) => r.id == pedidoActualizado.repartidorId,
            orElse: () => _repartidores.first,
          );
        } else {
          _repartidorSeleccionado = null;
        }

        // Actualizar el repartidor inicial para futuras comparaciones
        _repartidorInicial = _repartidorSeleccionado;

        // Actualizar el estado del pedido
        _estadoSeleccionado = pedidoActualizado.estado;

        // IMPORTANTE: Llamar setState para actualizar la UI
        if (mounted) {
          setState(() {
            // Las variables ya están actualizadas arriba
          });
        }

        logInfo('✅ Datos del formulario actualizados correctamente');

        // Notificar al padre con los datos actualizados
        widget.onSave(pedidoActualizado);
      } else {
        logError('❌ Error al obtener datos actualizados: ${result.error}');
        if (!mounted) {
          return;
        }
        final l10n = AppLocalizations.of(context);
        NotificationService.showError(
          '${l10n.errorFetchingUpdatedData}: ${result.error ?? l10n.unknownError}',
          context: context,
        );
      }
    } catch (e) {
      logError('❌ Error al refrescar datos del pedido', e);
      if (!mounted) {
        return;
      }
      NotificationService.showError(
        AppLocalizations.of(context).errorRefreshingData(e),
        context: context,
      );
    }
  }

  Widget _buildDireccionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).deliveryAddress,
          style: const TextStyle(
            fontSize: MedRushTheme.fontSizeBodyLarge,
            fontWeight: MedRushTheme.fontWeightMedium,
            color: MedRushTheme.textPrimary,
          ),
        ),
        const SizedBox(height: MedRushTheme.spacingSm),

        // Estado (State)
        TextFormField(
          controller: _estadoRegionController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).stateOptionalLabel,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(LucideIcons.mapPin),
          ),
        ),
        const SizedBox(height: MedRushTheme.spacingMd),

        // Distrito (City)
        TextFormField(
          controller: _distritoController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).districtRequiredLabel,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(LucideIcons.mapPin),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppLocalizations.of(context).districtRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: MedRushTheme.spacingMd),

        // Código Postal (ZIP Code)
        TextFormField(
          controller: _codigoPostalController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).postalCodeOptionalLabel,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(LucideIcons.mail),
          ),
        ),
        const SizedBox(height: MedRushTheme.spacingMd),

        // Dirección Línea 1
        TextFormField(
          controller: _direccionLinea1Controller,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).deliveryAddressLine1Label,
            helperText: AppLocalizations.of(context).addressLine1HelperText,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(LucideIcons.mapPin),
          ),
          minLines: 1,
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppLocalizations.of(context).deliveryAddressLine1Required;
            }
            return null;
          },
          onChanged: _onAddressChanged,
        ),
        const SizedBox(height: MedRushTheme.spacingMd),

        // Dirección Línea 2
        TextFormField(
          controller: _direccionLinea2Controller,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).deliveryAddressLine2OptionalLabel,
            helperText: AppLocalizations.of(context).addressLine2HelperText,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(LucideIcons.mapPin),
          ),
          minLines: 1,
          maxLines: 2,
        ),
        const SizedBox(height: MedRushTheme.spacingMd),

        // Mapa interactivo
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  LucideIcons.mapPin,
                  size: 16,
                  color: MedRushTheme.primaryGreen,
                ),
                SizedBox(width: 6),
                Text(
                  'Ubicación de Entrega *',
                  style: TextStyle(
                    fontWeight: MedRushTheme.fontWeightBold,
                    color: MedRushTheme.textPrimary,
                    fontSize: MedRushTheme.fontSizeBodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: MedRushTheme.spacingSm),
            Stack(
              children: [
                MapaWidget(
                  pedidos: const [],
                  puntoSeleccionado: _buildLatLngFromControllers(),
                  height: 300,
                  onTapMapa: (pos) async {
                    _latLng = pos;
                    _markers
                      ..clear()
                      ..add(Marker(
                        markerId: const MarkerId('entrega'),
                        position: pos,
                      ));
                    setState(() {});
                    await _reverseGeocodeAndFill(pos);
                  },
                ),
                // Botón de pantalla completa
                Positioned(
                  top: 8,
                  right: 8,
                  child: FloatingActionButton.small(
                    heroTag: 'fab_mapa_pedidos_form',
                    onPressed: _abrirMapaPantallaCompleta,
                    backgroundColor: MedRushTheme.primaryGreen,
                    foregroundColor: MedRushTheme.textInverse,
                    child: const Icon(LucideIcons.maximize),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEstadoSoloLecturaSection() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: MedRushTheme.backgroundSecondary,
        border: Border.all(
          color: MedRushTheme.textSecondary.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            StatusHelpers.estadoPedidoIcon(_estadoSeleccionado),
            color: MedRushTheme.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: MedRushTheme.spacingSm,
              runSpacing: 4,
              children: [
                Text(
                  AppLocalizations.of(context).orderStatusLabel,
                  style: const TextStyle(
                    fontSize: MedRushTheme.fontSizeBodyMedium,
                    fontWeight: MedRushTheme.fontWeightMedium,
                    color: MedRushTheme.textSecondary,
                  ),
                ),
                Text(
                  StatusHelpers.estadoPedidoTexto(_estadoSeleccionado, AppLocalizations.of(context)),
                  style: TextStyle(
                    fontSize: MedRushTheme.fontSizeBodyMedium,
                    fontWeight: MedRushTheme.fontWeightBold,
                    color: StatusHelpers.estadoPedidoColor(_estadoSeleccionado),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirmaEspecialSection() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: MedRushTheme.textSecondary.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.penTool,
            color: MedRushTheme.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).requiresSpecialSignature,
                  style: const TextStyle(
                    fontSize: MedRushTheme.fontSizeBodyMedium,
                    fontWeight: MedRushTheme.fontWeightMedium,
                    color: MedRushTheme.textPrimary,
                  ),
                ),
                Text(
                  _requiereFirmaEspecial ? AppLocalizations.of(context).yes : AppLocalizations.of(context).no,
                  style: const TextStyle(
                    fontSize: MedRushTheme.fontSizeBodySmall,
                    color: MedRushTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _requiereFirmaEspecial,
            onChanged: (value) {
              setState(() {
                _requiereFirmaEspecial = value;
              });
            },
            activeThumbColor: MedRushTheme.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicamentosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context).medications,
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodyLarge,
                fontWeight: MedRushTheme.fontWeightMedium,
                color: MedRushTheme.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: _addMedicamento,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text(AppLocalizations.of(context).add),
              style: TextButton.styleFrom(
                foregroundColor: MedRushTheme.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: MedRushTheme.spacingSm),
        if (_medicamentos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(MedRushTheme.spacingMd),
            decoration: BoxDecoration(
              color: MedRushTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
              border: Border.all(
                color: MedRushTheme.textSecondary.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              AppLocalizations.of(context).noMedicationsAddedHint,
              style: const TextStyle(
                color: MedRushTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...List.generate(_medicamentos.length, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: MedRushTheme.spacingSm),
              padding: const EdgeInsets.all(MedRushTheme.spacingMd),
              decoration: BoxDecoration(
                color: MedRushTheme.surface,
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusSm),
                border: Border.all(
                  color: MedRushTheme.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _medicamentos[index]['nombre'] ?? AppLocalizations.of(context).medicationDefaultName,
                          style: const TextStyle(
                            fontWeight: MedRushTheme.fontWeightMedium,
                            color: MedRushTheme.textPrimary,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context).quantityLabelShort(_medicamentos[index]['cantidad'] ?? 1),
                          style: const TextStyle(
                            color: MedRushTheme.textSecondary,
                            fontSize: MedRushTheme.fontSizeBodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeMedicamento(index),
                    icon: const Icon(LucideIcons.trash2, color: Colors.red),
                    iconSize: 20,
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _addMedicamento() {
    showDialog(
      context: context,
      builder: (context) => _MedicamentoDialog(
        onSave: (nombre, cantidad) {
          setState(() {
            _medicamentos.add({
              'nombre': nombre,
              'cantidad': cantidad,
            });
          });
        },
      ),
    );
  }

  void _removeMedicamento(int index) {
    setState(() {
      _medicamentos.removeAt(index);
    });
  }

  Widget _buildRepartidorDropdown() {
    // Si hay muchos repartidores (>20), usar un dropdown con búsqueda
    if (_repartidores.length > 20) {
      return _buildRepartidorSearchableDropdown();
    }

    // Para listas pequeñas, usar dropdown normal
    return DropdownButtonFormField<Usuario>(
      initialValue: _repartidorSeleccionado,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).driverOptionalLabel,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(LucideIcons.truck),
        helperText: AppLocalizations.of(context).selectDriverForOrderHint,
      ),
      items: _isRepartidoresLoading
          ? [
              DropdownMenuItem<Usuario>(
                child: Text(AppLocalizations.of(context).loadingDrivers),
              ),
            ]
          : [
              DropdownMenuItem<Usuario>(
                child: Text(AppLocalizations.of(context).unassigned),
              ),
              ..._repartidores.map((repartidor) {
                return DropdownMenuItem<Usuario>(
                  value: repartidor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        repartidor.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (repartidor.telefono != null)
                        Text(
                          repartidor.telefono!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
      selectedItemBuilder: (context) {
        if (_isRepartidoresLoading) {
          return [Text(AppLocalizations.of(context).loadingDrivers)];
        }

        return [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(AppLocalizations.of(context).unassigned),
          ),
          ..._repartidores.map(
            (repartidor) => Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                repartidor.nombre,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ];
      },
      onChanged: _isRepartidoresLoading
          ? null
          : (Usuario? value) {
              setState(() {
                _repartidorSeleccionado = value;
              });
            },
    );
  }

  Widget _buildRepartidorSearchableDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).driverOptionalLabel,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(LucideIcons.truck),
            suffixIcon: const Icon(LucideIcons.chevronDown),
            helperText:
                '${_repartidores.length} repartidores disponibles - Toca para buscar',
            hintText: _repartidorSeleccionado?.nombre ?? AppLocalizations.of(context).unassigned,
          ),
          onTap: _showRepartidorSearchDialog,
        ),
        if (_repartidorSeleccionado != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MedRushTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: MedRushTheme.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.user,
                  color: MedRushTheme.primaryGreen,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _repartidorSeleccionado!.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: MedRushTheme.primaryGreen,
                        ),
                      ),
                      if (_repartidorSeleccionado!.telefono != null)
                        Text(
                          _repartidorSeleccionado!.telefono!,
                          style: TextStyle(
                            fontSize: 12,
                            color: MedRushTheme.primaryGreen
                                .withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _repartidorSeleccionado = null;
                    });
                  },
                  icon: const Icon(
                    LucideIcons.x,
                    color: MedRushTheme.primaryGreen,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showRepartidorSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _RepartidorSearchDialog(
        repartidores: _repartidores,
        repartidorSeleccionado: _repartidorSeleccionado,
        onRepartidorSelected: (repartidor) {
          setState(() {
            _repartidorSeleccionado = repartidor;
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        // Primera fila: Farmacia y Repartidor
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<Farmacia>(
                initialValue: _farmaciaSeleccionada,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).pharmacyRequiredLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(LucideIcons.building2),
                ),
                items: _isFarmaciasLoading
                    ? [
                        DropdownMenuItem(
                          child: Text(AppLocalizations.of(context).loadingPharmacies),
                        )
                      ]
                    : _farmacias.map((farmacia) {
                        return DropdownMenuItem<Farmacia>(
                          value: farmacia,
                          child: Text(farmacia.nombre),
                        );
                      }).toList(),
                onChanged: _isFarmaciasLoading
                    ? null
                    : (Farmacia? value) {
                        setState(() {
                          _farmaciaSeleccionada = value;
                        });
                      },
                validator: (value) {
                  if (value == null) {
                    return AppLocalizations.of(context).selectPharmacyRequired;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: MedRushTheme.spacingMd),
            Expanded(
              child: _buildRepartidorDropdown(),
            ),
          ],
        ),
        const SizedBox(height: MedRushTheme.spacingMd),

        // Segunda fila: Cliente y Teléfono
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _clienteController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).clientNameRequiredLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(LucideIcons.user),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context).clientNameRequired;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: MedRushTheme.spacingMd),
            Expanded(child: _buildTelefonoField()),
          ],
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // Tercera fila: Email
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).emailOptionalLabel,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(LucideIcons.mail),
          ),
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // Quinta fila: Código de Acceso
        TextFormField(
          controller: _codigoAccesoController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).buildingAccessCodeOptionalLabel,
            helperText: AppLocalizations.of(context).buildingAccessCodeHelper,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(LucideIcons.key),
          ),
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // Sexta fila: Estado (solo lectura) y Tipo de Pedido
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildEstadoSoloLecturaSection(),
            ),
            const SizedBox(width: MedRushTheme.spacingMd),
            Expanded(
              child: DropdownButtonFormField<TipoPedido>(
                initialValue: _tipoSeleccionado,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).orderTypeRequiredLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(LucideIcons.pill),
                ),
                items: TipoPedido.values.map((tipo) {
                  return DropdownMenuItem<TipoPedido>(
                    value: tipo,
                    child: Builder(
                      builder: (context) => Text(StatusHelpers.tipoPedidoTexto(tipo, AppLocalizations.of(context))),
                    ),
                  );
                }).toList(),
                onChanged: (TipoPedido? value) {
                  if (value != null) {
                    setState(() {
                      _tipoSeleccionado = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Farmacia (Dropdown)
        DropdownButtonFormField<Farmacia>(
          initialValue: _farmaciaSeleccionada,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).pharmacyRequiredLabel,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(LucideIcons.building2),
          ),
          items: _isFarmaciasLoading
              ? [
                  DropdownMenuItem(
                    child: Text(AppLocalizations.of(context).loadingPharmacies),
                  )
                ]
              : _farmacias.map((farmacia) {
                  return DropdownMenuItem<Farmacia>(
                    value: farmacia,
                    child: Text(farmacia.nombre),
                  );
                }).toList(),
          onChanged: _isFarmaciasLoading
              ? null
              : (Farmacia? value) {
                  setState(() {
                    _farmaciaSeleccionada = value;
                  });
                },
          validator: (value) {
            if (value == null) {
              return AppLocalizations.of(context).selectPharmacyRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: MedRushTheme.spacingMd),

        // Repartidor (Dropdown - opcional)
        _buildRepartidorDropdown(),
        const SizedBox(height: MedRushTheme.spacingMd),

        // Cliente
        TextFormField(
          controller: _clienteController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).clientNameRequiredLabel,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(LucideIcons.user),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppLocalizations.of(context).clientNameRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: MedRushTheme.spacingMd),

        // Teléfono
        _buildTelefonoField(),
        const SizedBox(height: MedRushTheme.spacingMd),

        // Email (opcional)
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).emailOptionalLabel,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(LucideIcons.mail),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: MedRushTheme.spacingMd),

        // Código de Acceso
        TextFormField(
          controller: _codigoAccesoController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).buildingAccessCodeOptionalLabel,
            helperText: AppLocalizations.of(context).buildingAccessCodeHelper,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(LucideIcons.key),
          ),
        ),
        const SizedBox(height: MedRushTheme.spacingMd),

        // Estado (Solo lectura)
        _buildEstadoSoloLecturaSection(),
        const SizedBox(height: MedRushTheme.spacingMd),

        // Tipo de pedido (Dropdown)
        DropdownButtonFormField<TipoPedido>(
          initialValue: _tipoSeleccionado,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).orderTypeRequiredLabel,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(LucideIcons.pill),
          ),
          items: TipoPedido.values.map((tipo) {
            return DropdownMenuItem<TipoPedido>(
              value: tipo,
              child: Builder(
                builder: (context) => Text(StatusHelpers.tipoPedidoTexto(tipo, AppLocalizations.of(context))),
              ),
            );
          }).toList(),
          onChanged: (TipoPedido? value) {
            if (value != null) {
              setState(() {
                _tipoSeleccionado = value;
              });
            }
          },
        ),
      ],
    );
  }
}

class _MedicamentoDialog extends StatefulWidget {
  final Function(String nombre, int cantidad) onSave;

  const _MedicamentoDialog({required this.onSave});

  @override
  State<_MedicamentoDialog> createState() => _MedicamentoDialogState();
}

class _MedicamentoDialogState extends State<_MedicamentoDialog> {
  final _nombreController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nombreController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).addMedicationTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).medicationNameRequiredLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context).medicationNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: MedRushTheme.spacingMd),
            TextFormField(
              controller: _cantidadController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).quantityRequiredLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context).medicationQuantityRequired;
                }
                final cantidad = int.tryParse(value);
                if (cantidad == null || cantidad <= 0) {
                  return AppLocalizations.of(context).enterValidQuantity;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _nombreController.text.trim(),
                int.parse(_cantidadController.text.trim()),
              );
              Navigator.of(context).pop();
            }
          },
          child: Text(AppLocalizations.of(context).add),
        ),
      ],
    );
  }
}

class _RepartidorSearchDialog extends StatefulWidget {
  final List<Usuario> repartidores;
  final Usuario? repartidorSeleccionado;
  final Function(Usuario?) onRepartidorSelected;

  const _RepartidorSearchDialog({
    required this.repartidores,
    this.repartidorSeleccionado,
    required this.onRepartidorSelected,
  });

  @override
  State<_RepartidorSearchDialog> createState() =>
      _RepartidorSearchDialogState();
}

class _RepartidorSearchDialogState extends State<_RepartidorSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Usuario> _filteredRepartidores = [];
  Usuario? _selectedRepartidor;

  @override
  void initState() {
    super.initState();
    _filteredRepartidores = widget.repartidores;
    _selectedRepartidor = widget.repartidorSeleccionado;
    _searchController.addListener(_filterRepartidores);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterRepartidores() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRepartidores = widget.repartidores;
      } else {
        _filteredRepartidores = widget.repartidores.where((repartidor) {
          return repartidor.nombre.toLowerCase().contains(query) ||
              (repartidor.telefono?.toLowerCase().contains(query) ?? false) ||
              repartidor.email.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(LucideIcons.truck, color: MedRushTheme.primaryGreen),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context).selectDriverTitle),
          const Spacer(),
          Text(
            '${_filteredRepartidores.length} disponibles',
            style: const TextStyle(
              fontSize: 12,
              color: MedRushTheme.textSecondary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // Campo de búsqueda
            TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).searchDriverHint,
                prefixIcon: const Icon(LucideIcons.search),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Lista de repartidores
            Expanded(
              child: ListView.builder(
                itemCount:
                    _filteredRepartidores.length + 1, // +1 para "Sin asignar"
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // Opción "Sin asignar"
                    return ListTile(
                      leading: const Icon(LucideIcons.userX),
                      title: Text(AppLocalizations.of(context).unassigned),
                      subtitle:
                          Text(AppLocalizations.of(context).unassignDriverOption),
                      selected: _selectedRepartidor == null,
                      onTap: () {
                        setState(() {
                          _selectedRepartidor = null;
                        });
                      },
                    );
                  }

                  final repartidor = _filteredRepartidores[index - 1];
                  final isSelected = _selectedRepartidor?.id == repartidor.id;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? MedRushTheme.primaryGreen
                          : MedRushTheme.backgroundSecondary,
                      child: Icon(
                        LucideIcons.user,
                        color: isSelected
                            ? MedRushTheme.textInverse
                            : MedRushTheme.textSecondary,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      repartidor.nombre,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (repartidor.telefono != null)
                          Text(repartidor.telefono!),
                        Text(
                          repartidor.email,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedRepartidor = repartidor;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onRepartidorSelected(_selectedRepartidor);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: MedRushTheme.primaryGreen,
            foregroundColor: MedRushTheme.textInverse,
          ),
          child: Text(AppLocalizations.of(context).select),
        ),
      ],
    );
  }
}
