import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  static const Color themeColor = Color(0xFFF2B342);
  static const Color primaryText = Color(0xFF2C3E50);
  static const Color secondaryText = Color(0xFF5D6D7E);
  static const Color backgroundColor = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Main Header
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Column(
                children: [
                  const Text(
                    'Privacy Policy for Dedicated Cowboy',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Dedicated Cowboy',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: secondaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Effective Date: July 27, 2025',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: secondaryText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Dedicated Cowboy ("we," "us," or "our") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, store, and share your information when you use our website, mobile app, and related services (collectively, the "Service").',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryText,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'By using the Service, you agree to the practices described in this policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Privacy Policy Sections
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFE5E5E5)),

                  _buildSection(
                    '1. Information We Collect',
                    'We collect limited personal information necessary to operate the platform, including:',
                    extraContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildBulletPoint(
                          'Name and email address when you create an account',
                        ),
                        _buildBulletPoint(
                          'Business information if you create a business listing',
                        ),
                        _buildBulletPoint(
                          'Listing content including photos, descriptions, and location',
                        ),
                        _buildBulletPoint(
                          'IP address and browser data for analytics and security',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'We do not collect or store payment information directly; all transactions are processed securely through Stripe.',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryText,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildSection(
                    '2. How We Use Your Information',
                    'We use your information to:',
                    extraContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildBulletPoint('Create and manage your account'),
                        _buildBulletPoint('Display and promote listings'),
                        _buildBulletPoint('Provide customer support'),
                        _buildBulletPoint('Monitor and improve our Service'),
                        _buildBulletPoint('Enforce our Terms and Conditions'),
                      ],
                    ),
                  ),

                  _buildSection(
                    '3. Cookies and Tracking',
                    'We use cookies to improve user experience and site functionality. Cookies may be used to:',
                    extraContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildBulletPoint('Remember login sessions'),
                        _buildBulletPoint('Store display preferences'),
                        _buildBulletPoint(
                          'Analyze usage via anonymous traffic data',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'You can disable cookies in your browser settings, but some features may not function properly.',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryText,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildSection(
                    '4. Media Uploads',
                    'If you upload images to the site, avoid including embedded location data (EXIF GPS), as this data may be viewable by other users.',
                  ),

                  _buildSection(
                    '5. Embedded Content',
                    'Listings or blog articles may contain embedded content (e.g., videos, maps, social media posts) from other websites. Embedded content behaves the same way as if you visited the originating site directly and may collect user data.',
                  ),

                  _buildSection(
                    '6. Data Sharing',
                    'We do not sell or rent your personal data. We may share your information only in the following situations:',
                    extraContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildBulletPoint(
                          'With third-party service providers (e.g., Stripe, email services) to support platform functionality',
                        ),
                        _buildBulletPoint(
                          'If required by law, legal process, or to protect rights and safety',
                        ),
                      ],
                    ),
                  ),

                  _buildSection(
                    '7. Data Retention',
                    'We retain listing and account information as long as your account is active or as needed to comply with legal obligations. You may request deletion of your account and associated data by contacting us.',
                  ),

                  _buildSection(
                    '8. Your Rights',
                    'You may request to:',
                    extraContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildBulletPoint(
                          'Access the personal data we hold about you',
                        ),
                        _buildBulletPoint('Correct inaccurate information'),
                        _buildBulletPoint(
                          'Delete your data (except where we are legally required to retain it)',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Send all requests to: info@dedicatedcowboy.com',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryText,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildSection(
                    '9. Security',
                    'We implement industry-standard security practices to protect your data. However, no method of transmission over the internet is 100% secure. Use the Service at your own risk.',
                  ),

                  _buildSection(
                    '10. Children\'s Privacy',
                    'Our platform is not intended for users under the age of 18. We do not knowingly collect personal data from children.',
                  ),

                  _buildSection(
                    '11. Changes to This Policy',
                    'We may update this Privacy Policy from time to time. Material changes will be posted on our website. Continued use of the Service after such changes constitutes your agreement to the new policy.',
                  ),

                  _buildSection(
                    '12. Contact Us',
                    '',
                    extraContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildContactItem('Dedicated Cowboy'),
                        _buildContactItem('info@dedicatedcowboy.com'),
                        _buildContactItem('1-877-332-3248 (DC4U)'),
                        _buildContactItem('PO Box 2, Cross Plains, TX 76443'),
                      ],
                    ),
                    isLast: true,
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                '© 2025 Dedicated Cowboy. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    String content, {
    Widget? extraContent,
    bool isLast = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        border:
            isLast
                ? null
                : const Border(
                  bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
                ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryText,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              textAlign: TextAlign.center,
              content,
              style: const TextStyle(
                fontSize: 14,
                color: secondaryText,
                height: 1.5,
              ),
            ),
          ],
          if (extraContent != null) extraContent,
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 14, color: secondaryText, height: 1.5),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: secondaryText,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: secondaryText, height: 1.5),
      ),
    );
  }
}
