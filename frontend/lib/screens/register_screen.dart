import 'package:flutter/material.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:medrush/utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _licenseNumberController =
      TextEditingController();
  final TextEditingController _vehiclePlateController = TextEditingController();
  final TextEditingController _vehicleBrandController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _insuranceUrlController = TextEditingController();
  DateTime? _licenseExpiry;

  bool _isLoading = false;
  bool _obscurePwd = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _licenseNumberController.dispose();
    _vehiclePlateController.dispose();
    _vehicleBrandController.dispose();
    _vehicleModelController.dispose();
    _insuranceUrlController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Verificar email existente
      // TODO: Verificar email existente cuando el backend soporte endpoint /usuarios?email={email}
      // Por ahora, asumimos que el email está disponible
      logInfo(
          '👤 Verificación de email no implementada (endpoint no disponible)');

      // TODO: Implementar creación de usuario usando AuthApi.registerRepartidor cuando esté disponible
      // Por ahora, solo simulamos éxito
      logInfo('👤 Usuario creado exitosamente (simulado)');

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada exitosamente. Ahora inicia sesión.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
    return Scaffold(
      backgroundColor: MedRushTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: MedRushTheme.surface,
        elevation: 0,
        title: const Text(
          'Registro de Repartidor',
          style: TextStyle(
            color: MedRushTheme.textPrimary,
            fontWeight: MedRushTheme.fontWeightBold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MedRushTheme.spacingLg),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: MedRushTheme.surface,
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
            border: Border.all(color: MedRushTheme.borderLight),
            boxShadow: const [
              BoxShadow(
                color: MedRushTheme.shadowLight,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(MedRushTheme.spacingXl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Crear cuenta',
                    style: TextStyle(
                      fontSize: MedRushTheme.fontSizeHeadlineSmall,
                      fontWeight: MedRushTheme.fontWeightBold,
                      color: MedRushTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: MedRushTheme.spacingXl),

                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: const Icon(Icons.person,
                          color: MedRushTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(MedRushTheme.borderRadiusMd),
                      ),
                      filled: true,
                      fillColor: MedRushTheme.backgroundSecondary,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Ingresa tu nombre'
                        : null,
                  ),

                  const SizedBox(height: MedRushTheme.spacingMd),

                  // Número de licencia (requerido)
                  TextFormField(
                    controller: _licenseNumberController,
                    decoration: InputDecoration(
                      labelText: 'Número de licencia *',
                      prefixIcon: const Icon(Icons.badge_outlined,
                          color: MedRushTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(MedRushTheme.borderRadiusMd),
                      ),
                      filled: true,
                      fillColor: MedRushTheme.backgroundSecondary,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Ingresa tu número de licencia'
                        : null,
                  ),

                  const SizedBox(height: MedRushTheme.spacingMd),

                  // Vencimiento de licencia (requerido)
                  GestureDetector(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _licenseExpiry ??
                            DateTime(now.year + 1, now.month, now.day),
                        firstDate: DateTime(now.year, now.month, now.day),
                        lastDate: DateTime(now.year + 10),
                        helpText: 'Selecciona fecha de vencimiento',
                      );
                      if (picked != null) {
                        setState(() {
                          _licenseExpiry = picked;
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Vencimiento de licencia *',
                          hintText: _licenseExpiry == null
                              ? 'YYYY-MM-DD'
                              : StatusHelpers.formatearFechaAPI(
                                  _licenseExpiry!),
                          prefixIcon: const Icon(Icons.event,
                              color: MedRushTheme.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                MedRushTheme.borderRadiusMd),
                          ),
                          filled: true,
                          fillColor: MedRushTheme.backgroundSecondary,
                        ),
                        validator: (_) => _licenseExpiry == null
                            ? 'Selecciona la fecha de vencimiento'
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: MedRushTheme.spacingMd),

                  // Placa (requerido)
                  TextFormField(
                    controller: _vehiclePlateController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Placa del vehículo *',
                      prefixIcon: const Icon(Icons.confirmation_number_outlined,
                          color: MedRushTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(MedRushTheme.borderRadiusMd),
                      ),
                      filled: true,
                      fillColor: MedRushTheme.backgroundSecondary,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Ingresa la placa'
                        : null,
                  ),

                  const SizedBox(height: MedRushTheme.spacingMd),

                  // Marca (opcional)
                  TextFormField(
                    controller: _vehicleBrandController,
                    decoration: InputDecoration(
                      labelText: 'Marca del vehículo (opcional)',
                      prefixIcon: const Icon(
                          Icons.directions_car_filled_outlined,
                          color: MedRushTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(MedRushTheme.borderRadiusMd),
                      ),
                      filled: true,
                      fillColor: MedRushTheme.backgroundSecondary,
                    ),
                  ),

                  const SizedBox(height: MedRushTheme.spacingMd),

                  // Modelo (opcional)
                  TextFormField(
                    controller: _vehicleModelController,
                    decoration: InputDecoration(
                      labelText: 'Modelo del vehículo (opcional)',
                      prefixIcon: const Icon(Icons.time_to_leave,
                          color: MedRushTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(MedRushTheme.borderRadiusMd),
                      ),
                      filled: true,
                      fillColor: MedRushTheme.backgroundSecondary,
                    ),
                  ),

                  const SizedBox(height: MedRushTheme.spacingMd),

                  // Seguro (URL opcional)
                  TextFormField(
                    controller: _insuranceUrlController,
                    decoration: InputDecoration(
                      labelText: 'URL del seguro (opcional)',
                      prefixIcon: const Icon(Icons.link,
                          color: MedRushTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(MedRushTheme.borderRadiusMd),
                      ),
                      filled: true,
                      fillColor: MedRushTheme.backgroundSecondary,
                    ),
                  ),

                  const SizedBox(height: MedRushTheme.spacingMd),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(Icons.email_outlined,
                          color: MedRushTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(MedRushTheme.borderRadiusMd),
                      ),
                      filled: true,
                      fillColor: MedRushTheme.backgroundSecondary,
                    ),
                    validator: Validators.email,
                  ),

                  const SizedBox(height: MedRushTheme.spacingMd),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Teléfono (opcional)',
                      prefixIcon: const Icon(Icons.phone,
                          color: MedRushTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(MedRushTheme.borderRadiusMd),
                      ),
                      filled: true,
                      fillColor: MedRushTheme.backgroundSecondary,
                    ),
                  ),

                  const SizedBox(height: MedRushTheme.spacingMd),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePwd,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: MedRushTheme.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscurePwd
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: MedRushTheme.textSecondary),
                        onPressed: () =>
                            setState(() => _obscurePwd = !_obscurePwd),
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(MedRushTheme.borderRadiusMd),
                      ),
                      filled: true,
                      fillColor: MedRushTheme.backgroundSecondary,
                    ),
                    validator: Validators.password,
                  ),

                  const SizedBox(height: MedRushTheme.spacingMd),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: MedRushTheme.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: MedRushTheme.textSecondary),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(MedRushTheme.borderRadiusMd),
                      ),
                      filled: true,
                      fillColor: MedRushTheme.backgroundSecondary,
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Confirma tu contraseña'
                        : null,
                  ),

                  const SizedBox(height: MedRushTheme.spacingXl),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _register,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.person_add, color: Colors.white),
                      label: Text(
                          _isLoading ? 'Creando cuenta...' : 'Crear cuenta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MedRushTheme.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
