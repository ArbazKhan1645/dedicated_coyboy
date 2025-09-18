import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

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
          'Terms & Conditions',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
                  const Text(
                    'Dedicated Cowboy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkBrown,
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Text(
                    'Terms & Conditions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Please read these Terms and Conditions (“Terms”) carefully before using the Dedicated Cowboy website or app (the “Service”) operated by Dedicated Cowboy (“us”, “we”, or “our”). These Terms govern your access to and use of the Service, whether as a visitor, individual user, or business user',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: lightBrown),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'By accessing or using any part of the Service, you agree to be bound by these Terms and our Privacy Policy. If you do not agree, please do not use the Service',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: lightBrown),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Terms and Conditions Sections
            _buildSection(
              '1. Platform Purpose',
              'Dedicated Cowboy is a digital listing platform designed to promote Western goods, services, events, and businesses. We do not process transactions, act as a broker or agent, or participate in the sale or purchase of any listed items.',
            ),

            _buildSection(
              '2. Listing Overview',
              'Dedicated Cowboy allows users to post listings to promote items, services, or events.\n\n'
                  'Listing Fees:\n'
                  '• \$5 for a 30-day listing\n'
                  '• \$50 for a 1-year listing\n\n'
                  'All listings must comply with applicable local, state, and federal laws.\n\n'
                  'We reserve the right to remove any listing that violates these Terms or is inappropriate, offensive, misleading, or fraudulent.',
            ),

            _buildSection(
              '3. Listing Responsibilities',
              'Users must:\n\n'
                  '• Accurately represent their listings\n'
                  '• Hold all required licenses or permits (where applicable)\n'
                  '• Manage all inquiries, customer service, and fulfillment independently\n\n'
                  'Dedicated Cowboy does not guarantee outcomes or visibility of listings and is not responsible for disputes, satisfaction, or transaction issues.',
            ),

            _buildSection(
              '4. Payments',
              'All listing payments are securely processed via Stripe. By making a purchase, you agree to Stripe\'s terms and privacy policy.\n\n'
                  'Payments are non-refundable, except in cases of:\n\n'
                  '• Duplicate charges\n'
                  '• Platform-related technical errors\n'
                  '• Listing removal by us due to Terms violations\n\n'
                  'You are responsible for any applicable taxes or fees related to your purchases.',
            ),

            _buildSection(
              '5. Transactions and User Responsibility',
              'All communication, negotiation, and transactions take place directly between users. Dedicated Cowboy is not a party to any sale.\n\n'
                  'We do not screen or guarantee buyers or sellers and are not liable for:\n\n'
                  '• Off-platform losses\n'
                  '• Fraudulent activity\n'
                  '• Failure to deliver goods or services\n\n'
                  'Use of this platform is at your own risk.',
            ),

            _buildSection(
              '6. User Conduct',
              'By using our Service, you agree to:\n\n'
                  '• Comply with all laws and regulations\n'
                  '• Avoid posting false, misleading, unlawful, or harmful content\n'
                  '• Not impersonate another person or misrepresent yourself\n'
                  '• Not interfere with platform security or functionality\n'
                  '• Not scrape or use automated tools to extract platform data\n\n'
                  'Violation of these rules may result in suspension or removal of your access.',
            ),

            _buildSection(
              '7. Intellectual Property',
              'All content on the platform, excluding user-generated listings, is owned by Dedicated Cowboy or its licensors.\n\n'
                  'By submitting a listing, you grant us a non-exclusive, royalty-free license to use, display, and promote your content.',
            ),

            _buildSection(
              '8. Limitation of Liability',
              'To the fullest extent allowed by law, Dedicated Cowboy is not liable for any indirect, incidental, or consequential damages related to:\n\n'
                  '• Use or inability to use the Service\n'
                  '• Third-party actions or content\n'
                  '• Listing inaccuracies\n'
                  '• Unauthorized access to your data\n\n'
                  'Your sole remedy for dissatisfaction is to discontinue use of the Service.',
            ),

            _buildSection(
              '9. Indemnification',
              'You agree to defend and indemnify Dedicated Cowboy and its affiliates from any claims, damages, or expenses arising from:\n\n'
                  '• Your use of the platform\n'
                  '• Your violation of these Terms\n'
                  '• Your infringement of any laws or third-party rights',
            ),

            _buildSection(
              '10. Termination',
              'We may suspend or terminate your access at any time, without notice, for conduct that violates these Terms or harms the platform or its users.\n\n'
                  'Provisions that survive termination include ownership rights, disclaimers, indemnities, and limitations of liability.',
            ),

            _buildSection(
              '11. Modifications',
              'We may update these Terms at any time. Significant changes will be communicated on the platform or via email. Continued use of the Service after changes implies acceptance.',
            ),

            _buildSection(
              '12. Governing Law',
              'These Terms are governed by the laws of the State of Texas. Any legal disputes shall be resolved in state or federal courts located in Texas.',
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
                        '13. Contact Us',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkBrown,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    Icons.email_rounded,
                    'info@dedicatedcowboy.com',
                  ),
                  _buildContactItem(Icons.phone_rounded, '877-332-3248 (DC4U)'),
                  _buildContactItem(
                    Icons.location_on_rounded,
                    'PO Box 2, Cross Plains, TX 86443',
                  ),
                ],
              ),
            ),

            // Acceptance Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeColor.withOpacity(0.5),
                  width: 2,
                ),
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
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: themeColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '14. Acceptance of Terms',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkBrown,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'By using Dedicated Cowboy, you confirm that you have read, understood, and agree to these Terms and our Privacy Policy.',
                    style: TextStyle(fontSize: 15, color: lightBrown),
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
