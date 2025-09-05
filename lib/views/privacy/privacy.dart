import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  static const Color themeColor = Color(0xFFF2B342);
  static const Color darkBrown = Colors.black;
  static const Color lightBrown = Colors.black;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAF5),
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
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.security_rounded, size: 48, color: themeColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Dedicated Cowboy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Effective Date: July 27, 2025',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: darkBrown,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'We are committed to protecting your privacy. This policy explains how we collect, use, store, and share your information.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: lightBrown),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Privacy Policy Sections
            _buildSection(
              '1. Information We Collect',
              'We collect limited personal information necessary to operate the platform, including:\n\n'
                  '• Name and email address when you create an account\n'
                  '• Business information if you create a business listing\n'
                  '• Listing content including photos, descriptions, and location\n'
                  '• IP address and browser data for analytics and security\n\n'
                  'We do not collect or store payment information directly; all transactions are processed securely through Stripe.',
            ),

            _buildSection(
              '2. How We Use Your Information',
              'We use your information to:\n\n'
                  '• Create and manage your account\n'
                  '• Display and promote listings\n'
                  '• Provide customer support\n'
                  '• Monitor and improve our Service\n'
                  '• Enforce our Terms and Conditions',
            ),

            _buildSection(
              '3. Cookies and Tracking',
              'We use cookies to improve user experience and site functionality. Cookies may be used to:\n\n'
                  '• Remember login sessions\n'
                  '• Store display preferences\n'
                  '• Analyze usage via anonymous traffic data\n\n'
                  'You can disable cookies in your browser settings, but some features may not function properly.',
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
              'We do not sell or rent your personal data. We may share your information only in the following situations:\n\n'
                  '• With third-party service providers (e.g., Stripe, email services) to support platform functionality\n'
                  '• If required by law, legal process, or to protect rights and safety',
            ),

            _buildSection(
              '7. Data Retention',
              'We retain listing and account information as long as your account is active or as needed to comply with legal obligations. You may request deletion of your account and associated data by contacting us.',
            ),

            _buildSection(
              '8. Your Rights',
              'You may request to:\n\n'
                  '• Access the personal data we hold about you\n'
                  '• Correct inaccurate information\n'
                  '• Delete your data (except where we are legally required to retain it)\n\n'
                  'Send all requests to: info@dedicatedcowboy.com',
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

            // Contact Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeColor.withOpacity(0.1),
                    themeColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: themeColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.contact_support_rounded,
                        color: themeColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '12. Contact Us',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkBrown,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(Icons.business_rounded, 'Dedicated Cowboy'),
                  _buildContactItem(
                    Icons.email_rounded,
                    'info@dedicatedcowboy.com',
                  ),
                  _buildContactItem(
                    Icons.phone_rounded,
                    '1-877-332-3248 (DC4U)',
                  ),
                  _buildContactItem(
                    Icons.location_on_rounded,
                    'PO Box 2, Cross Plains, TX 76443',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Footer
            Center(
              child: Text(
                '© 2025 Dedicated Cowboy. All rights reserved.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: darkBrown,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 12, color: lightBrown),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: lightBrown),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: darkBrown,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
