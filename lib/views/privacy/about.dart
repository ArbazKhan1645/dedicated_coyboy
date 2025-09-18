import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

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
          'About Us',
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
                    'About Dedicated Cowboy',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Discover the journey behind Dedicated Cowboy and our mission to serve the western community',
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

            // About Sections
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFE5E5E5)),

                  // Founder Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'From Founder & CEO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Founder info and image
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Founder image
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: themeColor.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: Image.network(
                                  'https://dedicatedcowboy.com/wp-content/uploads/2024/04/Screenshot-2024-04-03-at-1.47.54-PM-935x1024.png',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: themeColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: themeColor,
                                        size: 40,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Founder name and title
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Chelle Allen',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: primaryText,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Founder & CEO',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: secondaryText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Founder story
                        const Text(
                          'I faced the challenging decision of what to wear to my father-in-law\'s Hall of Fame induction, as my reliable Double D had become vintage. After searching through various online platforms like Ebay, PoshMark, and Etsy, as well as cute boutiques, I realized there was no single site that catered to all things western. This realization led to the creation of Dedicated Cowboy.',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryText,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Countless prayers, hours of hard work, and numerous conversations have gone into bringing Dedicated Cowboy to life. We are still in the early stages, but our goal is to serve the entire western community by providing a platform for buying, selling, promoting, and offering ranch-related services and products.',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryText,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'I firmly believe that Dedicated Cowboy will have a significant impact on the western world, offering an economical, user-friendly, simple, and enjoyable experience. Thank you for being a part of Dedicated Cowboy.',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryText,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Mission Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Our Mission',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'To serve the entire western community by providing a comprehensive platform for buying, selling, promoting, and offering ranch-related services and products.',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryText,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Values Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Our Values',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildValueItem(
                          'Economical',
                          'Affordable solutions for the western community',
                        ),
                        _buildValueItem(
                          'User-Friendly',
                          'Simple and intuitive platform design',
                        ),
                        _buildValueItem(
                          'Simple',
                          'Easy-to-use interface for all users',
                        ),
                        _buildValueItem(
                          'Enjoyable',
                          'Making western commerce fun and engaging',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Thank you message and footer
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: themeColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Thank you for being part of our journey',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '© 2025 Dedicated Cowboy. All rights reserved.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: secondaryText,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
