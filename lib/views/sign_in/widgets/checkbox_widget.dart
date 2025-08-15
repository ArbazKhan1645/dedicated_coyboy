import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/consts/appthemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PasswordOptionsRow extends StatelessWidget {
  final bool isChecked;
  final void Function(bool?)? onChanged;
  final VoidCallback? onForgotPasswordTap;

  const PasswordOptionsRow({
    Key? key,
    required this.isChecked,
    this.onChanged,
    this.onForgotPasswordTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember Password Checkbox
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: isChecked,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onChanged?.call(!isChecked),
              child: const Text(
                'remember password',
                style: TextStyle(fontSize: 14, color: Color(0xFF424242)),
              ),
            ),
          ],
        ),

        // Forget Password Button
        GestureDetector(
          onTap: onForgotPasswordTap,
          child: Text(
            'Forget password',
            style: Appthemes.textSmall.copyWith(
              fontSize: 15.sp,
              fontFamily: 'popins-bold',
              color: appColors.darkBlue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
