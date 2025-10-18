// import eliminado: no se requiere generación de ID en cliente
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/api/farmacias.api.dart';
import 'package:medrush/models/farmacia.model.dart';
import 'package:medrush/services/geocoding_service.dart'; // Para GeocodingResult
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:medrush/widgets/mapa_widget.dart';

class FarmaciaForm extends StatefulWidget {
  final void Function(Farmacia farmacia)? onSave;
  final Farmacia? initialData;

  const FarmaciaForm({super.key, this.onSave, this.initialData});

  @override
  State<FarmaciaForm> createState() => _FarmaciaFormState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<void Function(Farmacia farmacia)?>.has(
          'onSave', onSave))
      ..add(DiagnosticsProperty<Farmacia?>('initialData', initialData));
  }
}

class _FarmaciaFormState extends State<FarmaciaForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _direccionLinea1Controller = TextEditingController();
  final _direccionLinea2Controller = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _responsableController = TextEditingController();
  final _latitudController = TextEditingController();
  final _longitudController = TextEditingController();
  final _rucController = TextEditingController();
  final _cadenaController = TextEditingController();
  final _distritoController = TextEditingController();
  final _horarioController = TextEditingController();
  final _provinciaController = TextEditingController();
  final _departamentoController = TextEditingController();
  final _telefonoResponsableController = TextEditingController();

  EstadoFarmacia _estado = EstadoFarmacia.activa;
  bool _delivery24h = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupAddressListeners();
  }

  void _setupAddressListeners() {
    _direccionLinea1Controller.addListener(_updateDireccionCompleta);
    _direccionLinea2Controller.addListener(_updateDireccionCompleta);
  }

  void _updateDireccionCompleta() {
    final linea1 = _direccionLinea1Controller.text.trim();
    final linea2 = _direccionLinea2Controller.text.trim();
    final direccionCompleta =
        [linea1, linea2].where((linea) => linea.isNotEmpty).join(', ');

    if (_direccionController.text != direccionCompleta) {
      _direccionController.text = direccionCompleta;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _direccionLinea1Controller.dispose();
    _direccionLinea2Controller.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _responsableController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    _rucController.dispose();
    _cadenaController.dispose();
    _distritoController.dispose();
    _provinciaController.dispose();
    _departamentoController.dispose();
    _horarioController.dispose();
    _telefonoResponsableController.dispose();
    super.dispose();
  }

  LatLng? _buildLatLngFromControllers() {
    final lat = double.tryParse(_latitudController.text.trim());
    final lng = double.tryParse(_longitudController.text.trim());
    if (lat == null || lng == null) {
      return null;
    }
    return LatLng(lat, lng);
  }

  void _initializeData() {
    if (widget.initialData != null) {
      final farmacia = widget.initialData!;
      _nombreController.text = farmacia.nombre;
      _direccionController.text = farmacia.direccion;
      _direccionLinea1Controller.text = farmacia.direccionLinea1 ?? '';
      _direccionLinea2Controller.text = farmacia.direccionLinea2 ?? '';
      _telefonoController.text = farmacia.telefono ?? '';
      _emailController.text = farmacia.email ?? '';
      _responsableController.text = farmacia.contactoResponsable ?? '';
      _latitudController.text = farmacia.latitud.toString();
      _longitudController.text = farmacia.longitud.toString();
      _rucController.text = farmacia.ruc;
      _cadenaController.text = farmacia.cadena ?? '';
      _distritoController.text = farmacia.city ?? '';
      _provinciaController.text = farmacia.state ?? '';
      _departamentoController.text = farmacia.zipCode ?? '';
      _horarioController.text = farmacia.horarioAtencion ?? '';
      _telefonoResponsableController.text = farmacia.telefonoResponsable ?? '';
      _estado = farmacia.estado;
      _delivery24h = farmacia.delivery24h;
    } else {
      // Valores por defecto para Lima
      _latitudController.text = '-12.0464';
      _longitudController.text = '-77.0428';
      _horarioController.text = 'Lun-Vie: 8:00-20:00';
    }
  }

  // Eliminado: el ID lo genera el backend (UUID). No generar en cliente.

  /// Formatea un número de teléfono al formato E.164 (+51...)
  String _formatPhoneToE164(String phone) {
    if (phone.isEmpty) {
      return phone;
    }

    // Remover espacios, guiones y paréntesis
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Si ya tiene +, devolverlo tal como está
    if (cleaned.startsWith('+')) {
      return cleaned;
    }

    // Si empieza con 51, agregar +
    if (cleaned.startsWith('51')) {
      return '+$cleaned';
    }

    // Si empieza con 9 (celular peruano), agregar +51
    if (cleaned.startsWith('9') && cleaned.length == 9) {
      return '+51$cleaned';
    }

    // Si es un número de 9 dígitos, asumir que es celular peruano
    if (cleaned.length == 9 && RegExp(r'^\d+$').hasMatch(cleaned)) {
      return '+51$cleaned';
    }

    // Si es un número de 7-8 dígitos, asumir que es fijo peruano
    if (cleaned.length >= 7 &&
        cleaned.length <= 8 &&
        RegExp(r'^\d+$').hasMatch(cleaned)) {
      return '+51$cleaned';
    }

    // Si no coincide con ningún patrón, devolver tal como está
    return phone;
  }

  void _abrirMapaPantallaCompleta() {
    final puntoInicial = _buildLatLngFromControllers();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapaPantallaCompleta(
          puntoInicial: puntoInicial,
          titulo: 'Seleccionar Ubicación de la Farmacia',
          onUbicacionSeleccionada: (coordenadas, geocodingResult) {
            setState(() {
              _latitudController.text = StatusHelpers.formatearNumero(
                  coordenadas.latitude,
                  decimales: 6);
              _longitudController.text = StatusHelpers.formatearNumero(
                  coordenadas.longitude,
                  decimales: 6);

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
                  _provinciaController.text = geocodingResult.state;
                }

                // Reemplazar código postal (siempre que haya datos)
                if (geocodingResult.postalCode.isNotEmpty) {
                  _departamentoController.text = geocodingResult.postalCode;
                }

                // Reemplazar dirección completa (siempre que haya datos)
                if (geocodingResult.formattedAddress.isNotEmpty) {
                  _direccionController.text = geocodingResult.formattedAddress;
                }
              }
            });
          },
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      logInfo(
          '${widget.initialData != null ? 'Actualizando' : 'Creando'} farmacia...');

      // El backend maneja la validación de RUC único automáticamente

      final farmacia = Farmacia(
        id: widget.initialData?.id ?? '',
        nombre: _nombreController.text.trim(),
        razonSocial: _nombreController.text
            .trim(), // Usar nombre como razón social por defecto
        direccion: _direccionController.text.trim(),
        direccionLinea1: _direccionLinea1Controller.text.trim().isNotEmpty
            ? _direccionLinea1Controller.text.trim()
            : null,
        direccionLinea2: _direccionLinea2Controller.text.trim().isNotEmpty
            ? _direccionLinea2Controller.text.trim()
            : null,
        telefono: _formatPhoneToE164(_telefonoController.text.trim()),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        contactoResponsable: _responsableController.text.trim().isNotEmpty
            ? _responsableController.text.trim()
            : null,
        telefonoResponsable:
            _telefonoResponsableController.text.trim().isNotEmpty
                ? _formatPhoneToE164(_telefonoResponsableController.text.trim())
                : null,
        ruc: _rucController.text.trim(),
        cadena: _cadenaController.text.trim(),
        city: _distritoController.text.trim(),
        state: _provinciaController.text.trim().isEmpty
            ? null
            : _provinciaController.text.trim(),
        zipCode: _departamentoController.text.trim().isEmpty
            ? null
            : _departamentoController.text.trim(),
        codigoIsoPais: 'PER', // Por defecto Perú
        latitud: double.tryParse(_latitudController.text.trim()) ?? -12.0464,
        longitud: double.tryParse(_longitudController.text.trim()) ?? -77.0428,
        estado: _estado,
        horarioAtencion: _horarioController.text.trim().isNotEmpty
            ? _horarioController.text.trim()
            : null,
        delivery24h: _delivery24h,
        fechaRegistro: widget.initialData?.fechaRegistro ?? DateTime.now(),
      );

      Farmacia farmaciaGuardada;

      if (widget.initialData != null) {
        // Actualizar farmacia existente
        logInfo('Actualizando farmacia: ${farmacia.nombre}');
        farmaciaGuardada = await FarmaciasApi.updateFarmacia(farmacia);
        logInfo(
            'Farmacia actualizada exitosamente: ${farmaciaGuardada.nombre}');
      } else {
        // Crear nueva farmacia
        logInfo('➕ Creando nueva farmacia: ${farmacia.nombre}');
        farmaciaGuardada = await FarmaciasApi.createFarmacia(farmacia);
        logInfo('Farmacia creada exitosamente: ${farmaciaGuardada.nombre}');
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      // Llamar callback con la farmacia guardada
      widget.onSave?.call(farmaciaGuardada);

      // Cerrar el formulario
      Navigator.of(context).pop();
    } catch (e) {
      logError(
          'Error al ${widget.initialData != null ? 'actualizar' : 'crear'} farmacia',
          e);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      // Mostrar error al usuario
      NotificationService.showError(
        'Error al ${widget.initialData != null ? 'actualizar' : 'crear'} farmacia: $e',
        context: context,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _handleDelete() async {
    if (widget.initialData == null) {
      return;
    }

    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la farmacia "${widget.initialData!.nombre}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      logInfo('Eliminando farmacia: ${widget.initialData!.nombre}');

      await FarmaciasApi.deleteFarmacia(widget.initialData!.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      // Mostrar mensaje de éxito
      NotificationService.showSuccess(
        'Farmacia "${widget.initialData!.nombre}" eliminada exitosamente',
        context: context,
        duration: const Duration(seconds: 3),
      );

      // Llamar callback con la farmacia eliminada
      widget.onSave?.call(widget.initialData!);

      // Cerrar el formulario
      Navigator.of(context).pop();
    } catch (e) {
      logError('Error al eliminar farmacia', e);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      // Mostrar error al usuario
      NotificationService.showError(
        'Error al eliminar farmacia: $e',
        context: context,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        // Primera fila: Nombre y Cadena
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Farmacia *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.building2),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre de la farmacia';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: MedRushTheme.spacingMd),
            Expanded(
              child: TextFormField(
                controller: _cadenaController,
                decoration: const InputDecoration(
                  labelText: 'Cadena (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.building),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // Segunda fila: Responsable y Teléfono Responsable
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _responsableController,
                decoration: const InputDecoration(
                  labelText: 'Responsable *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.user),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el responsable';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: MedRushTheme.spacingMd),
            Expanded(
              child: TextFormField(
                controller: _telefonoResponsableController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono del Responsable (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.phone),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // Tercera fila: Teléfono y Email
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.phone),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el teléfono';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: MedRushTheme.spacingMd),
            Expanded(
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.mail),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Por favor ingrese un correo válido';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // Cuarta fila: RUC (campo completo)
        TextFormField(
          controller: _rucController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'RUC *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(LucideIcons.shield),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese el RUC';
            }
            return null;
          },
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // Quinta fila: Estado y Delivery 24h
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: MedRushTheme.textSecondary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado de la Farmacia',
                      style: TextStyle(
                        fontSize: MedRushTheme.fontSizeBodyMedium,
                        fontWeight: MedRushTheme.fontWeightMedium,
                        color: MedRushTheme.textPrimary,
                      ),
                    ),
                    DropdownButtonFormField<EstadoFarmacia>(
                      initialValue: _estado,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      items: EstadoFarmacia.values.map((estado) {
                        return DropdownMenuItem<EstadoFarmacia>(
                          value: estado,
                          child: Text(
                            StatusHelpers.estadoFarmaciaTexto(estado),
                            style: TextStyle(
                              color: StatusHelpers.estadoFarmaciaColor(estado),
                              fontWeight: MedRushTheme.fontWeightMedium,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _estado = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: MedRushTheme.spacingMd),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: MedRushTheme.textSecondary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.truck,
                      color: MedRushTheme.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Delivery 24 horas',
                            style: TextStyle(
                              fontSize: MedRushTheme.fontSizeBodyMedium,
                              fontWeight: MedRushTheme.fontWeightMedium,
                              color: MedRushTheme.textPrimary,
                            ),
                          ),
                          Text(
                            _delivery24h ? 'Disponible' : 'No disponible',
                            style: const TextStyle(
                              fontSize: MedRushTheme.fontSizeBodySmall,
                              color: MedRushTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _delivery24h,
                      onChanged: (value) {
                        setState(() {
                          _delivery24h = value;
                        });
                      },
                      activeThumbColor: MedRushTheme.primaryGreen,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // Sexta fila: Horario de Atención
        TextFormField(
          controller: _horarioController,
          decoration: const InputDecoration(
            labelText: 'Horario de Atención (opcional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(LucideIcons.clock),
          ),
          validator: (value) {
            return null;
          },
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // Séptima fila: Dirección Línea 1 y Dirección Línea 2
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _direccionLinea1Controller,
                decoration: const InputDecoration(
                  labelText: 'Dirección Línea 1 *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.mapPin),
                  helperText: 'Calle, avenida, jirón, etc.',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la dirección línea 1';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: MedRushTheme.spacingMd),
            Expanded(
              child: TextFormField(
                controller: _direccionLinea2Controller,
                decoration: const InputDecoration(
                  labelText: 'Dirección Línea 2 (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.mapPin),
                  helperText: 'Piso, departamento, referencia, etc.',
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // Octava fila: ZIP Code y Ciudad
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _departamentoController,
                decoration: const InputDecoration(
                  labelText: 'ZIP Code (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.mapPin),
                ),
              ),
            ),
            const SizedBox(width: MedRushTheme.spacingMd),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _distritoController,
                decoration: const InputDecoration(
                  labelText: 'Ciudad *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.mapPin),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la ciudad';
                  }
                  return null;
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
        // 1. Campo Nombre de Farmacia
        TextFormField(
          controller: _nombreController,
          decoration: const InputDecoration(
            labelText: 'Nombre de la Farmacia *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(LucideIcons.building2),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese el nombre de la farmacia';
            }
            return null;
          },
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // 2. Campo Cadena
        TextFormField(
          controller: _cadenaController,
          decoration: const InputDecoration(
            labelText: 'Cadena (opcional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(LucideIcons.building),
          ),
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // 3. Campo Responsable
        TextFormField(
          controller: _responsableController,
          decoration: const InputDecoration(
            labelText: 'Responsable *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(LucideIcons.user),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese el responsable';
            }
            return null;
          },
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // 3.1. Campo Teléfono del Responsable
        TextFormField(
          controller: _telefonoResponsableController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Teléfono del Responsable (opcional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(LucideIcons.phone),
          ),
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // 4. Campo Teléfono
        TextFormField(
          controller: _telefonoController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Teléfono *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(LucideIcons.phone),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese el teléfono';
            }
            return null;
          },
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // 5. Campo Email
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo Electrónico (opcional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(LucideIcons.mail),
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Por favor ingrese un correo válido';
              }
            }
            return null;
          },
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // 6. Campo RUC
        TextFormField(
          controller: _rucController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'RUC *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(LucideIcons.shield),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese el RUC';
            }
            return null;
          },
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // 7. Campo Estado de la Farmacia
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            border: Border.all(
                color: MedRushTheme.textSecondary.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estado de la Farmacia',
                style: TextStyle(
                  fontSize: MedRushTheme.fontSizeBodyMedium,
                  fontWeight: MedRushTheme.fontWeightMedium,
                  color: MedRushTheme.textPrimary,
                ),
              ),
              DropdownButtonFormField<EstadoFarmacia>(
                initialValue: _estado,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                items: EstadoFarmacia.values.map((estado) {
                  return DropdownMenuItem<EstadoFarmacia>(
                    value: estado,
                    child: Text(
                      StatusHelpers.estadoFarmaciaTexto(estado),
                      style: TextStyle(
                        color: StatusHelpers.estadoFarmaciaColor(estado),
                        fontWeight: MedRushTheme.fontWeightMedium,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _estado = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // 8. Campo Horario de Atención
        TextFormField(
          controller: _horarioController,
          decoration: const InputDecoration(
            labelText: 'Horario de Atención (opcional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(LucideIcons.clock),
          ),
          validator: (value) {
            return null;
          },
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // 9. Campo Delivery 24h
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            border: Border.all(
                color: MedRushTheme.textSecondary.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.truck,
                color: MedRushTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery 24 horas',
                      style: TextStyle(
                        fontSize: MedRushTheme.fontSizeBodyMedium,
                        fontWeight: MedRushTheme.fontWeightMedium,
                        color: MedRushTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _delivery24h ? 'Disponible' : 'No disponible',
                      style: const TextStyle(
                        fontSize: MedRushTheme.fontSizeBodySmall,
                        color: MedRushTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _delivery24h,
                onChanged: (value) {
                  setState(() {
                    _delivery24h = value;
                  });
                },
                activeThumbColor: MedRushTheme.primaryGreen,
              ),
            ],
          ),
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // 10. Campo Dirección Línea 1
        TextFormField(
          controller: _direccionLinea1Controller,
          decoration: const InputDecoration(
            labelText: 'Dirección Línea 1 *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(LucideIcons.mapPin),
            helperText: 'Calle, avenida, jirón, etc.',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese la dirección línea 1';
            }
            return null;
          },
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // 11. Campo Dirección Línea 2
        TextFormField(
          controller: _direccionLinea2Controller,
          decoration: const InputDecoration(
            labelText: 'Dirección Línea 2 (opcional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(LucideIcons.mapPin),
            helperText: 'Piso, departamento, referencia, etc.',
          ),
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // 12. Campo ZIP Code
        TextFormField(
          controller: _departamentoController,
          decoration: const InputDecoration(
            labelText: 'ZIP Code (opcional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(LucideIcons.mapPin),
          ),
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // 13. Campo Ciudad
        TextFormField(
          controller: _distritoController,
          decoration: const InputDecoration(
            labelText: 'Ciudad *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(LucideIcons.mapPin),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese la ciudad';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Column(
          children: [
            // Header con drag handle y botón de cerrar
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              decoration: const BoxDecoration(
                color: MedRushTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: MedRushTheme.textSecondary.withValues(alpha: 0.3),
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
                                  ? 'Editar Farmacia'
                                  : 'Nueva Farmacia',
                              style: const TextStyle(
                                fontSize: MedRushTheme.fontSizeTitleLarge,
                                fontWeight: MedRushTheme.fontWeightBold,
                                color: MedRushTheme.textPrimary,
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

                          // 12. Sección de coordenadas - Latitud y Longitud
                          const Text(
                            'Ubicación en el mapa',
                            style: TextStyle(
                              fontSize: MedRushTheme.fontSizeBodyLarge,
                              fontWeight: MedRushTheme.fontWeightMedium,
                              color: MedRushTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: MedRushTheme.spacingSm),

                          // Mapa interactivo (tap para seleccionar ubicación)
                          Stack(
                            children: [
                              MapaWidget(
                                pedidos: const [],
                                puntoSeleccionado:
                                    _buildLatLngFromControllers(),
                                height: 300, // Aumentar altura del mapa
                                onTapMapa: (pos) async {
                                  _latitudController.text =
                                      StatusHelpers.formatearNumero(
                                          pos.latitude,
                                          decimales: 6);
                                  _longitudController.text =
                                      StatusHelpers.formatearNumero(
                                          pos.longitude,
                                          decimales: 6);

                                  // Obtener información de dirección usando geocodificación
                                  try {
                                    final result =
                                        await GeocodingService.reverseGeocode(
                                            pos.latitude, pos.longitude);

                                    if (result != null) {
                                      // Reemplazar dirección línea 1 (siempre que haya datos)
                                      if (result.addressLine1.isNotEmpty) {
                                        _direccionLinea1Controller.text =
                                            result.addressLine1;
                                      }

                                      // Reemplazar ciudad (siempre que haya datos)
                                      if (result.city.isNotEmpty) {
                                        _distritoController.text = result.city;
                                      }

                                      // Reemplazar estado/región (siempre que haya datos)
                                      if (result.state.isNotEmpty) {
                                        _provinciaController.text =
                                            result.state;
                                      }

                                      // Reemplazar código postal (siempre que haya datos)
                                      if (result.postalCode.isNotEmpty) {
                                        _departamentoController.text =
                                            result.postalCode;
                                      }

                                      // Reemplazar dirección completa (siempre que haya datos)
                                      if (result.formattedAddress.isNotEmpty) {
                                        _direccionController.text =
                                            result.formattedAddress;
                                      }
                                    }
                                  } catch (e) {
                                    logError(
                                        'Error en geocodificación del mapa pequeño',
                                        e);
                                  }

                                  setState(() {});
                                },
                              ),
                              // Botón de pantalla completa
                              Positioned(
                                top: 8,
                                right: 8,
                                child: FloatingActionButton.small(
                                  heroTag: 'fab_mapa_farmacia_form',
                                  onPressed: _abrirMapaPantallaCompleta,
                                  backgroundColor: MedRushTheme.primaryGreen,
                                  foregroundColor: MedRushTheme.textInverse,
                                  child: const Icon(LucideIcons.maximize),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Campos de coordenadas
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _latitudController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Latitud *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(LucideIcons.mapPin),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese la latitud';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Por favor ingrese una latitud válida';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: MedRushTheme.spacingMd),
                              Expanded(
                                child: TextFormField(
                                  controller: _longitudController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Longitud *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(LucideIcons.mapPin),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese la longitud';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Por favor ingrese una longitud válida';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: MedRushTheme.spacingLg),

                          // Botones de acción
                          Row(
                            children: [
                              // Botón de guardar
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _handleSave,
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    MedRushTheme.textInverse),
                                          ),
                                        )
                                      : const Icon(LucideIcons.save),
                                  label: _isLoading
                                      ? const Text('Guardando...')
                                      : Text(widget.initialData != null
                                          ? 'Actualizar Farmacia'
                                          : 'Crear Farmacia'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: MedRushTheme.primaryGreen,
                                    foregroundColor: MedRushTheme.textInverse,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                ),
                              ),

                              // Botón de eliminar (solo si se está editando)
                              if (widget.initialData != null) ...[
                                const SizedBox(width: MedRushTheme.spacingMd),
                                OutlinedButton.icon(
                                  onPressed: _isLoading ? null : _handleDelete,
                                  icon: const Icon(LucideIcons.trash2),
                                  label: const Text('Eliminar'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red[600],
                                    side: BorderSide(color: Colors.red[600]!),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                ),
                              ],
                            ],
                          ),

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
    );
  }
}
