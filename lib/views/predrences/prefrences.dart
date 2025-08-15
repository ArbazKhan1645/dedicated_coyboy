import 'package:flutter/material.dart';

class PreferenceScreen extends StatelessWidget {
  const PreferenceScreen({super.key});

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
        title: const Text(
          'Preference',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Icon(Icons.more_vert, color: Colors.black),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Display Email on Author Page',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const _CustomRadioTile(
              title: 'Display to Everyone',
              selected: true,
            ),
            const SizedBox(height: 10),
            const _CustomRadioTile(title: 'Display to logged in user only'),
            const SizedBox(height: 10),
            const _CustomRadioTile(title: "Don't Display"),
            const SizedBox(height: 24),
            const Text(
              'Contact Listing Owner Form Reciept',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const _CustomRadioTile(title: 'Author Email', selected: true),
            const SizedBox(height: 10),
            const _CustomRadioTile(title: "Listing's emails"),
            const SizedBox(height: 16),
            Row(
              children: [
                Switch(
                  padding: EdgeInsets.all(0),
                  value: false,
                  onChanged: (_) {},
                  activeColor: Colors.black,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Hide contact form in my listings',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
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
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _CustomRadioTile extends StatelessWidget {
  final String title;
  final bool selected;
  const _CustomRadioTile({required this.title, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black54),
          ),
          child:
              selected
                  ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2D3D53),
                      ),
                    ),
                  )
                  : null,
        ),
        Text(title, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
