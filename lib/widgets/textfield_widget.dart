import 'package:dedicated_cowboy/consts/appthemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextField extends StatefulWidget {
  final String labelText;
  final String hintText;
  final TextEditingController? controller;
  final bool isPassword;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? customPasswordIcon;
  final String? customPasswordIconVisible;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final bool enabled;
  final bool required;
  final bool readOnly;
  final int maxLines;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? labelColor;
  final Color? hintColor;
  final Color? textColor;
  final double? fontSize;
  final double borderRadius;
  final EdgeInsets? contentPadding;
  final bool showLabel;
  final double? customPasswordIconSize;
  final List<TextInputFormatter>? inputFormatters; // ✅ Add this parameter

  const CustomTextField({
    Key? key,
    required this.labelText,
    required this.hintText,
    this.controller,
    this.isPassword = false,
    this.required = false,
    this.suffixIcon,
    this.prefixIcon,
    this.customPasswordIcon,
    this.customPasswordIconVisible,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.fillColor = Colors.white,
    this.borderColor = const Color(0xFFE0E0E0),
    this.focusedBorderColor = Colors.black,
    this.labelColor = const Color(0xFF424242),
    this.hintColor = const Color(0xFF9E9E9E),
    this.textColor = const Color(0xFF212121),
    this.fontSize = 16.0,
    this.borderRadius = 12.0,
    this.contentPadding,
    this.showLabel = true,
    this.customPasswordIconSize = 24.0,
    this.inputFormatters, // ✅ Add this parameter
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _obscureText = widget.isPassword;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel) ...[
          Row(
            children: [
              Text(
                widget.labelText,
                style: Appthemes.textSmall.copyWith(
                  fontFamily: 'popins-bold',
                  fontSize: 13.5.sp,
                  color: widget.labelColor,
                ),
              ),
              if (widget.required) ...[
                Text(
                  ' *',
                  style: Appthemes.textSmall.copyWith(
                    color: Colors.red,
                    fontSize: 15.sp,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8.0),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.isPassword ? _obscureText : false,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          inputFormatters: widget.inputFormatters, // ✅ Add this line
          style: Appthemes.textSmall.copyWith(
            fontSize: widget.fontSize,
            color: widget.textColor,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: Appthemes.textMedium.copyWith(
              color: widget.hintColor,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: widget.fillColor,
            contentPadding:
                widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            prefixIcon:
                widget.labelText == 'Price'
                    ? widget.prefixIcon
                    : null, // ✅ Uncommented this line,
            suffixIcon: _buildSuffixIcon(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(color: widget.borderColor!, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(color: widget.borderColor!, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: widget.focusedBorderColor!,
                width: 1.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: const BorderSide(color: Colors.red, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: const BorderSide(color: Colors.red, width: 2.0),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: widget.borderColor!.withOpacity(0.5),
                width: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.isPassword) {
      if (widget.customPasswordIcon != null) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(
              _obscureText
                  ? widget.customPasswordIcon!
                  : (widget.customPasswordIconVisible ??
                      widget.customPasswordIcon!),
              width: widget.customPasswordIconSize,
              height: widget.customPasswordIconSize,
              fit: BoxFit.contain,
            ),
          ),
        );
      } else {
        return IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: widget.hintColor,
            size: 20.sp,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        );
      }
    }
    return widget.suffixIcon;
  }
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Limit to 10 digits
    if (digitsOnly.length > 10) {
      digitsOnly = digitsOnly.substring(0, 10);
    }

    // Format based on length
    String formatted = '';
    int cursorPosition = newValue.selection.baseOffset;

    if (digitsOnly.isNotEmpty) {
      formatted = digitsOnly.substring(0, digitsOnly.length.clamp(0, 3));

      if (digitsOnly.length >= 4) {
        formatted +=
            '-${digitsOnly.substring(3, digitsOnly.length.clamp(3, 6))}';

        if (digitsOnly.length >= 7) {
          formatted +=
              '-${digitsOnly.substring(6, digitsOnly.length.clamp(6, 10))}';
        }
      }
    }

    // Calculate new cursor position
    int newCursorPosition = formatted.length;
    if (cursorPosition <= oldValue.text.length) {
      // Count digits before cursor in old text
      String beforeCursor = oldValue.text.substring(
        0,
        cursorPosition.clamp(0, oldValue.text.length),
      );
      int digitsBefore = beforeCursor.replaceAll(RegExp(r'[^\d]'), '').length;

      // Find position after same number of digits in new text
      int digitsCount = 0;
      for (int i = 0; i < formatted.length; i++) {
        if (RegExp(r'\d').hasMatch(formatted[i])) {
          digitsCount++;
          if (digitsCount == digitsBefore) {
            newCursorPosition = i + 1;
            break;
          }
        }
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newCursorPosition.clamp(0, formatted.length),
      ),
    );
  }
}
