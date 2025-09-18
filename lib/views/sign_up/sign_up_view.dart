// views/sign_up/sign_up_view.dart
import 'package:dedicated_cowboy/bottombar/bottom_bar_widegt.dart';
import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/consts/appthemes.dart';
import 'package:dedicated_cowboy/views/privacy/privacy.dart';
import 'package:dedicated_cowboy/views/privacy/terms.dart';
import 'package:dedicated_cowboy/views/sign_in/sign_in_view.dart';
import 'package:dedicated_cowboy/views/sign_up/controller/sign_up_controller.dart';
import 'package:dedicated_cowboy/widgets/custom_elevated_button_widget.dart';
import 'package:dedicated_cowboy/widgets/textfield_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  late final SignUpController controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller
    controller = Get.put(SignUpController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColors.pYellow,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: appColors.transparent,
        automaticallyImplyLeading: true,

        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextButton(
              onPressed: () {
                Get.offAll(() => SignInView());
              },
              child: Text(
                'LOGIN',
                style: Appthemes.textSmall.copyWith(
                  fontFamily: 'popins-bold',
                  color: appColors.black,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        'JOIN',
                        style: Appthemes.textLarge.copyWith(
                          fontFamily: 'popins-bold',
                          fontWeight: FontWeight.bold,
                          fontSize: 32.sp,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Create your account and become part of the Western lifestyle marketplace',
                          textAlign: TextAlign.center,
                          style: Appthemes.textSmall.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  decoration: BoxDecoration(
                    color: appColors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 30,
                    ),
                    child: Column(
                      children: [
                        // Error message display
                        Obx(
                          () =>
                              controller.generalError.value.isNotEmpty
                                  ? Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      border: Border.all(
                                        color: Colors.red.shade200,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.red.shade700,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            controller.generalError.value,
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : const SizedBox.shrink(),
                        ),

                        // First Name Field
                        Obx(
                          () => CustomTextField(
                            labelText: 'Username',
                            required: true,
                            hintText: 'Enter Username',
                            controller: controller.usernameController.value,
                            keyboardType: TextInputType.name,
                            prefixIcon: const Icon(Icons.person_outline),
                            onChanged: (value) {},
                          ),
                        ),
                        const SizedBox(height: 20),

                        // // Last Name Field
                        // Obx(
                        //   () => CustomTextField(
                        //     labelText: 'Last Name',
                        //     hintText: 'Enter your last name',
                        //     controller: controller.lastNameController.value,
                        //     keyboardType: TextInputType.name,

                        //     prefixIcon: const Icon(Icons.person_outline),
                        //     validator:
                        //         (value) =>
                        //             controller.lastNameError.value.isEmpty
                        //                 ? null
                        //                 : controller.lastNameError.value,
                        //     onChanged: (value) {
                        //       if (controller.lastNameError.value.isNotEmpty) {
                        //         controller.lastNameError.value = '';
                        //       }
                        //       if (controller.generalError.value.isNotEmpty) {
                        //         controller.generalError.value = '';
                        //       }
                        //     },
                        //   ),
                        // ),

                        // Email Field
                        Obx(
                          () => CustomTextField(
                            labelText: 'Email Address',
                            required: true,
                            hintText: 'Enter your email address',
                            controller: controller.emailController.value,
                            keyboardType: TextInputType.emailAddress,

                            prefixIcon: const Icon(Icons.email_outlined),
                            validator:
                                (value) =>
                                    controller.emailError.value.isEmpty
                                        ? null
                                        : controller.emailError.value,
                            onChanged: (value) {
                              if (controller.emailError.value.isNotEmpty) {
                                controller.emailError.value = '';
                              }
                              if (controller.generalError.value.isNotEmpty) {
                                controller.generalError.value = '';
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // // Phone Number Field
                        // Obx(
                        //   () => CustomTextField(
                        //     labelText: 'Phone Number',
                        //     hintText: 'Enter your phone number',
                        //     controller: controller.phoneController.value,
                        //     keyboardType: TextInputType.phone,

                        //     prefixIcon: const Icon(Icons.phone_outlined),
                        //     inputFormatters: [PhoneNumberFormatter()],
                        //     validator:
                        //         (value) =>
                        //             controller.phoneError.value.isEmpty
                        //                 ? null
                        //                 : controller.phoneError.value,
                        //     onChanged: (value) {
                        //       if (controller.phoneError.value.isNotEmpty) {
                        //         controller.phoneError.value = '';
                        //       }
                        //       if (controller.generalError.value.isNotEmpty) {
                        //         controller.generalError.value = '';
                        //       }
                        //     },
                        //   ),
                        // ),
                        // const SizedBox(height: 20),

                        // // Facebook Page ID Field (Optional)
                        // Obx(
                        //   () => CustomTextField(
                        //     labelText: 'Facebook Page ID (Optional)',
                        //     hintText: 'Enter your Facebook page ID',
                        //     controller:
                        //         controller.facebookPageIdController.value,
                        //     keyboardType: TextInputType.text,

                        //     prefixIcon: const Icon(Icons.facebook_outlined),
                        //     validator:
                        //         (value) =>
                        //             controller.facebookPageIdError.value.isEmpty
                        //                 ? null
                        //                 : controller.facebookPageIdError.value,
                        //     onChanged: (value) {
                        //       if (controller
                        //           .facebookPageIdError
                        //           .value
                        //           .isNotEmpty) {
                        //         controller.facebookPageIdError.value = '';
                        //       }
                        //       if (controller.generalError.value.isNotEmpty) {
                        //         controller.generalError.value = '';
                        //       }
                        //     },
                        //   ),
                        // ),

                        // Create Password Field
                        Obx(
                          () => CustomTextField(
                            required: true,
                            labelText: 'Create Password',
                            hintText: 'Create a strong password',
                            isPassword: !controller.isPasswordVisible.value,
                            controller: controller.passwordController.value,
                            keyboardType: TextInputType.visiblePassword,

                            prefixIcon: const Icon(Icons.lock_outlined),
                            validator:
                                (value) =>
                                    controller.passwordError.value.isEmpty
                                        ? null
                                        : controller.passwordError.value,
                            onChanged: (value) {
                              if (controller.passwordError.value.isNotEmpty) {
                                controller.passwordError.value = '';
                              }
                              if (controller.generalError.value.isNotEmpty) {
                                controller.generalError.value = '';
                              }
                              // Revalidate confirm password when password changes
                              if (controller
                                  .confirmPasswordController
                                  .value
                                  .text
                                  .isNotEmpty) {
                                if (value !=
                                    controller
                                        .confirmPasswordController
                                        .value
                                        .text) {
                                  controller.confirmPasswordError.value =
                                      'Passwords do not match';
                                } else {
                                  controller.confirmPasswordError.value = '';
                                }
                              }
                            },
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.isPasswordVisible.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: controller.togglePasswordVisibility,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Confirm Password Field
                        Obx(
                          () => CustomTextField(
                            labelText: 'Confirm Password',
                            hintText: 'Confirm your password',
                            isPassword:
                                !controller.isConfirmPasswordVisible.value,
                            controller:
                                controller.confirmPasswordController.value,
                            keyboardType: TextInputType.visiblePassword,

                            prefixIcon: const Icon(Icons.lock_outlined),
                            validator:
                                (value) =>
                                    controller
                                            .confirmPasswordError
                                            .value
                                            .isEmpty
                                        ? null
                                        : controller.confirmPasswordError.value,
                            onChanged: (value) {
                              if (controller
                                  .confirmPasswordError
                                  .value
                                  .isNotEmpty) {
                                controller.confirmPasswordError.value = '';
                              }
                              if (controller.generalError.value.isNotEmpty) {
                                controller.generalError.value = '';
                              }
                              // Real-time password match validation
                              if (value !=
                                  controller.passwordController.value.text) {
                                controller.confirmPasswordError.value =
                                    'Passwords do not match';
                              } else {
                                controller.confirmPasswordError.value = '';
                              }
                            },
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.isConfirmPasswordVisible.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                              ),
                              onPressed:
                                  controller.toggleConfirmPasswordVisibility,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Obx(
                          () => CustomTextField(
                            labelText: 'Facebook Page ID',
                            hintText: 'eg. 2534645746575',
                            controller:
                                controller.facebookpageIdController.value,
                            keyboardType: TextInputType.name,
                            prefixIcon: const Icon(Icons.person_outline),
                            onChanged: (value) {},
                          ),
                        ),
                        SizedBox(height: 10),
                        AgreeCheckBox(
                          value: controller.agreePrivacy.value,
                          text: "I agree to the Privacy Policy",
                          onTapText: () {
                            Get.to(() => const PrivacyPolicyScreen());
                          },
                          onChanged: (val) {
                            setState(
                              () =>
                                  controller.agreePrivacy.value = val ?? false,
                            );
                          },
                        ),
                        AgreeCheckBox(
                          value: controller.agreeTerms.value,
                          text: "I agree with all Terms & Conditions",
                          onTapText: () {
                            Get.to(() => const TermsConditionsScreen());
                            // open Terms page
                          },
                          onChanged: (val) {
                            setState(
                              () => controller.agreeTerms.value = val ?? false,
                            );
                          },
                        ),
                        const SizedBox(height: 30),

                        // JOIN Button
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            height: 55.h,
                            child: CustomElevatedButton(
                              borderRadius: 25.r,
                              text: controller.isLoading.value ? '' : 'JOIN',
                              backgroundColor: appColors.pYellow,
                              textColor: appColors.white,
                              isLoading: controller.isLoading.value,
                              onTap:
                                  controller.isLoading.value
                                      ? null
                                      : controller.signUp,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Terms and Privacy Policy
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'By creating an account, you agree to our Terms of Service and Privacy Policy',
                            textAlign: TextAlign.center,
                            style: Appthemes.textSmall.copyWith(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AgreeCheckBox extends StatelessWidget {
  final bool value;
  final String text;
  final VoidCallback onTapText;
  final ValueChanged<bool?> onChanged;

  const AgreeCheckBox({
    Key? key,
    required this.value,
    required this.text,
    required this.onTapText,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(
          child: Row(
            children: [
              GestureDetector(
                onTap: onTapText,
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
              ),
              Text(
                ' *',
                style: Appthemes.textSmall.copyWith(
                  color: Colors.red,
                  fontSize: 15.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
