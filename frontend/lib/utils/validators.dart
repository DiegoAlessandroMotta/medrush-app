class Validators {
  // ===== Validadores para formularios =====

  /// Valida email (para uso en TextFormField.validator)
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }
    if (!isValidEmailStrict(value.trim())) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  /// Valida contraseña (para uso en TextFormField.validator)
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  // ===== Funciones de validación (retornan bool) =====

  /// Valida si un email tiene un formato válido
  static bool isValidEmailStrict(String email) {
    if (email.isEmpty || email.length > 254) {
      return false;
    }

    final parts = email.split('@');
    if (parts.length != 2) {
      return false;
    }

    final localPart = parts[0];
    final domainPart = parts[1];

    // Validar parte local (antes de @)
    if (localPart.isEmpty || localPart.length > 64) {
      return false;
    }
    if (localPart.startsWith('.') ||
        localPart.endsWith('.') ||
        localPart.contains(' ')) {
      return false;
    }

    // Validar dominio (después de @)
    if (domainPart.isEmpty ||
        domainPart.length > 253 ||
        !domainPart.contains('.')) {
      return false;
    }
    if (domainPart.startsWith('.') ||
        domainPart.endsWith('.') ||
        domainPart.startsWith('-') ||
        domainPart.endsWith('-')) {
      return false;
    }

    // Validar TLD (2-4 caracteres, solo letras)
    final domainParts = domainPart.split('.');
    if (domainParts.length < 2) {
      return false;
    }
    final tld = domainParts.last;
    if (tld.length < 2 || tld.length > 4) {
      return false;
    }
    for (var i = 0; i < tld.length; i++) {
      final code = tld.codeUnitAt(i);
      final isLower = code >= 97 && code <= 122; // 'a'-'z'
      final isUpper = code >= 65 && code <= 90; // 'A'-'Z'
      if (!isLower && !isUpper) {
        return false;
      }
    }

    return true;
  }

  /// Valida si un teléfono tiene un formato válido (USA: +1XXXXXXXXXX)
  static bool isValidPhoneFormat(String phone,
      {int minLength = 7, int maxLength = 15}) {
    if (phone.isEmpty) {
      return false;
    }

    int digitCount = 0;
    bool hasPlus = false;

    for (var i = 0; i < phone.length; i++) {
      final code = phone.codeUnitAt(i);
      final isDigit = code >= 48 && code <= 57; // '0'-'9'
      final isSpace = code == 32; // ' '
      final isDash = code == 45; // '-'
      final isParenthesisOpen = code == 40; // '('
      final isParenthesisClose = code == 41; // ')'
      final isPlus = code == 43; // '+'

      if (isDigit) {
        digitCount++;
      } else if (isPlus) {
        if (i != 0) {
          return false; // + solo puede estar al inicio
        }
        hasPlus = true;
      } else if (!isSpace &&
          !isDash &&
          !isParenthesisOpen &&
          !isParenthesisClose) {
        return false; // Carácter no permitido
      }
    }

    final totalLength = phone.length;
    if (totalLength < minLength || totalLength > maxLength) {
      return false;
    }
    if (digitCount < minLength - (hasPlus ? 1 : 0)) {
      return false;
    }

    return true;
  }

  /// Valida formato de token FCM
  static bool isValidFcmToken(String token) {
    if (token.isEmpty || token.length < 140 || token.length > 160) {
      return false;
    }
    for (var i = 0; i < token.length; i++) {
      final code = token.codeUnitAt(i);
      final isDigit = code >= 48 && code <= 57; // '0'-'9'
      final isLower = code >= 97 && code <= 122; // 'a'-'z'
      final isUpper = code >= 65 && code <= 90; // 'A'-'Z'
      final isColon = code == 58; // ':'
      final isUnderscore = code == 95; // '_'
      final isDash = code == 45; // '-'

      if (!isDigit &&
          !isLower &&
          !isUpper &&
          !isColon &&
          !isUnderscore &&
          !isDash) {
        return false;
      }
    }
    return true;
  }

  // ===== Funciones helper para manipulación de strings =====

  /// Remueve todos los caracteres no numéricos
  static String removeNonDigits(String value) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      if (code >= 48 && code <= 57) {
        // '0'-'9'
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  /// Normaliza espacios múltiples a un solo espacio
  static String normalizeSpaces(String value) {
    final buffer = StringBuffer();
    bool lastWasSpace = false;
    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      final isSpace = code == 32 ||
          (code >= 9 && code <= 13); // espacio, tab, newline, etc.

      if (isSpace) {
        if (!lastWasSpace) {
          buffer.write(' ');
          lastWasSpace = true;
        }
      } else {
        buffer.writeCharCode(code);
        lastWasSpace = false;
      }
    }
    return buffer.toString();
  }

  /// Divide texto por comas y espacios
  static List<String> splitByCommasAndSpaces(String value) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool isSeparator = false;

    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      final isComma = code == 44; // ','
      final isSpace =
          code == 32 || (code >= 9 && code <= 13); // espacio, tab, etc.

      if (isComma || isSpace) {
        if (buffer.isNotEmpty && !isSeparator) {
          result.add(buffer.toString());
          buffer.clear();
          isSeparator = true;
        }
      } else {
        buffer.writeCharCode(code);
        isSeparator = false;
      }
    }

    if (buffer.isNotEmpty) {
      result.add(buffer.toString());
    }

    return result;
  }

  /// Remueve todos los dígitos (equivalente a \D)
  static String removeDigits(String value) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      if (code < 48 || code > 57) {
        // No es '0'-'9'
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  /// Remueve todos los dígitos de un string (mantiene solo no-dígitos)
  static String removeDigitsFromString(String value) {
    return removeDigits(value);
  }

  /// Limpia caracteres especiales para headers CSV
  static String cleanCsvHeader(String header) {
    final buffer = StringBuffer();
    for (var i = 0; i < header.length; i++) {
      final code = header.codeUnitAt(i);
      final isLower = code >= 97 && code <= 122; // 'a'-'z'
      final isDigit = code >= 48 && code <= 57; // '0'-'9'
      final isUnderscore = code == 95; // '_'
      final isSpace = code == 32; // ' '

      if (isLower || isDigit || isUnderscore || isSpace) {
        buffer
            .writeCharCode(isSpace ? 95 : code); // Reemplazar espacios con '_'
      }
    }
    return buffer.toString();
  }

  /// Limpia caracteres de control problemáticos
  static String removeControlCharacters(String value) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      // Mantener caracteres imprimibles (excepto DEL 0x7F)
      // 0x00-0x08, 0x0B-0x0C, 0x0E-0x1F, 0x7F son caracteres de control
      if (!((code >= 0x00 && code <= 0x08) ||
          (code >= 0x0B && code <= 0x0C) ||
          (code >= 0x0E && code <= 0x1F) ||
          code == 0x7F)) {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  /// Valida si una cadena contiene solo números
  static bool isNumericOnly(String value) {
    if (value.isEmpty) {
      return false;
    }
    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      if (code < 48 || code > 57) {
        // '0' = 48, '9' = 57
        return false;
      }
    }
    return true;
  }

  /// Valida si una cadena contiene solo alfanuméricos
  static bool isAlphanumericOnly(String value) {
    if (value.isEmpty) {
      return false;
    }
    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      final isDigit = code >= 48 && code <= 57; // '0'-'9'
      final isLower = code >= 97 && code <= 122; // 'a'-'z'
      final isUpper = code >= 65 && code <= 90; // 'A'-'Z'
      if (!isDigit && !isLower && !isUpper) {
        return false;
      }
    }
    return true;
  }

  /// Valida si una cadena contiene solo letras y espacios
  static bool isLettersAndSpacesOnly(String value) {
    if (value.isEmpty) {
      return false;
    }
    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      final isLower = code >= 97 && code <= 122; // 'a'-'z'
      final isUpper = code >= 65 && code <= 90; // 'A'-'Z'
      final isSpace = code == 32; // ' '
      if (!isLower && !isUpper && !isSpace) {
        return false;
      }
    }
    return true;
  }

  /// Valida si una cadena contiene solo letras, números y espacios
  static bool isAlphanumericAndSpacesOnly(String value) {
    if (value.isEmpty) {
      return false;
    }
    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      final isDigit = code >= 48 && code <= 57; // '0'-'9'
      final isLower = code >= 97 && code <= 122; // 'a'-'z'
      final isUpper = code >= 65 && code <= 90; // 'A'-'Z'
      final isSpace = code == 32; // ' '
      final isDash = code == 45; // '-'
      if (!isDigit && !isLower && !isUpper && !isSpace && !isDash) {
        return false;
      }
    }
    return true;
  }

  /// Valida si una cadena contiene solo mayúsculas y números
  static bool isUppercaseAndNumbersOnly(String value) {
    if (value.isEmpty) {
      return false;
    }
    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      final isDigit = code >= 48 && code <= 57; // '0'-'9'
      final isUpper = code >= 65 && code <= 90; // 'A'-'Z'
      if (!isDigit && !isUpper) {
        return false;
      }
    }
    return true;
  }

  /// Valida si una cadena contiene solo mayúsculas, números y guiones
  static bool isUppercaseNumbersAndDashesOnly(String value) {
    if (value.isEmpty) {
      return false;
    }
    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      final isDigit = code >= 48 && code <= 57; // '0'-'9'
      final isUpper = code >= 65 && code <= 90; // 'A'-'Z'
      final isDash = code == 45; // '-'
      if (!isDigit && !isUpper && !isDash) {
        return false;
      }
    }
    return true;
  }

  /// Valida si una contraseña tiene formato complejo (mayúsculas, minúsculas y números)
  static bool isComplexPassword(String password) {
    bool hasUpper = false;
    bool hasLower = false;
    bool hasDigit = false;

    for (var i = 0; i < password.length; i++) {
      final code = password.codeUnitAt(i);
      if (code >= 65 && code <= 90) {
        // 'A'-'Z'
        hasUpper = true;
      } else if (code >= 97 && code <= 122) {
        // 'a'-'z'
        hasLower = true;
      } else if (code >= 48 && code <= 57) {
        // '0'-'9'
        hasDigit = true;
      }

      if (hasUpper && hasLower && hasDigit) {
        return true;
      }
    }

    return false;
  }

  // ===== Formateo de teléfono (USA +1) =====

  /// Formatea un número de teléfono al formato E.164 para USA (+1)
  /// [phone] El número de teléfono a formatear
  /// Retorna el número en formato E.164 (ej: +15551234567)
  static String formatPhoneToE164(String phone) {
    if (phone.isEmpty) {
      return phone;
    }

    // Remover espacios, guiones y paréntesis
    final cleaned = phone
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '');

    // Ya en E.164
    if (cleaned.startsWith('+')) {
      return cleaned;
    }

    // Si empieza con 1, agregar +
    if (cleaned.startsWith('1')) {
      return '+$cleaned';
    }

    // 10 dígitos -> +1XXXXXXXXXX
    if (isNumericOnly(cleaned) && cleaned.length == 10) {
      return '+1$cleaned';
    }

    // Si tiene 11 dígitos empezando en 1, solo agregar +
    if (cleaned.startsWith('1') &&
        isNumericOnly(cleaned) &&
        cleaned.length == 11) {
      return '+$cleaned';
    }

    // Para otros casos, intentar formatear con +1
    final digitsOnly = removeNonDigits(cleaned);
    if (digitsOnly.isNotEmpty && isNumericOnly(digitsOnly)) {
      // Si tiene 10 dígitos, agregar +1
      if (digitsOnly.length == 10) {
        return '+1$digitsOnly';
      }
      // Si tiene 11 dígitos empezando en 1, solo agregar +
      if (digitsOnly.length == 11 && digitsOnly.startsWith('1')) {
        return '+$digitsOnly';
      }
    }

    // Si no se puede formatear, devolver original
    return phone;
  }

  // ===== Patterns para input formatters =====

  /// Filtro para input formatters que permite solo números, +, - y espacios
  static Pattern getPhoneInputPattern() {
    return _PhoneInputPattern();
  }

  /// Filtro para input formatters que permite solo alfanuméricos
  static Pattern getAlphanumericInputPattern() {
    return _AlphanumericInputPattern();
  }
}

/// Patrón personalizado para input formatters de teléfono
/// Permite solo números, +, - y espacios
class _PhoneInputPattern implements Pattern {
  @override
  Match? matchAsPrefix(String string, [int start = 0]) {
    if (start >= string.length) {
      return null;
    }
    final char = string[start];
    final code = char.codeUnitAt(0);
    final isDigit = code >= 48 && code <= 57; // '0'-'9'
    final isPlus = code == 43; // '+'
    final isDash = code == 45; // '-'
    final isSpace = code == 32; // ' '

    if (isDigit || isPlus || isDash || isSpace) {
      return _SimpleMatch(char, start, string);
    }
    return null;
  }

  @override
  Iterable<Match> allMatches(String string, [int start = 0]) {
    final matches = <Match>[];
    for (var i = start; i < string.length; i++) {
      final match = matchAsPrefix(string, i);
      if (match != null) {
        matches.add(match);
      }
    }
    return matches;
  }

  Match? firstMatch(String string) {
    for (var i = 0; i < string.length; i++) {
      final match = matchAsPrefix(string, i);
      if (match != null) {
        return match;
      }
    }
    return null;
  }
}

/// Patrón personalizado para input formatters alfanuméricos
/// Permite solo letras y números
class _AlphanumericInputPattern implements Pattern {
  @override
  Match? matchAsPrefix(String string, [int start = 0]) {
    if (start >= string.length) {
      return null;
    }
    final char = string[start];
    final code = char.codeUnitAt(0);
    final isDigit = code >= 48 && code <= 57; // '0'-'9'
    final isLower = code >= 97 && code <= 122; // 'a'-'z'
    final isUpper = code >= 65 && code <= 90; // 'A'-'Z'

    if (isDigit || isLower || isUpper) {
      return _SimpleMatch(char, start, string);
    }
    return null;
  }

  @override
  Iterable<Match> allMatches(String string, [int start = 0]) {
    final matches = <Match>[];
    for (var i = start; i < string.length; i++) {
      final match = matchAsPrefix(string, i);
      if (match != null) {
        matches.add(match);
      }
    }
    return matches;
  }

  Match? firstMatch(String string) {
    for (var i = 0; i < string.length; i++) {
      final match = matchAsPrefix(string, i);
      if (match != null) {
        return match;
      }
    }
    return null;
  }
}

/// Implementación simple de Match para los patrones personalizados
class _SimpleMatch implements Match {
  final String _matched;
  final int _start;
  final String _input;

  _SimpleMatch(this._matched, this._start, this._input);

  @override
  String? operator [](int group) {
    if (group == 0) {
      return _matched;
    }
    return null;
  }

  @override
  String? group(int group) {
    if (group == 0) {
      return _matched;
    }
    return null;
  }

  @override
  int get groupCount => 0;

  @override
  List<String?> groups(List<int> groupIndices) => [_matched];

  @override
  int get start => _start;

  @override
  int get end => _start + _matched.length;

  @override
  Pattern get pattern => throw UnimplementedError();

  @override
  String get input => _input;
}
