class Validators {
  // Validador de email
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un email válido';
    }

    return null;
  }

  // Validador de contraseña
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    return null;
  }

  // Validador de teléfono
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es requerido';
    }

    // Remover espacios y caracteres especiales
    final cleanedValue = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanedValue.length < 10) {
      return 'El teléfono debe tener al menos 10 dígitos';
    }

    return null;
  }

  // Validador de nombre
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }

    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }

    return null;
  }

  // Validador de código de barras
  static String? barcode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El código de barras es requerido';
    }

    // Validar que solo contenga números y letras
    final barcodeRegex = RegExp(r'^[A-Za-z0-9]+$');
    if (!barcodeRegex.hasMatch(value.trim())) {
      return 'Código de barras inválido';
    }

    if (value.trim().length < 6) {
      return 'El código debe tener al menos 6 caracteres';
    }

    return null;
  }

  // Validador de campo requerido
  static String? required(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  // Validador de dirección
  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La dirección es requerida';
    }

    if (value.trim().length < 10) {
      return 'La dirección debe ser más específica';
    }

    return null;
  }

  // Validador de motivo de falla
  static String? failureReason(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Debes especificar el motivo de la falla';
    }

    if (value.trim().length < 5) {
      return 'El motivo debe tener al menos 5 caracteres';
    }

    return null;
  }

  // Validador de observaciones
  static String? observations(String? value) {
    // Las observaciones son opcionales, pero si se ingresan deben tener contenido
    if (value != null && value.trim().isNotEmpty && value.trim().length < 3) {
      return 'Las observaciones deben tener al menos 3 caracteres';
    }

    return null;
  }

  // Función para limpiar número de teléfono
  static String cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  // Función para formatear número de teléfono
  static String formatPhoneNumber(String phone) {
    final cleaned = cleanPhoneNumber(phone);
    if (cleaned.length == 10) {
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    }
    return phone;
  }

  // Validador de coordenadas
  static String? coordinates(double? lat, double? lng) {
    if (lat == null || lng == null) {
      return 'Las coordenadas son requeridas';
    }

    if (lat < -90 || lat > 90) {
      return 'Latitud inválida';
    }

    if (lng < -180 || lng > 180) {
      return 'Longitud inválida';
    }

    return null;
  }
}
