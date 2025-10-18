import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema profesional para MedRush - Delivery de Medicamentos
/// Paleta inspirada en la industria farmacéutica y de delivery
class MedRushTheme {
  // ========================================
  // PALETA DE COLORES PRINCIPAL
  // ========================================

  // Colores primarios - Azul principal (basado en la nueva paleta)
  static const Color primaryBlue = Color(0xFF006BBA); // Azul principal
  static const Color primaryBlueLight = Color(0xFF0091F9); // Azul claro
  static const Color primaryBlueDark = Color(0xFF00406E); // Azul oscuro

  // Colores secundarios - Verde asparagus
  static const Color primaryGreen =
      Color(0xFF5F9041); // Verde asparagus principal
  static const Color primaryGreenLight =
      Color(0xFF7CB459); // Verde asparagus claro
  static const Color primaryGreenDark =
      Color(0xFF395727); // Verde asparagus oscuro

  // Colores de acento - Verde forest
  static const Color accentGreen = Color(0xFF5A8E3D); // Verde forest
  static const Color accentGreenLight = Color(0xFF76B654); // Verde forest claro
  static const Color accentGreenDark = Color(0xFF365625); // Verde forest oscuro

  // Colores de acento - Gris para botones secundarios
  static const Color accentGrey =
      Color(0xFFF5F5F5); // Gris claro para botones secundarios
  static const Color accentGreyLight = Color(0xFFFAFAFA); // Gris muy claro
  static const Color accentGreyDark = Color(0xFFE0E0E0); // Gris oscuro

  // Colores secundarios - Azul para compatibilidad
  static const Color secondaryBlue =
      Color(0xFF006BBA); // Azul principal (alias)
  static const Color secondaryBlueLight =
      Color(0xFF0091F9); // Azul claro (alias)
  static const Color secondaryBlueDark =
      Color(0xFF00406E); // Azul oscuro (alias)

  // ========================================
  // COLORES NEUTRALES
  // ========================================

  // Grises profesionales
  static const Color neutralGrey50 = Color(0xFFFAFAFA);
  static const Color neutralGrey100 = Color(0xFFF5F5F5);
  static const Color neutralGrey200 = Color(0xFFEEEEEE);
  static const Color neutralGrey300 = Color(0xFFE0E0E0);
  static const Color neutralGrey400 = Color(0xFFBDBDBD);
  static const Color neutralGrey500 = Color(0xFF9E9E9E);
  static const Color neutralGrey600 = Color(0xFF757575);
  static const Color neutralGrey700 = Color(0xFF616161);
  static const Color neutralGrey800 = Color(0xFF424242);
  static const Color neutralGrey900 = Color(0xFF212121);

  // ========================================
  // COLORES SEMÁNTICOS
  // ========================================

  // Estados de pedidos
  static const Color statusPending = Color(0xFFFFA000); // Amarillo pendiente
  static const Color statusInProgress =
      Color(0xFF006BBA); // Azul principal en progreso
  static const Color statusCompleted =
      Color(0xFF5F9041); // Verde asparagus completado
  static const Color statusFailed = Color(0xFFD32F2F); // Rojo fallido
  static const Color statusCancelled = Color(0xFF757575); // Gris cancelado

  // Estados de repartidores
  static const Color statusAvailable =
      Color(0xFF5F9041); // Verde asparagus disponible
  static const Color statusBusy = Color(0xFFFF6F00); // Naranja en ruta
  static const Color statusOffline = Color(0xFF757575); // Gris desconectado

  // Alertas y notificaciones
  static const Color success = Color(0xFF5F9041); // Verde asparagus éxito
  static const Color warning = Color(0xFFFFA000); // Amarillo advertencia
  static const Color error = Color(0xFFD32F2F); // Rojo error
  static const Color info = Color(0xFF006BBA); // Azul principal información

  // Colores específicos para contenido especial
  static const Color observations =
      Color(0xFF006BBA); // Azul principal para observaciones
  static const Color specialSignature =
      Color(0xFF5F9041); // Verde asparagus para firma especial

  // ========================================
  // COLORES DE FONDO
  // ========================================

  static const Color backgroundPrimary = Color(0xFFFFFFFF); // Blanco principal
  static const Color backgroundSecondary = Color(0xFFFAFAFA); // Gris muy claro
  static const Color backgroundTertiary = Color(0xFFF5F5F5); // Gris claro
  static const Color surface = Color(0xFFFFFFFF); // Superficie
  static const Color surfaceVariant =
      Color(0xFFF5F5F5); // Variante de superficie

  // ========================================
  // COLORES DE TEXTO
  // ========================================

  static const Color textPrimary = Color(0xFF212121); // Texto principal
  static const Color textSecondary = Color(0xFF757575); // Texto secundario
  static const Color textTertiary = Color(0xFF9E9E9E); // Texto terciario
  static const Color textDisabled = Color(0xFFBDBDBD); // Texto deshabilitado
  static const Color textInverse = Color(0xFFFFFFFF); // Texto inverso

  // ========================================
  // COLORES DE BORDES Y DIVISORES
  // ========================================

  static const Color borderPrimary = Color(0xFFE0E0E0); // Borde principal
  static const Color borderSecondary = Color(0xFFEEEEEE); // Borde secundario
  static const Color borderLight = Color(0xFFE0E0E0); // Borde claro para inputs
  static const Color divider = Color(0xFFE0E0E0); // Divisor

  // ========================================
  // COLORES DE SOMBRAS
  // ========================================

  static const Color shadowLight = Color(0x1A000000); // Sombra ligera
  static const Color shadowMedium = Color(0x33000000); // Sombra media
  static const Color shadowDark = Color(0x4D000000); // Sombra oscura

  // ========================================
  // CONFIGURACIÓN DE FUENTES
  // ========================================

  // Familia de fuentes principal - Public Sans (moderna y legible)
  static const String fontFamilyPrimary = 'Public Sans';

  // Familia de fuentes secundaria - Inter (fallback moderna)
  static const String fontFamilySecondary = 'Inter';

  // Tamaños de fuente
  static const double fontSizeDisplayLarge = 57.0;
  static const double fontSizeDisplayMedium = 45.0;
  static const double fontSizeDisplaySmall = 36.0;
  static const double fontSizeHeadlineLarge = 32.0;
  static const double fontSizeHeadlineMedium = 28.0;
  static const double fontSizeHeadlineSmall = 24.0;
  static const double fontSizeTitleLarge = 22.0;
  static const double fontSizeTitleMedium = 16.0;
  static const double fontSizeTitleSmall = 14.0;
  static const double fontSizeBodyLarge =
      17.0; // +1px para mejorar legibilidad en listas
  static const double fontSizeBodyMedium = 15.0; // +1px
  static const double fontSizeBodySmall = 13.0; // +1px
  static const double fontSizeLabelLarge = 14.0;
  static const double fontSizeLabelMedium = 13.0; // +1px
  static const double fontSizeLabelSmall = 12.0; // +1px

  // Pesos de fuente
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // ========================================
  // CONFIGURACIÓN DE ESPACIADO
  // ========================================

  // Espaciado base (8px)
  static const double spacingBase = 8.0;

  // Espaciado específico
  static const double spacingXs = 4.0; // 4px
  static const double spacingSm = 8.0; // 8px
  static const double spacingMd = 16.0; // 16px
  static const double spacingLg = 24.0; // 24px
  static const double spacingXl = 32.0; // 32px
  static const double spacingXxl = 48.0; // 48px
  static const double spacingXxxl = 64.0; // 64px

  // ========================================
  // CONFIGURACIÓN DE BORDES RADIUS
  // ========================================

  static const double borderRadiusXs = 4.0; // 4px
  static const double borderRadiusSm = 8.0; // 8px
  static const double borderRadiusMd = 12.0; // 12px
  static const double borderRadiusLg = 16.0; // 16px
  static const double borderRadiusXl = 24.0; // 24px
  static const double borderRadiusCircular = 50.0; // Circular

  // ========================================
  // CONFIGURACIÓN DE ELEVACIÓN
  // ========================================

  static const double elevationNone = 0.0;
  static const double elevationXs = 1.0;
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 16.0;

  // ========================================
  // TEMA CLARO
  // ========================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Configuración de colores
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        primaryContainer: primaryBlueLight,
        onPrimaryContainer: textInverse,
        secondary: primaryGreen,
        onSecondary: textInverse,
        secondaryContainer: primaryGreenLight,
        onSecondaryContainer: textPrimary,
        tertiary: accentGreen,
        onTertiary: textInverse,
        tertiaryContainer: accentGreenLight,
        onTertiaryContainer: textPrimary,
        error: error,
        errorContainer: Color(0xFFFFEBEE),
        onErrorContainer: error,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceVariant,
        onSurfaceVariant: textSecondary,
        outline: borderPrimary,
        outlineVariant: borderSecondary,
        shadow: shadowLight,
        scrim: shadowMedium,
        inverseSurface: neutralGrey900,
        onInverseSurface: textInverse,
        inversePrimary: primaryGreenLight,
        surfaceTint: primaryGreen,
      ),

      // Configuración de fuentes (Public Sans)
      // Notas UX: jerarquía clara, buen contraste, y límites de legibilidad.
      // - Titulares: pesos 600–700 con tracking leve negativo en tamaños grandes
      // - Cuerpos: 400 y líneas 1.45–1.55
      // - Etiquetas/botones: 600 para mejor toque/escaneo
      fontFamily: fontFamilyPrimary,
      textTheme: GoogleFonts.publicSansTextTheme().copyWith(
        // Display grande: 57/64, Bold con tracking leve
        displayLarge: GoogleFonts.publicSans(
          fontSize: fontSizeDisplayLarge,
          height: 64 / fontSizeDisplayLarge,
          letterSpacing: -0.25,
          fontWeight: fontWeightBold,
          color: textPrimary,
        ),
        // Display mediano: 45/52, Semibold
        displayMedium: GoogleFonts.publicSans(
          fontSize: fontSizeDisplayMedium,
          height: 52 / fontSizeDisplayMedium,
          letterSpacing: -0.2,
          fontWeight: fontWeightSemiBold,
          color: textPrimary,
        ),
        // Display pequeño: 36/44, Semibold
        displaySmall: GoogleFonts.publicSans(
          fontSize: fontSizeDisplaySmall,
          height: 44 / fontSizeDisplaySmall,
          letterSpacing: -0.1,
          fontWeight: fontWeightSemiBold,
          color: textPrimary,
        ),
        // Headline grande: 32/40, Semibold
        headlineLarge: GoogleFonts.publicSans(
          fontSize: fontSizeHeadlineLarge,
          height: 40 / fontSizeHeadlineLarge,
          fontWeight: fontWeightSemiBold,
          color: textPrimary,
        ),
        // Headline mediano: 28/36, Medium
        headlineMedium: GoogleFonts.publicSans(
          fontSize: fontSizeHeadlineMedium,
          height: 36 / fontSizeHeadlineMedium,
          fontWeight: fontWeightMedium,
          color: textPrimary,
        ),
        // Headline pequeño: 24/32, Medium
        headlineSmall: GoogleFonts.publicSans(
          fontSize: fontSizeHeadlineSmall,
          height: 32 / fontSizeHeadlineSmall,
          fontWeight: fontWeightMedium,
          color: textPrimary,
        ),
        // Títulos para pantallas y secciones
        titleLarge: GoogleFonts.publicSans(
          fontSize: fontSizeTitleLarge,
          height: 28 / fontSizeTitleLarge,
          fontWeight: fontWeightSemiBold,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.publicSans(
          fontSize: fontSizeTitleMedium,
          height: 22 / fontSizeTitleMedium,
          letterSpacing: 0.1,
          fontWeight: fontWeightMedium,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.publicSans(
          fontSize: fontSizeTitleSmall,
          height: 20 / fontSizeTitleSmall,
          letterSpacing: 0.1,
          fontWeight: fontWeightMedium,
          color: textPrimary,
        ),
        // Cuerpo de texto
        bodyLarge: GoogleFonts.publicSans(
          fontSize: fontSizeBodyLarge,
          height: 24 / fontSizeBodyLarge,
          letterSpacing: 0.15,
          fontWeight: fontWeightRegular,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.publicSans(
          fontSize: fontSizeBodyMedium,
          height: 20 / fontSizeBodyMedium,
          letterSpacing: 0.15,
          fontWeight: fontWeightRegular,
          color: textPrimary,
        ),
        bodySmall: GoogleFonts.publicSans(
          fontSize: fontSizeBodySmall,
          height: 18 / fontSizeBodySmall,
          letterSpacing: 0.2,
          fontWeight: fontWeightRegular,
          color: textSecondary,
        ),
        // Etiquetas y botones
        labelLarge: GoogleFonts.publicSans(
          fontSize: fontSizeLabelLarge,
          height: 20 / fontSizeLabelLarge,
          letterSpacing: 0.1,
          fontWeight: fontWeightSemiBold,
          color: textPrimary,
        ),
        labelMedium: GoogleFonts.publicSans(
          fontSize: fontSizeLabelMedium,
          height: 16 / fontSizeLabelMedium,
          letterSpacing: 0.2,
          fontWeight: fontWeightMedium,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.publicSans(
          fontSize: fontSizeLabelSmall,
          height: 16 / fontSizeLabelSmall,
          letterSpacing: 0.3,
          fontWeight: fontWeightMedium,
          color: textTertiary,
        ),
      ),

      // Configuración de AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: elevationNone,
        scrolledUnderElevation: elevationSm,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: fontSizeTitleLarge,
          fontWeight: fontWeightMedium,
          color: textPrimary,
        ),
      ),

      // Configuración de Card
      cardTheme: CardThemeData(
        color: surface,
        elevation: elevationSm,
        shadowColor: shadowLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
        ),
        margin: const EdgeInsets.all(spacingSm),
      ),

      // Configuración de ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: textInverse,
          elevation: elevationSm,
          shadowColor: shadowLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          textStyle: const TextStyle(
            // Button per guía: 16/24 Medium
            fontSize: 16,
            height: 24 / 16,
            fontWeight: fontWeightMedium,
          ),
        ),
      ),

      // Configuración de OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: fontWeightMedium,
          ),
        ),
      ),

      // Configuración de TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMd,
            vertical: spacingSm,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: fontWeightMedium,
          ),
        ),
      ),

      // Configuración de InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
          borderSide: const BorderSide(color: borderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
          borderSide: const BorderSide(color: borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingMd,
        ),
        labelStyle: const TextStyle(
          fontSize: fontSizeBodyMedium,
          color: textSecondary,
        ),
        hintStyle: const TextStyle(
          fontSize: fontSizeBodyMedium,
          color: textTertiary,
        ),
      ),

      // Configuración de FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: textInverse,
        elevation: elevationMd,
        shape: CircleBorder(),
      ),

      // Configuración de BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: elevationSm,
      ),

      // Configuración de Divider
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: spacingMd,
      ),

      // Configuración de Chip
      chipTheme: ChipThemeData(
        backgroundColor: backgroundSecondary,
        selectedColor: primaryGreenLight,
        disabledColor: backgroundTertiary,
        labelStyle: const TextStyle(
          fontSize: fontSizeBodySmall,
          fontWeight: fontWeightMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusCircular),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingXs,
        ),
      ),

      // Configuración de Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGreen;
          }
          return neutralGrey400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGreenLight;
          }
          return neutralGrey300;
        }),
      ),

      // Configuración de Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGreen;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(textInverse),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusXs),
        ),
      ),

      // Configuración de Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGreen;
          }
          return neutralGrey400;
        }),
      ),

      // Configuración de Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryGreen,
        inactiveTrackColor: neutralGrey300,
        thumbColor: primaryGreen,
        overlayColor: primaryGreenLight.withValues(alpha: 0.2),
        valueIndicatorColor: primaryGreen,
        valueIndicatorTextStyle: const TextStyle(
          color: textInverse,
          fontSize: fontSizeBodySmall,
          fontWeight: fontWeightMedium,
        ),
      ),

      // Configuración de ProgressIndicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
        linearTrackColor: neutralGrey300,
        circularTrackColor: neutralGrey300,
      ),

      // Configuración de SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: neutralGrey900,
        contentTextStyle: const TextStyle(
          color: textInverse,
          fontSize: fontSizeBodyMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Configuración de Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: elevationLg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusLg),
        ),
        titleTextStyle: const TextStyle(
          fontSize: fontSizeTitleLarge,
          fontWeight: fontWeightMedium,
          color: textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: fontSizeBodyMedium,
          color: textPrimary,
        ),
      ),

      // Configuración de BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        elevation: elevationLg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(borderRadiusLg),
          ),
        ),
      ),

      // Configuración de NavigationRail
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: IconThemeData(color: primaryGreen),
        unselectedIconTheme: IconThemeData(color: textTertiary),
        selectedLabelTextStyle: TextStyle(
          color: primaryGreen,
          fontSize: fontSizeBodySmall,
          fontWeight: fontWeightMedium,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: textTertiary,
          fontSize: fontSizeBodySmall,
        ),
      ),
    );
  }

  /// Obtiene el color de alerta
  static Color getAlertColor(String type) {
    switch (type.toLowerCase()) {
      case 'success':
      case 'exito':
        return success;
      case 'warning':
      case 'advertencia':
        return warning;
      case 'error':
        return error;
      case 'info':
      case 'informacion':
        return info;
      default:
        return textSecondary;
    }
  }
}
