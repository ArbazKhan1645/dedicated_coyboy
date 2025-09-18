import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

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
          'About Us',
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
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeColor.withOpacity(0.15),
                    themeColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: themeColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'About Dedicated Cowboy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkBrown,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Discover the journey behind Dedicated Cowboy and our mission to serve the western community',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: lightBrown),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Founder Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Founder Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.08),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From Founder & CEO',
                              style: TextStyle(
                                fontSize: 14,
                                color: lightBrown,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Chelle Allen',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: darkBrown,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Founder Content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Founder Image Placeholder
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: themeColor.withOpacity(0.3),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.network(
                              'https://dedicatedcowboy.com/wp-content/uploads/2024/04/Screenshot-2024-04-03-at-1.47.54-PM-935x1024.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),

                          // Replace this container with:
                        ),

                        const SizedBox(height: 24),

                        // Founder Story
                        const Text(
                          'I faced the challenging decision of what to wear to my father-in-law\'s Hall of Fame induction, as my reliable Double D had become vintage. After searching through various online platforms like Ebay, PoshMark, and Etsy, as well as cute boutiques, I realized there was no single site that catered to all things western. This realization led to the creation of Dedicated Cowboy.',
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.justify,
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Countless prayers, hours of hard work, and numerous conversations have gone into bringing Dedicated Cowboy to life. We are still in the early stages, but our goal is to serve the entire western community by providing a platform for buying, selling, promoting, and offering ranch-related services and products.',
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.justify,
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'I firmly believe that Dedicated Cowboy will have a significant impact on the western world, offering an economical, user-friendly, simple, and enjoyable experience. Thank you for being a part of Dedicated Cowboy.',
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.justify,
                        ),

                        const SizedBox(height: 24),

                        // Signature
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: themeColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Chelle Allen',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: darkBrown,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'Founder & CEO',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: lightBrown,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Mission Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag_rounded, color: themeColor, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Our Mission',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkBrown,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'To serve the entire western community by providing a comprehensive platform for buying, selling, promoting, and offering ranch-related services and products.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Values Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: themeColor, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Our Values',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkBrown,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildValueItem(
                    Icons.monetization_on_rounded,
                    'Economical',
                    'Affordable solutions for the western community',
                  ),
                  _buildValueItem(
                    Icons.phone_android_rounded,
                    'User-Friendly',
                    'Simple and intuitive platform design',
                  ),
                  _buildValueItem(
                    Icons.lightbulb_rounded,
                    'Simple',
                    'Easy-to-use interface for all users',
                  ),
                  _buildValueItem(
                    Icons.sentiment_very_satisfied_rounded,
                    'Enjoyable',
                    'Making western commerce fun and engaging',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Footer
            Center(
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkBrown,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '© 2025 Dedicated Cowboy. All rights reserved.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildValueItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
