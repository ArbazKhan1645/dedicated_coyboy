import 'package:flutter/material.dart';

class SubscriptionManagementScreen extends StatelessWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAF5),
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          'Subscription Management',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.more_vert, color: Colors.black),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Monthly Listing Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF4A5568), width: 1),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF4A5568),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        child: const Text(
                          'Monthly Listing',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        child: Column(
                          children: [
                            SizedBox(height: 8),
                            Text(
                              '\$5.00/ Month',
                              style: TextStyle(
                                color: Color(0xFFFBB040),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'PER PACKAGE',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Want to use what if at discount? Start for \$5.00 annually. Cancel anytime (required or total price of the yearly subscription for a month).',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20),
                            Column(
                              children: [
                                _buildFeatureItem('Post Account Number'),
                                _buildFeatureItem('Watchbox'),
                                _buildFeatureItem('Phone Number'),
                                _buildFeatureItem(
                                  'Active Plan: Monthly Listing',
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFBB040),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  'Continue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  _showCancelDialog(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Color(0xFFE2E8F0)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  'Cancel Membership',
                                  style: TextStyle(
                                    color: Color(0xFF4A5568),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Yearly Listing Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF4A5568), width: 1),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF4A5568),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        child: const Text(
                          'Yearly Listing',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        child: Column(
                          children: [
                            SizedBox(height: 8),
                            Text(
                              '\$5.00/ Month',
                              style: TextStyle(
                                color: Color(0xFFFBB040),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'PER PACKAGE',
                              style: TextStyle(
                                color: Color(0xFFFBB040),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Want to use what if at discount? Start for \$5.00 annually. Cancel anytime (required or total price of the yearly subscription for a month).',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20),
                            Column(
                              children: [
                                _buildFeatureItem('Post Account Number'),
                                _buildFeatureItem('Watchbox'),
                                _buildFeatureItem('Phone Number'),
                                _buildFeatureItem(
                                  'Active Plan: Monthly Listing',
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFBB040),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  'Continue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  _showCancelDialog(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Color(0xFFE2E8F0)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  'Cancel Membership',
                                  style: TextStyle(
                                    color: Color(0xFF4A5568),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade300, // light border
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Color(0xFF364C63),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.white, size: 10),
            ),
            SizedBox(width: 10),
            Text(text, style: TextStyle(color: Colors.black, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.all(0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: EdgeInsets.all(10),
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Red X icon with gray background
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(0xFFD1D5DB), // Gray background like in image
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Color(0xFFEF4444), // Red color for X
                  size: 40,
                ),
              ),
              SizedBox(height: 25),

              // Title text
              Text(
                'Are You Sure You Want To',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 5),
              Text(
                'Cancel Membership',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),

              // Description text
              Text(
                'This action will cancel your current subscription\nand remove associated benefits',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),

              // Buttons
              Column(
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        margin: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: const Color(0xFFFBC65F),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40000000),
                              offset: Offset(0, 4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Yes',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // YES button - Orange
                  SizedBox(height: 12),

                  // Cancel button - Light gray with border
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Color(0xFFF9FAFB), // Very light gray
                        side: BorderSide(
                          color: Color(0xFFE5E7EB), // Light border
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF374151), // Dark gray text
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


}
