import 'package:flutter/material.dart';

class FeatureWidget extends StatelessWidget {
  const FeatureWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xffD9D9D9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(color: Colors.black, fontSize: 16),
                children: [
                  const TextSpan(text: "Join Dedicated Cowboy for just "),
                  TextSpan(
                    text: "\$5/month",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: " or "),
                  TextSpan(
                    text: "\$50/year",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text: " and get access to the heart of the Western World.",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "As a Dedicated Cowboy , you can do all three:",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            _buildBulletPoint(
              "List your items for sale — from boots and buckles to home décor and tack",
            ),
            _buildBulletPoint(
              "Promote your business — whether you run a boutique, ranch service, or western retail shop.",
            ),
            _buildBulletPoint(
              "Post your events — from jackpots and rodeos to barrel races and clinics, complete with maps and details.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF2C3E50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
