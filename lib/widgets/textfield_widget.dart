import 'package:dedicated_cowboy/consts/appthemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextField extends StatefulWidget {
  final String labelText;
  final String hintText;
  final TextEditingController? controller;
  final bool isPassword;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? customPasswordIcon; // Custom password icon image path
  final String?
  customPasswordIconVisible; // Custom icon when password is visible
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTap; // ✅ New onTap
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
    this.onTap, // ✅ New onTap param
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
          onTap: widget.onTap, // ✅ Allow tap handling
          enabled: widget.enabled,
          readOnly: widget.readOnly, // ✅ Already here
          maxLines: widget.maxLines,
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
            prefixIcon: widget.prefixIcon,
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
