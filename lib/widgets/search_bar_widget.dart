import 'package:dedicated_cowboy/consts/appColors.dart';
import 'package:dedicated_cowboy/consts/appthemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSearchTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final String hintText;
  final bool enabled;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.onSearchTap,
    this.onChanged,
    this.onSubmitted,
    this.hintText = 'Search Listings',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: appColors.grey.withOpacity(.2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        onChanged: onChanged,
        onSubmitted: (value) {
          if (onSubmitted != null) {
            onSubmitted!();
          }
        },
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: Appthemes.textSmall.copyWith(
            color: Colors.grey[600],
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: GestureDetector(
            onTap: onSearchTap,
            child: Icon(Icons.search, color: appColors.black, size: 24.sp),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.black87,
        ),
      ),
    );
  }
}
