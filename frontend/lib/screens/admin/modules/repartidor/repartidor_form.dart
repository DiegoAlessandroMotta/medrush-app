import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/models/usuario.model.dart';
import 'package:medrush/repositories/base.repository.dart';
import 'package:medrush/repositories/repartidor.repository.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:medrush/utils/validators.dart';

// Ancho máximo del bottom sheet en desktop para mejorar legibilidad
const double _kMaxDesktopSheetWidth = 980;

class RepartidorForm extends StatefulWidget {
  final void Function(Usuario usuario) onSave;
  final Usuario? initialData;
  final VoidCallback?
      onImageUpdated; // Callback para notificar actualización de imagen

  const RepartidorForm({
    super.key,
    required this.onSave,
    this.initialData,
    this.onImageUpdated,
  });

  @override
  State<RepartidorForm> createState() => _RepartidorFormState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<void Function(Usuario usuario)>.has(
          'onSave', onSave))
      ..add(DiagnosticsProperty<Usuario?>('initialData', initialData))
      ..add(ObjectFlagProperty<VoidCallback?>.has(
          'onImageUpdated', onImageUpdated));
  }
}

class _RepartidorFormState extends State<RepartidorForm> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _dniIdNumeroController = TextEditingController();
  final TextEditingController _licenciaNumeroController =
      TextEditingController();
  final TextEditingController _vehiculoPlacaController =
      TextEditingController();
  final TextEditingController _vehiculoMarcaController =
      TextEditingController();
  final TextEditingController _vehiculoModeloController =
      TextEditingController();
  final TextEditingController _vehiculoCodigoRegistroController =
      TextEditingController();
  final TextEditingController _paisController =
      TextEditingController(text: 'USA');

  // Estados
  bool _isLoading = false;
  EstadoRepartidor _estadoSeleccionado = EstadoRepartidor.disponible;
  DateTime? _licenciaVencimiento;
  bool _activo = true;
  String? _fotoUrl;
  String? _fotoDniUrl;
  String? _fotoLicenciaUrl;
  String? _fotoSeguroVehiculoUrl;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.initialData != null) {
      final usuario = widget.initialData!;
      _nombreController.text = usuario.nombre;
      _emailController.text = usuario.email;

      // Extraer número del teléfono existente (remover +1 si está presente)
      final telefonoCompleto = usuario.telefono ?? '';
      if (telefonoCompleto.isNotEmpty) {
        if (telefonoCompleto.startsWith('+1')) {
          _telefonoController.text = telefonoCompleto.substring(2);
        } else {
          _telefonoController.text = telefonoCompleto;
        }
      }

      _dniIdNumeroController.text = usuario.dniIdNumero ?? '';
      _fotoUrl = usuario.foto;
      _fotoDniUrl = usuario.dniIdImagenUrl;
      _fotoLicenciaUrl = usuario.licenciaImagenUrl;
      _licenciaNumeroController.text = usuario.licenciaNumero ?? '';
      _vehiculoPlacaController.text = usuario.vehiculoPlaca ?? '';
      _vehiculoMarcaController.text = usuario.vehiculoMarca ?? '';
      _vehiculoModeloController.text = usuario.vehiculoModelo ?? '';
      _vehiculoCodigoRegistroController.text =
          usuario.vehiculoCodigoRegistro ?? '';
      _licenciaVencimiento = usuario.licenciaVencimiento;
      _estadoSeleccionado =
          usuario.estadoRepartidor ?? EstadoRepartidor.disponible;
      _activo = usuario.activo;
    }
  }

  Future<void> _onImageChanged(String? imageUrl) async {
    // Actualizar inmediatamente con la URL del upload
    setState(() {
      _fotoUrl = imageUrl;
    });
    // Hacer GET por ID para obtener las URLs oficiales actualizadas
    if (widget.initialData?.id != null) {
      await _refreshRepartidorData();
    }

    // Notificar al padre que se actualizó una imagen
    widget.onImageUpdated?.call();
  }

  Future<void> _onDniImageChanged(String? imageUrl) async {
    // Actualizar inmediatamente con la URL del upload
    setState(() {
      _fotoDniUrl = imageUrl;
    });

    // Hacer GET por ID para obtener las URLs oficiales actualizadas
    if (widget.initialData?.id != null) {
      await _refreshRepartidorData();
    }

    // Notificar al padre que se actualizó una imagen
    widget.onImageUpdated?.call();
  }

  Future<void> _onLicenciaImageChanged(String? imageUrl) async {
    // Actualizar inmediatamente con la URL del upload
    setState(() {
      _fotoLicenciaUrl = imageUrl;
    });

    // Hacer GET por ID para obtener las URLs oficiales actualizadas
    if (widget.initialData?.id != null) {
      await _refreshRepartidorData();
    }

    // Notificar al padre que se actualizó una imagen
    widget.onImageUpdated?.call();
  }

  /// Refresca los datos del repartidor desde el backend
  Future<void> _refreshRepartidorData() async {
    if (widget.initialData?.id == null) {
      return;
    }

    try {
      final repository = RepartidorRepository();
      final result = await repository.getRepartidorById(widget.initialData!.id);

      if (result.success && result.data != null) {
        final usuario = result.data!;

        setState(() {
          _fotoUrl = usuario.foto;
          _fotoDniUrl = usuario.dniIdImagenUrl;
          _fotoLicenciaUrl = usuario.licenciaImagenUrl;
          _fotoSeguroVehiculoUrl =
              usuario.fotoSeguroVehiculo ?? usuario.seguroVehiculoUrl;
        });
      } else {
        // No-op
      }
    } catch (e) {
      // No-op
    }
  }

  Future<void> _onSeguroVehiculoImageChanged(String? imageUrl) async {
    setState(() {
      _fotoSeguroVehiculoUrl = imageUrl;
    });

    if (widget.initialData?.id != null) {
      await _refreshRepartidorData();
    }

    widget.onImageUpdated?.call();
  }

  Future<void> _showChangePasswordDialog() async {
    if (widget.initialData?.id == null) {
      return;
    }

    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: newPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nueva contraseña',
                  prefixIcon: Icon(LucideIcons.lock),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Requerido';
                  }
                  if (v.length < 8) {
                    return 'Mínimo 8 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: Icon(LucideIcons.lock),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Requerido';
                  }
                  if (v != newPassController.text) {
                    return 'No coinciden';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) {
                return;
              }
              try {
                final repo = RepartidorRepository();
                final result = await repo.cambiarPassword(
                  repartidorId: widget.initialData!.id,
                  nuevaPassword: newPassController.text,
                  confirmacionPassword: confirmController.text,
                );

                if (!mounted) {
                  return;
                }
                final ok = result.success;

                if (ok == true) {
                  if (!context.mounted) {
                    return;
                  }
                  NotificationService.showSuccess('Contraseña actualizada',
                      context: context);
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pop(true);
                } else {
                  if (!context.mounted) {
                    return;
                  }
                  NotificationService.showError(
                      'No se pudo actualizar la contraseña',
                      context: context);
                }
              } catch (e) {
                if (!context.mounted) {
                  return;
                }
                NotificationService.showError('Error: $e', context: context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true) {
      // No-op; ya notificamos
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Lógica de password:
      // - Si es nuevo usuario: usar password del campo o un default
      // - Si es actualización: solo enviar password si el usuario lo cambió (campo no vacío)
      String? passwordFinal;
      if (widget.initialData == null) {
        // Nuevo usuario: password es requerido
        passwordFinal = _passwordController.text.isNotEmpty
            ? _passwordController.text
            : 'defaultPassword123';
      } else {
        // Actualización: solo enviar si el usuario ingresó una nueva contraseña
        passwordFinal = _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null; // null = no enviar password (no cambiar)
      }

      final usuario = Usuario(
        id: widget.initialData?.id ??
            '', // Para nuevos usuarios, se generará UUID en el backend
        nombre: _nombreController.text.trim(),
        email: _emailController.text.trim(),
        password: passwordFinal,
        tipoUsuario: TipoUsuario.repartidor,
        telefono: _telefonoController.text.trim().isEmpty
            ? null
            : Validators.formatPhoneToE164(_telefonoController.text.trim()),
        foto: _fotoUrl,
        dniIdNumero: _dniIdNumeroController.text.trim().isEmpty
            ? null
            : _dniIdNumeroController.text.trim(),
        licenciaNumero: _licenciaNumeroController.text.trim().isEmpty
            ? null
            : _licenciaNumeroController.text.trim(),
        licenciaVencimiento: _licenciaVencimiento,
        vehiculoPlaca: _vehiculoPlacaController.text.trim().isEmpty
            ? null
            : _vehiculoPlacaController.text.trim(),
        vehiculoMarca: _vehiculoMarcaController.text.trim().isEmpty
            ? null
            : _vehiculoMarcaController.text.trim(),
        vehiculoModelo: _vehiculoModeloController.text.trim().isEmpty
            ? null
            : _vehiculoModeloController.text.trim(),
        vehiculoCodigoRegistro:
            _vehiculoCodigoRegistroController.text.trim().isEmpty
                ? null
                : _vehiculoCodigoRegistroController.text.trim(),
        codigoIsoPais: (_paisController.text.trim().isEmpty)
            ? 'USA'
            : _paisController.text.trim(),
        estadoRepartidor: _estadoSeleccionado,
        createdAt: widget.initialData?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        activo: _activo,
      );

      // No logs

      // Conectar con el backend real
      final repository = RepartidorRepository();
      RepositoryResult<Usuario?> result;

      if (widget.initialData != null) {
        // Actualizar repartidor existente
        // Pasar email original para evitar error de validación unique si no cambió
        final emailOriginal = widget.initialData!.email;
        result = await repository.updateRepartidor(usuario,
            emailOriginal: emailOriginal);
      } else {
        // Crear nuevo repartidor
        result = await repository.createRepartidor(usuario);
      }

      if (result.success && result.data != null) {
        final repartidorGuardado = result.data!;
        widget.onSave(repartidorGuardado);

        if (mounted) {
          NotificationService.showSuccess(
            widget.initialData != null
                ? 'Repartidor actualizado exitosamente'
                : 'Repartidor creado exitosamente',
            context: context,
          );
        }
      } else {
        throw Exception(
            result.error ?? 'Error desconocido al guardar repartidor');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError('Error al guardar: $e', context: context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _licenciaVencimiento ??
            DateTime.now().add(const Duration(days: 365)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
        helpText: 'Seleccionar fecha de vencimiento',
        cancelText: 'Cancelar',
        confirmText: 'Confirmar',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: MedRushTheme.primaryGreen,
                  ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null && picked != _licenciaVencimiento) {
        setState(() {
          _licenciaVencimiento = picked;
        });
        // No log
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError('Error al seleccionar fecha: $e',
            context: context);
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _telefonoController.dispose();
    _dniIdNumeroController.dispose();
    _licenciaNumeroController.dispose();
    _vehiculoPlacaController.dispose();
    _vehiculoMarcaController.dispose();
    _vehiculoModeloController.dispose();
    _vehiculoCodigoRegistroController.dispose();
    _paisController.dispose();
    super.dispose();
  }

  // Widget personalizado para el campo de teléfono
  Widget _buildTelefonoField() {
    return TextFormField(
      controller: _telefonoController,
      decoration: const InputDecoration(
        labelText: 'Número de Teléfono',
        hintText: '5551234567',
        border: OutlineInputBorder(),
        prefixIcon: Icon(LucideIcons.phone),
        prefixText: '+1 ',
        helperText: '10 dígitos',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return null;
        }

        // Remover espacios y caracteres especiales excepto números
        final soloNumeros = Validators.removeNonDigits(value);

        if (soloNumeros.length != 10) {
          return 'El teléfono debe tener exactamente 10 dígitos';
        }

        return null;
      },
      onChanged: (value) {
        // Validación en tiempo real
        setState(() {});
      },
    );
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
                                      ? 'Editar Repartidor'
                                      : 'Nuevo Repartidor',
                                  style: const TextStyle(
                                    fontSize: MedRushTheme.fontSizeTitleLarge,
                                    fontWeight: MedRushTheme.fontWeightBold,
                                    color: MedRushTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.initialData != null
                                      ? 'Modificando repartidor'
                                      : 'Creando nuevo repartidor',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Foto del repartidor
                          Center(
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(75),
                                border: Border.all(
                                  color: MedRushTheme.primaryGreen
                                      .withValues(alpha: 0.3),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: MedRushTheme.primaryGreen
                                        .withValues(alpha: 0.1),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(72),
                                child: GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: _fotoUrl != null
                                      ? Image.network(
                                          _fotoUrl!,
                                          width: 150,
                                          height: 150,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return _buildProfilePlaceholder();
                                          },
                                        )
                                      : _buildProfilePlaceholder(),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: MedRushTheme.spacingLg),

                          // Información Personal
                          _buildSectionTitle('Información Personal'),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Nombre
                          TextFormField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre Completo *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(LucideIcons.user),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El nombre es requerido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(LucideIcons.mail),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El email es requerido';
                              }
                              if (!Validators.isValidEmailStrict(value)) {
                                return 'Email inválido';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              // Validación en tiempo real
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // País (solo visual; por defecto USA)
                          TextFormField(
                            controller: _paisController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'País',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(LucideIcons.flag),
                              helperText: 'Se enviará como USA por defecto',
                            ),
                          ),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Password (solo para nuevos usuarios)
                          if (widget.initialData == null)
                            Column(
                              children: [
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: const InputDecoration(
                                    labelText: 'Contraseña *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(LucideIcons.lock),
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (widget.initialData == null &&
                                        (value == null ||
                                            value.trim().isEmpty)) {
                                      return 'La contraseña es requerida';
                                    }
                                    if (value != null &&
                                        value.isNotEmpty &&
                                        value.length < 6) {
                                      return 'La contraseña debe tener al menos 6 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: MedRushTheme.spacingMd),
                              ],
                            ),

                          // Teléfono con código de país
                          _buildTelefonoField(),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // ID
                          TextFormField(
                            controller: _dniIdNumeroController,
                            decoration: const InputDecoration(
                              labelText: 'ID (Driver’s License o State ID)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(LucideIcons.idCard),
                              helperText:
                                  'Letras y números; sin espacios ni guiones',
                            ),
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(20),
                              FilteringTextInputFormatter.allow(
                                  Validators.getAlphanumericInputPattern()),
                            ],
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (value.length < 5) {
                                  return 'El ID debe tener al menos 5 caracteres';
                                }
                                if (!Validators.isAlphanumericOnly(value)) {
                                  return 'Solo letras y números';
                                }
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: MedRushTheme.spacingLg),

                          // Información de Licencia
                          _buildSectionTitle('Información de Licencia'),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Número de licencia
                          TextFormField(
                            controller: _licenciaNumeroController,
                            decoration: const InputDecoration(
                              labelText: 'Número de Licencia',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(LucideIcons.idCard),
                              helperText: 'Formato: Letras y números',
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (value.length < 5) {
                                  return 'El número de licencia debe tener al menos 5 caracteres';
                                }
                                if (!Validators.isUppercaseAndNumbersOnly(
                                    value)) {
                                  return 'Solo letras mayúsculas y números';
                                }
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Fecha de vencimiento de licencia
                          InkWell(
                            onTap: _selectDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Vencimiento de Licencia',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(LucideIcons.calendar),
                              ),
                              child: Text(
                                _licenciaVencimiento != null
                                    ? '${_licenciaVencimiento!.day}/${_licenciaVencimiento!.month}/${_licenciaVencimiento!.year}'
                                    : 'Seleccionar fecha',
                                style: TextStyle(
                                  color: _licenciaVencimiento != null
                                      ? MedRushTheme.textPrimary
                                      : MedRushTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: MedRushTheme.spacingLg),

                          // Información del Vehículo
                          _buildSectionTitle('Información del Vehículo'),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Placa
                          TextFormField(
                            controller: _vehiculoPlacaController,
                            decoration: const InputDecoration(
                              labelText: 'Placa del Vehículo',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(LucideIcons.mapPin),
                              helperText: 'Formato: ABC-123 o ABC123',
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (value.length < 4) {
                                  return 'La placa debe tener al menos 4 caracteres';
                                }
                                if (!Validators.isUppercaseNumbersAndDashesOnly(
                                    value)) {
                                  return 'Solo letras mayúsculas, números y guiones';
                                }
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Marca
                          TextFormField(
                            controller: _vehiculoMarcaController,
                            decoration: const InputDecoration(
                              labelText: 'Marca del Vehículo',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(LucideIcons.car),
                              helperText: 'Ej: Toyota, Honda, Ford',
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (value.length < 2) {
                                  return 'La marca debe tener al menos 2 caracteres';
                                }
                                if (!Validators.isLettersAndSpacesOnly(value)) {
                                  return 'Solo letras y espacios';
                                }
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Modelo
                          TextFormField(
                            controller: _vehiculoModeloController,
                            decoration: const InputDecoration(
                              labelText: 'Modelo del Vehículo',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(LucideIcons.car),
                              helperText: 'Ej: Corolla, Civic, Focus',
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (value.length < 2) {
                                  return 'El modelo debe tener al menos 2 caracteres';
                                }
                                if (!Validators.isAlphanumericAndSpacesOnly(
                                    value)) {
                                  return 'Solo letras, números, espacios y guiones';
                                }
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: MedRushTheme.spacingLg),

                          // Código registro del vehículo
                          TextFormField(
                            controller: _vehiculoCodigoRegistroController,
                            decoration: const InputDecoration(
                              labelText: 'Código de Registro del Vehículo',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(LucideIcons.badge),
                              helperText: 'Alfanumérico; ej: ABC123456',
                            ),
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(20),
                              FilteringTextInputFormatter.allow(
                                  Validators.getAlphanumericInputPattern()),
                            ],
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (value.length < 5) {
                                  return 'Debe tener al menos 5 caracteres';
                                }
                                if (!Validators.isAlphanumericOnly(value)) {
                                  return 'Solo letras y números';
                                }
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: MedRushTheme.spacingLg),

                          // Documentos y Fotos
                          _buildSectionTitle('Documentos y Fotos'),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Contenedor para las fotos de documentos
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: MedRushTheme.backgroundSecondary,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: MedRushTheme.textSecondary
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Foto de ID
                                _buildDocumentPhoto(
                                  title: 'Foto de ID',
                                  subtitle: 'Documento de identidad',
                                  icon: LucideIcons.idCard,
                                  imageUrl: _fotoDniUrl,
                                  onImageChanged: _onDniImageChanged,
                                  uploadEndpoint:
                                      '/user/repartidores/${widget.initialData?.id ?? 'temp'}/dni-id',
                                  key: 'dni_${_fotoDniUrl ?? 'empty'}',
                                ),

                                const SizedBox(height: MedRushTheme.spacingLg),

                                // Divider
                                Container(
                                  height: 1,
                                  color: MedRushTheme.textSecondary
                                      .withValues(alpha: 0.2),
                                ),

                                const SizedBox(height: MedRushTheme.spacingLg),

                                // Foto de Licencia
                                _buildDocumentPhoto(
                                  title: 'Foto de Licencia de Conducir',
                                  subtitle: 'Licencia de conducir vigente',
                                  icon: LucideIcons.idCard,
                                  imageUrl: _fotoLicenciaUrl,
                                  onImageChanged: _onLicenciaImageChanged,
                                  uploadEndpoint:
                                      '/user/repartidores/${widget.initialData?.id ?? 'temp'}/licencia',
                                  key:
                                      'licencia_${_fotoLicenciaUrl ?? 'empty'}',
                                ),

                                const SizedBox(height: MedRushTheme.spacingLg),

                                // Divider
                                Container(
                                  height: 1,
                                  color: MedRushTheme.textSecondary
                                      .withValues(alpha: 0.2),
                                ),

                                const SizedBox(height: MedRushTheme.spacingLg),

                                // Foto de Seguro Vehicular
                                _buildDocumentPhoto(
                                  title: 'Foto de Seguro del Vehículo',
                                  subtitle: 'Póliza vigente',
                                  icon: LucideIcons.shield,
                                  imageUrl: _fotoSeguroVehiculoUrl,
                                  onImageChanged: _onSeguroVehiculoImageChanged,
                                  uploadEndpoint:
                                      '/user/repartidores/${widget.initialData?.id ?? 'temp'}/seguro-vehiculo',
                                  key:
                                      'seguro_${_fotoSeguroVehiculoUrl ?? 'empty'}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: MedRushTheme.spacingLg),

                          // Configuración
                          _buildSectionTitle('Configuración'),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Estado del repartidor
                          DropdownButtonFormField<EstadoRepartidor>(
                            initialValue: _estadoSeleccionado,
                            decoration: const InputDecoration(
                              labelText: 'Estado *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.assignment),
                            ),
                            items: EstadoRepartidor.values.map((estado) {
                              return DropdownMenuItem<EstadoRepartidor>(
                                value: estado,
                                child: Text(StatusHelpers.estadoRepartidorTexto(
                                    estado)),
                              );
                            }).toList(),
                            onChanged: (EstadoRepartidor? value) {
                              if (value != null) {
                                setState(() {
                                  _estadoSeleccionado = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Switch de activo
                          SwitchListTile(
                            title: const Text('Usuario Activo'),
                            subtitle: Text(_activo
                                ? 'El usuario puede acceder al sistema'
                                : 'Usuario deshabilitado'),
                            value: _activo,
                            onChanged: (bool value) async {
                              if (widget.initialData == null) {
                                setState(() => _activo = value);
                                return;
                              }
                              final prev = _activo;
                              setState(() => _activo = value);
                              try {
                                final repo = RepartidorRepository();
                                final res = await repo.setUsuarioActivo(
                                  userId: widget.initialData!.id,
                                  isActive: value,
                                );

                                if (!mounted) {
                                  return;
                                }
                                if (res.success != true) {
                                  if (!mounted) {
                                    return;
                                  }
                                  setState(() => _activo = prev);
                                  if (!context.mounted) {
                                    return;
                                  }
                                  NotificationService.showError(
                                      'No se pudo actualizar estado activo',
                                      context: context);
                                }
                              } catch (e) {
                                if (!mounted) {
                                  return;
                                }
                                setState(() => _activo = prev);
                                if (!context.mounted) {
                                  return;
                                }
                                NotificationService.showError('Error: $e',
                                    context: context);
                              }
                            },
                            activeThumbColor: MedRushTheme.primaryGreen,
                          ),
                          if (widget.initialData != null) ...[
                            const SizedBox(height: MedRushTheme.spacingSm),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _showChangePasswordDialog,
                                icon: const Icon(LucideIcons.lock),
                                label: const Text('Cambiar contraseña'),
                              ),
                            ),
                          ],
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
                                ? 'Guardando...'
                                : (widget.initialData != null
                                    ? 'Actualizar'
                                    : 'Crear Repartidor')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MedRushTheme.primaryGreen,
                              foregroundColor: MedRushTheme.textInverse,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),

                          // Espacio extra al final para evitar que el contenido se corte
                          const SizedBox(height: MedRushTheme.spacingXl),
                        ],
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: MedRushTheme.fontSizeBodyLarge,
        fontWeight: MedRushTheme.fontWeightMedium,
        color: MedRushTheme.primaryGreen,
      ),
    );
  }

  /// Construye una sección de foto de documento con diseño mejorado
  Widget _buildDocumentPhoto({
    required String title,
    required String subtitle,
    required IconData icon,
    required String? imageUrl,
    required Function(String?) onImageChanged,
    required String uploadEndpoint,
    required String key,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con título e icono
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MedRushTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: MedRushTheme.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: MedRushTheme.fontSizeBodyMedium,
                      fontWeight: MedRushTheme.fontWeightMedium,
                      color: MedRushTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: MedRushTheme.fontSizeBodySmall,
                      color: MedRushTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: MedRushTheme.spacingMd),

        // Contenedor de la foto
        Center(
          child: Container(
            width: 280,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: MedRushTheme.textSecondary.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildDocumentImagePicker(
              key: key,
              imageUrl: imageUrl,
              onImageChanged: onImageChanged,
              uploadEndpoint: uploadEndpoint,
              placeholderText: title,
            ),
          ),
        ),
      ],
    );
  }

  /// Construye un picker de imagen rectangular para documentos
  Widget _buildDocumentImagePicker({
    required String key,
    required String? imageUrl,
    required Function(String?) onImageChanged,
    required String uploadEndpoint,
    required String placeholderText,
  }) {
    return GestureDetector(
      onTap: () => _pickDocumentImage(uploadEndpoint, onImageChanged),
      child: Container(
        width: 280,
        height: 180,
        decoration: BoxDecoration(
          color: MedRushTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MedRushTheme.textSecondary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  width: 280,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDocumentPlaceholder(placeholderText);
                  },
                ),
              )
            : _buildDocumentPlaceholder(placeholderText),
      ),
    );
  }

  /// Construye el placeholder para documentos
  Widget _buildDocumentPlaceholder(String placeholderText) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_photo_alternate,
          size: 48,
          color: MedRushTheme.textSecondary,
        ),
        const SizedBox(height: 8),
        Text(
          placeholderText,
          style: const TextStyle(
            fontSize: 14,
            color: MedRushTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'Toca para seleccionar',
          style: TextStyle(
            fontSize: 12,
            color: MedRushTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Selecciona y sube una imagen de perfil
  Future<void> _pickProfileImage() async {
    try {
      final XFile? imageFile = await BaseApi.pickImage();

      if (imageFile != null && widget.initialData?.id != null) {
        final String? uploadedUrl = await BaseApi.uploadImage(
          imageFile: imageFile,
          userId: widget.initialData!.id,
          endpoint: '/user/${widget.initialData!.id}/foto',
        );

        if (uploadedUrl != null) {
          _onImageChanged(uploadedUrl);
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError('Error al subir imagen: $e',
            context: context);
      }
    }
  }

  /// Construye el placeholder para la foto de perfil
  Widget _buildProfilePlaceholder() {
    return Container(
      width: 150,
      height: 150,
      color: MedRushTheme.backgroundSecondary,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 48,
            color: MedRushTheme.textSecondary,
          ),
          SizedBox(height: 8),
          Text(
            'Foto del repartidor',
            style: TextStyle(
              fontSize: 14,
              color: MedRushTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'Toca para seleccionar',
            style: TextStyle(
              fontSize: 12,
              color: MedRushTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Selecciona y sube una imagen de documento
  Future<void> _pickDocumentImage(
      String uploadEndpoint, Function(String?) onImageChanged) async {
    try {
      final XFile? imageFile = await BaseApi.pickImage();

      if (imageFile != null && widget.initialData?.id != null) {
        // Construir endpoint correcto
        final String endpoint =
            uploadEndpoint.replaceAll('temp', widget.initialData!.id);

        final String? uploadedUrl = await BaseApi.uploadImage(
          imageFile: imageFile,
          userId: widget.initialData!.id,
          endpoint: endpoint,
        );

        if (uploadedUrl != null) {
          onImageChanged(uploadedUrl);
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError('Error al subir imagen: $e',
            context: context);
      }
    }
  }
}
