import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

class CustomTextField extends ConsumerStatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String hintText;
  final String? labelText;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final EdgeInsetsGeometry? contentPadding;
  final String? errorText;
  final String? helperText;
  final bool autofocus;
  final FocusNode? focusNode;

  const CustomTextField({
    super.key,
    this.controller,
    this.initialValue,
    required this.hintText,
    this.labelText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.contentPadding,
    this.errorText,
    this.helperText,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  ConsumerState<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends ConsumerState<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final fillColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final cursorColor = isDarkMode ? Colors.white : Colors.black;

    return TextFormField(
      controller: widget.controller,
      initialValue: widget.initialValue,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      cursorColor: cursorColor, // 👈 fixes invisible cursor
      style: TextStyle(
        color: textColor,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        labelText: widget.labelText,
        errorText: widget.errorText,
        helperText: widget.helperText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : widget.suffixIcon,
        contentPadding: widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: fillColor,
        hintStyle: TextStyle(color: hintColor),
        // ignore: deprecated_member_use
        labelStyle: TextStyle(color: textColor.withOpacity(0.8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cursorColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
