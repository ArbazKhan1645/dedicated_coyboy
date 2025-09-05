// my_reports_screen.dart
import 'package:dedicated_cowboy/app/models/report_model/report_model.dart';
import 'package:dedicated_cowboy/views/reports/service.dart';
import 'package:dedicated_cowboy/views/reports/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final ReportService _reportService = ReportService.instance;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Reports',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ReportModel>>(
        stream: _reportService.getUserReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2B342)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                  SizedBox(height: 16.h),
                  Text(
                    'Error loading reports',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Please try again later',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF2B342),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.report_outlined,
                    size: 64.sp,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No Reports Yet',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'You haven\'t submitted any reports',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: report.status.color,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                report.status.icon,
                                size: 14.sp,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                report.status.displayName,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatDate(report.createdAt),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // Listing info
                    Row(
                      children: [
                        Container(
                          width: 50.w,
                          height: 50.w,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child:
                              report.listingImage != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: Image.network(
                                      report.listingImage!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey[400],
                                          size: 20.sp,
                                        );
                                      },
                                    ),
                                  )
                                  : Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey[400],
                                    size: 20.sp,
                                  ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.listingName,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: _getListingTypeColor(
                                    report.listingType,
                                  ),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  report.listingType,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // Report reason
                    Text(
                      'Reason: ${report.reason}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),

                    if (report.customReason != null) ...[
                      SizedBox(height: 6.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          report.customReason!,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],

                    // Admin response if available
                    if (report.adminResponse != null) ...[
                      SizedBox(height: 12.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.admin_panel_settings,
                                  size: 16.sp,
                                  color: Colors.blue[700],
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'Admin Response:',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              report.adminResponse!,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Resolution date if resolved
                    if (report.resolvedAt != null) ...[
                      SizedBox(height: 8.h),
                      Text(
                        'Resolved: ${_formatDate(report.resolvedAt!)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getListingTypeColor(String type) {
    switch (type) {
      case 'Item':
        return Color(0xFFF2B342);
      case 'Business':
        return Colors.blue;
      case 'Event':
        return Colors.tealAccent;
      default:
        return Colors.grey;
    }
  }
}

class ReportButton extends StatefulWidget {
  final String listingId;
  final String listingType;
  final String listingName;
  final String? listingImage;
  final double size;
  final Color? color;
  final bool showText;
  final String? customText;

  const ReportButton({
    super.key,
    required this.listingId,
    required this.listingType,
    required this.listingName,
    this.listingImage,
    this.size = 24.0,
    this.color,
    this.showText = false,
    this.customText,
  });

  @override
  State<ReportButton> createState() => _ReportButtonState();
}

class _ReportButtonState extends State<ReportButton> {
  final ReportService _reportService = ReportService.instance;
  bool _hasReported = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkReportStatus();
  }

  Future<void> _checkReportStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hasReported = await _reportService.hasUserReportedListing(
        widget.listingId,
      );
      if (mounted) {
        setState(() {
          _hasReported = hasReported;
        });
      }
    } catch (e) {
      print('Error checking report status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onReportPressed() {
    if (_hasReported) {
      _showAlreadyReportedDialog();
    } else {
      Get.to(
        () => ReportListingScreen(
          listingId: widget.listingId,
          listingType: widget.listingType,
          listingName: widget.listingName,
          listingImage: widget.listingImage,
        ),
      )?.then((_) {
        _checkReportStatus();
      });
    }
  }

  void _showAlreadyReportedDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.verified,
              color: Color(0xFFF2B342).withOpacity(0.6),
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Already Reported',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        content: Text(
          'You have already reported this listing. Our team is reviewing your report.',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              Get.to(() => MyReportsScreen());
            },
            child: Text(
              'View My Reports',
              style: TextStyle(
                color: Color(0xFFF2B342),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'OK',
              style: TextStyle(
                color: Color(0xFFF2B342),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show simple placeholder while loading
    if (_isLoading) {
      return Container(
        height: widget.showText ? 36.h : widget.size,
        width: widget.showText ? 80.w : widget.size,
        child: Center(
          child: SizedBox(
            width: 16.w,
            height: 16.h,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
            ),
          ),
        ),
      );
    }

    // If already reported, show elegant success state
    if (_hasReported) {
      return Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.showText ? 16.w : 12.w,
            vertical: widget.showText ? 10.h : 8.h,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF2B342),
                const Color.fromARGB(255, 2, 65, 136)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(widget.showText ? 25.r : 12.r),
            border: Border.all(color: Color(0xFFF2B342), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFF2B342).withOpacity(0.15),
                blurRadius: 8,
                offset: Offset(0, 2),
                spreadRadius: 1,
              ),
            ],
          ),
          child:
              widget.showText
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        size: widget.size * 0.8,
                        color: Color(0xFFF2B342),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        widget.customText ?? 'Reported',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF2B342),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  )
                  : Icon(
                    Icons.verified,
                    size: widget.size,
                    color: Color(0xFFF2B342),
                  ),
        ),
      );
    }

    // Default report button - elegant text button
    return GestureDetector(
      onTap: _onReportPressed,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child:
            widget.showText
                ? Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(25.r),
                    border: Border.all(color: Colors.red[300]!, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: widget.size * 0.8,
                        color: Colors.red[600],
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        widget.customText ?? 'Report',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[600],
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                )
                : Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.flag_outlined,
                    size: widget.size,
                    color: widget.color ?? Colors.red[600],
                  ),
                ),
      ),
    );
  }
}

// USAGE EXAMPLES:

// 1. Simple icon button for detail screens:
/*
ReportButton(
  listingId: product.id ?? '',
  listingType: 'Item',
  listingName: product.itemName ?? 'Unnamed Item',
  listingImage: product.photoUrls?.first,
),
*/

// 2. Text button for cards or lists:
/*
ReportButton(
  listingId: business.id ?? '',
  listingType: 'Business',  
  listingName: business.businessName ?? 'Unnamed Business',
  listingImage: business.photoUrls?.first,
  showText: true,
  size: 16,
),
*/

// 3. Custom styled button:
/*
ReportButton(
  listingId: event.id ?? '',
  listingType: 'Event',
  listingName: event.eventName ?? 'Unnamed Event', 
  listingImage: event.photoUrls?.first,
  showText: true,
  customText: 'Report Event',
  size: 18,
  color: Colors.orange,
),
*/

// 4. To add in your ProductCard Stack:
/*
Positioned(
  top: 8,
  left: 40,
  child: ReportButton(
    listingId: widget.listingWrapper.id ?? '',
    listingType: widget.listingWrapper.type,
    listingName: widget.listingWrapper.name ?? 'Unnamed ${widget.listingWrapper.type}',
    listingImage: widget.listingWrapper.photoUrls?.first,
  ),
),
*/

// 5. For detail screens AppBar actions:
/*
actions: [
  ReportButton(
    listingId: widget.product.id ?? '',
    listingType: 'Item',
    listingName: widget.product.itemName ?? 'Unnamed Item',
    listingImage: widget.product.photoUrls?.first,
  ),
  SizedBox(width: 8),
  IconButton(
    icon: Icon(Icons.search, color: Colors.black),
    onPressed: () {},
  ),
],
*/
