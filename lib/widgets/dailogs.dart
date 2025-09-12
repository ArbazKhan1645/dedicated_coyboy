import 'package:dedicated_cowboy/consts/appColors.dart';
import 'package:dedicated_cowboy/consts/appthemes.dart';
import 'package:dedicated_cowboy/widgets/custom_elevated_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:async';

// 1. FORGET PASSWORD DIALOG
class ForgetPasswordDialog extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  ForgetPasswordDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: appColors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/Frame.png',
                  width: 25.w,
                  height: 25.h,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Forget Password',
                      style: Appthemes.textMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Subtitle
                    SizedBox(
                      width: 200.w,
                      child: Text(
                        maxLines: 2,
                        'Please enter your email or phone number to recover or set your password.',
                        textAlign: TextAlign.start,
                        style: Appthemes.textSmall.copyWith(
                          fontSize: 13.sp,
                          color: appColors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                Spacer(),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: appColors.pYellow,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16.sp,
                      color: appColors.white,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Email or Phone label
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Email or Phone',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: appColors.black,
                ),
              ),
            ),
            SizedBox(height: 8.h),

            // Text Field
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: '+92 000 000 000',
                hintStyle: TextStyle(color: appColors.grey, fontSize: 14.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                    color: appColors.grey.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: appColors.pYellow),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // Send Button
            SizedBox(
              width: double.infinity,

              child: CustomElevatedButton(
                borderRadius: 25.r,
                text: 'SEND',
                backgroundColor: appColors.pYellow,
                textColor: appColors.white,
                isLoading: false,
                onTap: () {
                  Get.back();
                  showCheckPhoneDialog();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. CHECK PHONE DIALOG (OTP)
class CheckPhoneDialog extends StatefulWidget {
  const CheckPhoneDialog({Key? key}) : super(key: key);

  @override
  State<CheckPhoneDialog> createState() => _CheckPhoneDialogState();
}

class _CheckPhoneDialogState extends State<CheckPhoneDialog> {
  List<TextEditingController> otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  List<FocusNode> focusNodes = List.generate(4, (index) => FocusNode());
  Timer? _timer;
  int _countdown = 240; // 4:00 minutes

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  void startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String get countdownText {
    int minutes = _countdown ~/ 60;
    int seconds = _countdown % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: appColors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/Group 1000005712.png',
                  width: 25.w,
                  height: 25.h,
                ),
                SizedBox(width: 5),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Check Phone',
                      style: Appthemes.textMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Subtitle
                    SizedBox(
                      width: 200.w,
                      child: Text(
                        maxLines: 2,
                        'We have sent  the code to your phone',
                        textAlign: TextAlign.start,
                        style: Appthemes.textSmall.copyWith(
                          fontSize: 12.sp,
                          color: appColors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                Spacer(),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: appColors.pYellow,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16.sp,
                      color: appColors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    border: Border.all(color: appColors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: TextField(
                    controller: otpControllers[index],
                    focusNode: focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 3) {
                        focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            SizedBox(height: 24.h),

            // Resend Code
            Row(
              children: [
                Text(
                  'Don\'t receive the code? ',
                  style: Appthemes.textSmall.copyWith(
                    fontSize: 14.sp,
                    // fontWeight: FontWeight.w900,
                    color: appColors.grey,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Resend code logic
                  },
                  child: Text(
                    "Click here",
                    style: Appthemes.textSmall.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: appColors.grey,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Send Button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  showPasswordRecoveredDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors.pYellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
                child: Text(
                  'SEND',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: appColors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Countdown
            Text(
              'Code expires in $countdownText',
              style: TextStyle(fontSize: 14.sp, color: appColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. PASSWORD RECOVERED DIALOG
class PasswordRecoveredDialog extends StatelessWidget {
  const PasswordRecoveredDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: appColors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 24.w), // Spacer
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: appColors.pYellow,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16.sp,
                      color: appColors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Success Icon
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(),
              child: Image.asset('assets/images/Group 1000005716.png'),
            ),
            SizedBox(height: 24.h),

            // Title
            Text(
              'Congratulations!',
              style: Appthemes.textLarge.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: appColors.black,
              ),
            ),
            SizedBox(height: 8.h),

            // Subtitle
            Text(
              'Password Recovered',
              style: Appthemes.textLarge.copyWith(
                fontSize: 15.sp,
                fontFamily: 'popins-bold',
                color: appColors.black,
              ),
            ),
            SizedBox(height: 16.h),

            // Description
            Text(
              'Your password has been recovered. Would youlike to log in or reset your password?',
              textAlign: TextAlign.center,
              style: Appthemes.textSmall.copyWith(color: appColors.grey),
            ),
            SizedBox(height: 32.h),

            // Reset Password Button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  showResetPasswordDialog();
                  // Navigate to reset password screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors.pYellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
                child: Text(
                  'RESET PASSWORD',
                  style: Appthemes.textSmall.copyWith(
                    fontSize: 16.sp,
                    fontFamily: 'popins-bold',
                    color: appColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// RESET PASSWORD DIALOG
class ResetPasswordDialog extends StatefulWidget {
  const ResetPasswordDialog({Key? key}) : super(key: key);

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool hasMinLength = false;
  bool hasNumber = false;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final password = passwordController.text;
    setState(() {
      hasMinLength = password.length >= 8;
      hasNumber = password.contains(RegExp(r'[0-9]'));
    });
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: appColors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 24.sp,
                        color: appColors.black,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Reset Your Password',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: appColors.black,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: appColors.pYellow,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16.sp,
                        color: appColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // Subtitle
              Text(
                'Please enter your new password',
                style: TextStyle(fontSize: 14.sp, color: appColors.grey),
              ),
              SizedBox(height: 24.h),

              // Password Field Label
              Text(
                'Password',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: appColors.black,
                ),
              ),
              SizedBox(height: 8.h),

              // Password TextField
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: TextStyle(color: appColors.grey, fontSize: 16.sp),
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                    child: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: appColors.grey,
                      size: 20.sp,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(
                      color: appColors.grey.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: appColors.pYellow),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Confirm Password Field Label
              Text(
                'Confirm Password',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: appColors.black,
                ),
              ),
              SizedBox(height: 8.h),

              // Confirm Password TextField
              TextField(
                controller: confirmPasswordController,
                obscureText: !isConfirmPasswordVisible,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: TextStyle(color: appColors.grey, fontSize: 16.sp),
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        isConfirmPasswordVisible = !isConfirmPasswordVisible;
                      });
                    },
                    child: Icon(
                      isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: appColors.grey,
                      size: 20.sp,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(
                      color: appColors.grey.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: appColors.pYellow),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Password Requirements
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // At least 8 characters
                  Row(
                    children: [
                      Icon(
                        hasMinLength
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 18.sp,
                        color:
                            hasMinLength
                                ? appColors.black
                                : appColors.grey.withOpacity(.5),
                      ),
                      SizedBox(width: 8.w),
                      SizedBox(
                        width: 220.w,
                        child: Text(
                          maxLines: 2,
                          'Your Password must contain : At least 8 characters',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color:
                                hasMinLength ? appColors.black : appColors.grey,
                            fontWeight:
                                hasMinLength
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // Contains a number
                  Row(
                    children: [
                      Icon(
                        hasNumber
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 18.sp,
                        color:
                            hasNumber
                                ? appColors.black
                                : appColors.grey.withOpacity(.5),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Contains a number',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: hasNumber ? appColors.black : appColors.grey,
                          fontWeight:
                              hasNumber ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 32.h),

              // Done Button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: CustomElevatedButton(
                  borderRadius: 25.r,
                  text: 'DONE',
                  textColor: appColors.white,
                  backgroundColor: appColors.pYellow,
                  isLoading: false, // Shows loading indicator
                  onTap: () {
                    (hasMinLength &&
                            hasNumber &&
                            passwordController.text ==
                                confirmPasswordController.text &&
                            passwordController.text.isNotEmpty)
                        ? () {
                          Get.back();
                          // Handle password reset completion
                          Get.snackbar(
                            'Success',
                            'Password has been reset successfully!',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Color(0xFFF2B342),
                            colorText: Colors.white,
                            duration: const Duration(seconds: 2),
                          );
                        }
                        : null;
                  }, // This won't be called while loading
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// METHOD TO CALL THE RESET PASSWORD DIALOG
void showResetPasswordDialog() {
  Get.dialog(ResetPasswordDialog(), barrierDismissible: false);
}
// METHODS TO CALL THE DIALOGS

void showForgetPasswordDialog() {
  Get.dialog(ForgetPasswordDialog(), barrierDismissible: false);
}

void showCheckPhoneDialog() {
  Get.dialog(CheckPhoneDialog(), barrierDismissible: false);
}

void showPasswordRecoveredDialog() {
  Get.dialog(PasswordRecoveredDialog(), barrierDismissible: false);
}
