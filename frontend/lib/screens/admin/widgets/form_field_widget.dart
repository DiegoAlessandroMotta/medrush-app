import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medrush/theme/theme.dart';

class FormFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;

  const FormFieldWidget({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: MedRushTheme.fontSizeBodyMedium,
            fontWeight: MedRushTheme.fontWeightMedium,
            color: MedRushTheme.textPrimary,
          ),
        ),
        const SizedBox(height: MedRushTheme.spacingSm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: MedRushTheme.textSecondary,
              fontSize: MedRushTheme.fontSizeBodyMedium,
            ),
            prefixIcon: Icon(
              icon,
              color: MedRushTheme.textSecondary,
            ),
            filled: true,
            fillColor: MedRushTheme.backgroundSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
              borderSide: const BorderSide(color: MedRushTheme.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
              borderSide: const BorderSide(color: MedRushTheme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
              borderSide: const BorderSide(color: MedRushTheme.primaryGreen),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: MedRushTheme.spacingMd,
              vertical: MedRushTheme.spacingMd,
            ),
          ),
          style: const TextStyle(
            color: MedRushTheme.textPrimary,
            fontSize: MedRushTheme.fontSizeBodyMedium,
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
          DiagnosticsProperty<TextEditingController>('controller', controller))
      ..add(StringProperty('label', label))
      ..add(StringProperty('hint', hint))
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(DiagnosticsProperty<TextInputType?>('keyboardType', keyboardType))
      ..add(ObjectFlagProperty<String? Function(String? p1)?>.has(
          'validator', validator))
      ..add(DiagnosticsProperty<bool>('obscureText', obscureText));
  }
}
