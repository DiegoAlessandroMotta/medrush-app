import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/l10n/app_localizations.dart';
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

      _fotoUrl = usuario.foto;
      _fotoLicenciaUrl = usuario.licenciaImagenUrl;
      _licenciaNumeroController.text =
          usuario.licenciaNumero ?? usuario.dniIdNumero ?? '';
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
        title: Text(AppLocalizations.of(context).changePasswordTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: newPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).newPassword,
                  prefixIcon: const Icon(LucideIcons.lock),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return AppLocalizations.of(context).requiredField;
                  }
                  if (v.length < 8) {
                    return AppLocalizations.of(context).passwordMinLength;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).confirmNewPassword,
                  prefixIcon: const Icon(LucideIcons.lock),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return AppLocalizations.of(context).requiredField;
                  }
                  if (v != newPassController.text) {
                    return AppLocalizations.of(context)
                        .passwordsDoNotMatchShort;
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
            child: Text(AppLocalizations.of(context).cancel),
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
                  NotificationService.showSuccess(
                      AppLocalizations.of(context).passwordUpdated,
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
                      AppLocalizations.of(context).couldNotUpdatePassword,
                      context: context);
                }
              } catch (e) {
                if (!context.mounted) {
                  return;
                }
                NotificationService.showError(
                    AppLocalizations.of(context).errorSavingDriver(e),
                    context: context);
              }
            },
            child: Text(AppLocalizations.of(context).save),
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
      // Guardar l10n antes del async para evitar problemas con BuildContext
      final l10n = AppLocalizations.of(context);

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
                ? l10n.driverUpdatedSuccess
                : l10n.driverCreatedSuccess,
            context: context,
          );
        }
      } else {
        throw Exception(result.error ?? l10n.errorSavingDriverUnknown);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
            AppLocalizations.of(context).errorSavingDriver(e),
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

  Future<void> _selectDate() async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _licenciaVencimiento ??
            DateTime.now().add(const Duration(days: 365)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
        helpText: AppLocalizations.of(context).selectExpiryDate,
        cancelText: AppLocalizations.of(context).cancel,
        confirmText: AppLocalizations.of(context).confirm,
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
        NotificationService.showError(
            AppLocalizations.of(context).errorSelectingDate(e),
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
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).phoneNumberLabel,
        hintText: '5551234567',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(LucideIcons.phone),
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
          return AppLocalizations.of(context).phoneMustBe10Digits;
        }

        return null;
      },
      onChanged: (value) {
        // Validación en tiempo real
        setState(() {});
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
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
                                      ? AppLocalizations.of(context).editDriver
                                      : AppLocalizations.of(context).newDriver,
                                  style: const TextStyle(
                                    fontSize: MedRushTheme.fontSizeTitleLarge,
                                    fontWeight: MedRushTheme.fontWeightBold,
                                    color: MedRushTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.initialData != null
                                      ? AppLocalizations.of(context)
                                          .modifyingDriver
                                      : AppLocalizations.of(context)
                                          .creatingDriver,
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
                                  child: BaseApi.imageUrlForDisplay(_fotoUrl) !=
                                          null
                                      ? Image.network(
                                          BaseApi.imageUrlForDisplay(_fotoUrl)!,
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
                          _buildSectionTitle(
                              AppLocalizations.of(context).sectionPersonalInfo),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Nombre
                          TextFormField(
                            controller: _nombreController,
                            decoration: InputDecoration(
                              labelText:
                                  AppLocalizations.of(context).fullNameRequired,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(LucideIcons.user),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppLocalizations.of(context)
                                    .nameRequired;
                              }
                              return null;
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText:
                                  '${AppLocalizations.of(context).email} *',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(LucideIcons.mail),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppLocalizations.of(context)
                                    .emailRequired;
                              }
                              if (!Validators.isValidEmailStrict(value)) {
                                return AppLocalizations.of(context)
                                    .invalidEmail;
                              }
                              return null;
                            },
                            onChanged: (value) {
                              // Validación en tiempo real
                              setState(() {});
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // País (solo visual; por defecto USA)
                          TextFormField(
                            controller: _paisController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).country,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(LucideIcons.flag),
                              helperText: AppLocalizations.of(context)
                                  .countryDefaultUSA,
                            ),
                          ),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Password (solo para nuevos usuarios)
                          if (widget.initialData == null)
                            Column(
                              children: [
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText:
                                        '${AppLocalizations.of(context).passwordLabel} *',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(LucideIcons.lock),
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (widget.initialData == null &&
                                        (value == null ||
                                            value.trim().isEmpty)) {
                                      return AppLocalizations.of(context)
                                          .passwordRequired;
                                    }
                                    if (value != null &&
                                        value.isNotEmpty &&
                                        value.length < 6) {
                                      return AppLocalizations.of(context)
                                          .passwordMin6Chars;
                                    }
                                    return null;
                                  },
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                ),
                                const SizedBox(height: MedRushTheme.spacingMd),
                              ],
                            ),

                          // Teléfono con código de país
                          _buildTelefonoField(),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Licencia / ID (opcional; un solo campo)
                          TextFormField(
                            controller: _licenciaNumeroController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                  .licenseOrIdNumberOptionalLabel,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(LucideIcons.idCard),
                              helperText: AppLocalizations.of(context)
                                  .licenseFormatHelper,
                            ),
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(20),
                              FilteringTextInputFormatter.allow(
                                  Validators.getAlphanumericInputPattern()),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return null;
                              }
                              if (value.length < 5) {
                                return AppLocalizations.of(context).idMin5Chars;
                              }
                              if (!Validators.isAlphanumericOnly(value)) {
                                return AppLocalizations.of(context)
                                    .alphanumericOnly;
                              }
                              return null;
                            },
                            onChanged: (value) => setState(() {}),
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Fecha de vencimiento de licencia
                          InkWell(
                            onTap: _selectDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)
                                    .licenseExpiryLabel,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(LucideIcons.calendar),
                              ),
                              child: Text(
                                _licenciaVencimiento != null
                                    ? '${_licenciaVencimiento!.day}/${_licenciaVencimiento!.month}/${_licenciaVencimiento!.year}'
                                    : AppLocalizations.of(context).selectDate,
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
                          _buildSectionTitle(
                              AppLocalizations.of(context).sectionVehicleInfo),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Placa
                          TextFormField(
                            controller: _vehiculoPlacaController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                  .vehiclePlateLabel,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(LucideIcons.mapPin),
                              helperText: AppLocalizations.of(context)
                                  .vehiclePlateFormat,
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (value.length < 4) {
                                  return AppLocalizations.of(context)
                                      .plateMin4Chars;
                                }
                                if (!Validators.isUppercaseNumbersAndDashesOnly(
                                    value)) {
                                  return AppLocalizations.of(context)
                                      .uppercaseNumbersDashes;
                                }
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {});
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Marca
                          TextFormField(
                            controller: _vehiculoMarcaController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                  .vehicleBrandLabel,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(LucideIcons.car),
                              helperText: AppLocalizations.of(context)
                                  .vehicleBrandHelper,
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (value.length < 2) {
                                  return AppLocalizations.of(context)
                                      .brandMin2Chars;
                                }
                                if (!Validators.isLettersAndSpacesOnly(value)) {
                                  return AppLocalizations.of(context)
                                      .lettersAndSpacesOnly;
                                }
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {});
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Modelo
                          TextFormField(
                            controller: _vehiculoModeloController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                  .vehicleModelLabel,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(LucideIcons.car),
                              helperText: AppLocalizations.of(context)
                                  .vehicleModelHelper,
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (value.length < 2) {
                                  return AppLocalizations.of(context)
                                      .modelMin2Chars;
                                }
                                if (!Validators.isAlphanumericAndSpacesOnly(
                                    value)) {
                                  return AppLocalizations.of(context)
                                      .alphanumericSpacesDashes;
                                }
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {});
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),
                          const SizedBox(height: MedRushTheme.spacingLg),

                          // Código registro del vehículo
                          TextFormField(
                            controller: _vehiculoCodigoRegistroController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                  .vehicleRegistrationLabel,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(LucideIcons.badge),
                              helperText: AppLocalizations.of(context)
                                  .vehicleRegistrationHelper,
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
                                  return AppLocalizations.of(context)
                                      .min5Characters;
                                }
                                if (!Validators.isAlphanumericOnly(value)) {
                                  return AppLocalizations.of(context)
                                      .alphanumericOnly;
                                }
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {});
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),
                          const SizedBox(height: MedRushTheme.spacingLg),

                          // Documentos y Fotos
                          _buildSectionTitle(
                              AppLocalizations.of(context).sectionDocuments),
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
                                // Foto de Licencia
                                _buildDocumentPhoto(
                                  title: AppLocalizations.of(context)
                                      .photoLicenseTitle,
                                  subtitle: AppLocalizations.of(context)
                                      .photoLicenseSubtitle,
                                  icon: LucideIcons.idCard,
                                  imageUrl: BaseApi.imageUrlForDisplay(
                                          _fotoLicenciaUrl) ??
                                      _fotoLicenciaUrl,
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
                                  title: AppLocalizations.of(context)
                                      .photoInsuranceTitle,
                                  subtitle: AppLocalizations.of(context)
                                      .photoInsuranceSubtitle,
                                  icon: LucideIcons.shield,
                                  imageUrl: BaseApi.imageUrlForDisplay(
                                          _fotoSeguroVehiculoUrl) ??
                                      _fotoSeguroVehiculoUrl,
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
                          _buildSectionTitle(
                              AppLocalizations.of(context).sectionSettings),
                          const SizedBox(height: MedRushTheme.spacingMd),

                          // Estado del repartidor (opcional al crear; por defecto Disponible)
                          DropdownButtonFormField<EstadoRepartidor>(
                            initialValue: _estadoSeleccionado,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                  .driverStatusLabel,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.assignment),
                            ),
                            items: EstadoRepartidor.values.map((estado) {
                              return DropdownMenuItem<EstadoRepartidor>(
                                value: estado,
                                child: Builder(
                                  builder: (context) => Text(
                                      StatusHelpers.estadoRepartidorTexto(
                                          estado,
                                          AppLocalizations.of(context))),
                                ),
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
                            title:
                                Text(AppLocalizations.of(context).activeUser),
                            subtitle: Text(_activo
                                ? AppLocalizations.of(context)
                                    .userCanAccessSystem
                                : AppLocalizations.of(context).userDisabled),
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
                                      AppLocalizations.of(context)
                                          .couldNotUpdateActiveStatus,
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
                                NotificationService.showError(
                                    AppLocalizations.of(context)
                                        .errorUpdatingActiveStatus(e),
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
                                label: Text(AppLocalizations.of(context)
                                    .changePasswordTitle),
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
                                ? AppLocalizations.of(context).saving
                                : (widget.initialData != null
                                    ? AppLocalizations.of(context).updateLabel
                                    : AppLocalizations.of(context)
                                        .createDriver)),
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
        Text(
          AppLocalizations.of(context).tapToSelect,
          style: const TextStyle(
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
        NotificationService.showError(
            AppLocalizations.of(context).errorUploadingImage(e),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person,
            size: 48,
            color: MedRushTheme.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).driverPhotoPlaceholder,
            style: const TextStyle(
              fontSize: 14,
              color: MedRushTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).tapToSelect,
            style: const TextStyle(
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
      // Usar mayor resolución y calidad para documentos que tienen texto
      final XFile? imageFile = await BaseApi.pickImage(
        maxWidth: 2500,
        maxHeight: 2500,
        imageQuality: 95,
      );

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
        NotificationService.showError(
            AppLocalizations.of(context).errorUploadingImage(e),
            context: context);
      }
    }
  }
}
