import 'package:dedicated_cowboy/consts/appColors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';

class AddItemButton extends StatelessWidget {
  const AddItemButton({super.key, required this.text, required this.ontap});
  final text;
  final Callback ontap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ontap();
      },
      child: Center(
        child: SizedBox(
          height: 60,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main orange button
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3B340), // Orange color
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(left: 45, right: 20),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              // Overlapping circular back arrow
              Positioned(
                left: -5,
                top: -4,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                    shape: BoxShape.circle,
                    color: appColors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Container(
                      height: 65.h,
                      width: 65.w,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: appColors.darkBlue.withOpacity(.2),
                          width: 1,
                        ),
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Color(0xFFFFC043),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
