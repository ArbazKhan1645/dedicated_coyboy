import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

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
          'Terms & Conditions',
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
                    'Terms and Conditions',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                      letterSpacing: -0.5,
                    ),
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
                    'Terms and\nConditions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: secondaryText,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Please read these Terms and Conditions ("Terms") carefully before using the Dedicated Cowboy website or app (the "Service") operated by Dedicated Cowboy ("us", "we", or "our"). These Terms govern your access to and use of the Service, whether as a visitor, individual user, or business user.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryText,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'By accessing or using any part of the Service, you agree to be bound by these Terms and our Privacy Policy. If you do not agree, please do not use the Service.',
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

            // Terms Sections
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFE5E5E5)),

                  _buildSection(
                    '1. Platform Purpose',
                    'Dedicated Cowboy is a digital listing platform designed to promote Western goods, services, events, and businesses. We do not process transactions, act as a broker or agent, or participate in the sale or purchase of any listed items.',
                  ),

                  _buildSection(
                    '2. Listing Overview',
                    'Dedicated Cowboy allows users to post listings to promote items, services, or events.',
                    extraContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Listing Fees:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBulletPoint('\$5 for a 30-day listing'),
                        _buildBulletPoint('\$50 for a 1-year listing'),
                        const SizedBox(height: 16),
                        const Text(
                          'All listings must comply with applicable local, state, and federal laws.',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryText,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'We reserve the right to remove any listing that violates these Terms or is inappropriate, offensive, misleading, or fraudulent.',
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
                    '3. Listing Responsibilities',
                    'Users must:',
                    extraContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildBulletPoint(
                          'Accurately represent their listings',
                        ),
                        _buildBulletPoint(
                          'Hold all required licenses or permits (where applicable)',
                        ),
                        _buildBulletPoint(
                          'Manage all inquiries, customer service, and fulfillment independently',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Dedicated Cowboy does not guarantee outcomes or visibility of listings and is not responsible for disputes, satisfaction, or transaction issues.',
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
                    '4. Payments',
                    'All listing payments are securely processed via Stripe. By making a purchase, you agree to Stripe\'s terms and privacy policy.',
                    extraContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Payments are non-refundable, except in cases of:',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryText,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBulletPoint('Duplicate charges'),
                        _buildBulletPoint('Platform-related technical errors'),
                        _buildBulletPoint(
                          'Listing removal by us due to Terms violations',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'You are responsible for any applicable taxes or fees related to your purchases.',
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
                    '5. Transactions and User Responsibility',
                    'All communication, negotiation, and transactions take place directly between users. Dedicated Cowboy is not a party to any sale.',
                    extraContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'We do not screen or guarantee buyers or sellers and are not liable for:',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryText,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBulletPoint('Off-platform losses'),
                        _buildBulletPoint('Fraudulent activity'),
                        _buildBulletPoint(
                          'Failure to deliver goods or services',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Use of this platform is at your own risk.',
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
                    '6. User Conduct',
                    'By using our Service, you agree to:',
                    extraContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildBulletPoint(
                          'Comply with all laws and regulations',
                        ),
                        _buildBulletPoint(
                          'Avoid posting false, misleading, unlawful, or harmful content',
                        ),
                        _buildBulletPoint(
                          'Not impersonate another person or misrepresent yourself',
                        ),
                        _buildBulletPoint(
                          'Not interfere with platform security or functionality',
                        ),
                        _buildBulletPoint(
                          'Not scrape or use automated tools to extract platform data',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Violation of these rules may result in suspension or removal of your access.',
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
                    '7. Intellectual Property',
                    'All content on the platform, excluding user-generated listings, is owned by Dedicated Cowboy or its licensors.',
                    extraContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'By submitting a listing, you grant us a non-exclusive, royalty-free license to use, display, and promote your content.',
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
                    '8. Limitation of Liability',
                    'To the fullest extent allowed by law, Dedicated Cowboy is not liable for any indirect, incidental, or consequential damages related to:',
                    extraContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildBulletPoint(
                          'Use or inability to use the Service',
                        ),
                        _buildBulletPoint('Third-party actions or content'),
                        _buildBulletPoint('Listing inaccuracies'),
                        _buildBulletPoint('Unauthorized access to your data'),
                        const SizedBox(height: 16),
                        const Text(
                          'Your sole remedy for dissatisfaction is to discontinue use of the Service.',
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
                    '9. Indemnification',
                    'You agree to defend and indemnify Dedicated Cowboy and its affiliates from any claims, damages, or expenses arising from:',
                    extraContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildBulletPoint('Your use of the platform'),
                        _buildBulletPoint('Your violation of these Terms'),
                        _buildBulletPoint(
                          'Your infringement of any laws or third-party rights',
                        ),
                      ],
                    ),
                  ),

                  _buildSection(
                    '10. Termination',
                    'We may suspend or terminate your access at any time, without notice, for conduct that violates these Terms or harms the platform or its users.',
                    extraContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Provisions that survive termination include ownership rights, disclaimers, indemnities, and limitations of liability.',
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
                    '11. Modifications',
                    'We may update these Terms at any time. Significant changes will be communicated on the platform or via email. Continued use of the Service after changes implies acceptance.',
                  ),

                  _buildSection(
                    '12. Governing Law',
                    'These Terms are governed by the laws of the State of Texas. Any legal disputes shall be resolved in state or federal courts located in Texas.',
                  ),

                  _buildSection(
                    '13. Contact Us',
                    '',
                    extraContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildContactItem('info@dedicatedcowboy.com'),
                        _buildContactItem('877-332-3248 (DC4U)'),
                        _buildContactItem('PO Box 2, Cross Plains, TX 86443'),
                      ],
                    ),
                  ),

                  _buildSection(
                    '14. Acceptance of Terms',
                    'By using Dedicated Cowboy, you confirm that you have read, understood, and agree to these Terms and our Privacy Policy.',
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryText,
              letterSpacing: -0.2,
            ),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
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
