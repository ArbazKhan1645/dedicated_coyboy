import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:flutter/material.dart';

class FeatureWidget extends StatelessWidget {
  const FeatureWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFfaf5ef), // Light cream background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 15),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  color: Color(0xFF4A5568), // Darker gray text
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: "Join Dedicated Cowboy for just\n",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'popins',
                      fontWeight: FontWeight.w200,
                      color: appColors.darkBlue,
                    ),
                  ),
                  TextSpan(
                    text: "\$5/month",
                    style: TextStyle(
                      fontFamily: 'popins',
                      fontWeight: FontWeight.bold,
                      color: appColors.darkBlue,
                    ),
                  ),
                  const TextSpan(text: " or "),
                  TextSpan(
                    text: "\$50/year",
                    style: TextStyle(
                      fontFamily: 'popins',
                      fontWeight: FontWeight.bold,
                      color: appColors.darkBlue,
                    ),
                  ),
                  TextSpan(
                    text:
                        " and get\naccess to the heart of the\nWestern World.",
                    style: TextStyle(
                      fontFamily: 'popins',
                      fontSize: 16,
                      fontWeight: FontWeight.w200,
                      color: appColors.darkBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Light divider line
            Container(
              width: double.infinity,
              height: 1,
              color: const Color(0xFFE2E8F0),
              margin: const EdgeInsets.symmetric(vertical: 16),
            ),
            Text(
              "As a Dedicated Cowboy, you can do\nall three:",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'popins',
                fontSize: 16,
                fontWeight: FontWeight.w200,
                color: appColors.darkBlue,
              ),
            ),
            const SizedBox(height: 25),
            _buildBulletPoint(
              "List your items for sale",
              "— from boots and buckles to home décor and tack.",
            ),
            const SizedBox(height: 16),
            _buildBulletPoint(
              "Promote your business",
              "— whether you run a boutique, ranch service, or western retail shop.",
            ),
            const SizedBox(height: 16),
            _buildBulletPoint(
              "Post your events",
              "— from jackpots and rodeos to barrel races and clinics, complete with maps and details.",
            ),
            const SizedBox(height: 32),
            // Bottom section with different background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFf6f0d9,
                ), // Slightly darker background for bottom section
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "It's simple, affordable, and\nmade for folks who live the\nDedicated Cowboy way.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'popins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: appColors.darkBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF4A5568), width: 2),
          ),
          child: const Icon(Icons.check, color: Color(0xFF4A5568), size: 14),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 15,
                fontFamily: 'popins',
                height: 1.4,
                color: Color(0xFF4A5568),
              ),
              children: [
                TextSpan(
                  text: title,
                  style: TextStyle(
                    fontFamily: 'popins-bold',
                    fontWeight: FontWeight.bold,
                    color: appColors.darkBlue,
                  ),
                ),
                const TextSpan(text: " "),
                TextSpan(
                  text: description,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'popins',
                    fontWeight: FontWeight.w200,
                    color: appColors.darkBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
