import 'package:flutter/material.dart';

class TextWithDividers extends StatelessWidget {
  final String text;
  final Color? dividerColor;
  final double? dividerThickness;
  final double spacing;
  final TextStyle? textStyle;

  const TextWithDividers({
    Key? key,
    required this.text,
    this.dividerColor,
    this.dividerThickness,
    this.spacing = 16.0,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: dividerColor ?? Colors.grey,
            thickness: dividerThickness ?? 1.0,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing),
          child: Text(
            text,
            style:
                textStyle ??
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Divider(
            color: dividerColor ?? Colors.grey,
            thickness: dividerThickness ?? 1.0,
          ),
        ),
      ],
    );
  }
}
