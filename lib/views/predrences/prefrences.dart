import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum EmailDisplayOption { everyone, loggedInOnly, dontDisplay }

enum ContactFormReceipt { authorEmail, listingEmails }

class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key});

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  EmailDisplayOption _emailDisplayOption = EmailDisplayOption.everyone;
  ContactFormReceipt _contactFormReceipt = ContactFormReceipt.authorEmail;
  bool _hideContactForm = false;
  bool _isLoading = true;
  bool _isSaving = false;

  // SharedPreferences keys
  static const String _emailDisplayKey = 'email_display_option';
  static const String _contactFormReceiptKey = 'contact_form_receipt';
  static const String _hideContactFormKey = 'hide_contact_form';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        // Load email display option
        final emailDisplayIndex = prefs.getInt(_emailDisplayKey) ?? 0;
        _emailDisplayOption = EmailDisplayOption.values[emailDisplayIndex];

        // Load contact form receipt option
        final contactFormReceiptIndex =
            prefs.getInt(_contactFormReceiptKey) ?? 0;
        _contactFormReceipt =
            ContactFormReceipt.values[contactFormReceiptIndex];

        // Load hide contact form toggle
        _hideContactForm = prefs.getBool(_hideContactFormKey) ?? false;

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load preferences');
    }
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        prefs.setInt(_emailDisplayKey, _emailDisplayOption.index),
        prefs.setInt(_contactFormReceiptKey, _contactFormReceipt.index),
        prefs.setBool(_hideContactFormKey, _hideContactForm),
      ]);

      _showSuccessSnackBar('Preferences saved successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to save preferences');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _getEmailDisplayTitle(EmailDisplayOption option) {
    switch (option) {
      case EmailDisplayOption.everyone:
        return 'Display to Everyone';
      case EmailDisplayOption.loggedInOnly:
        return 'Display to logged in user only';
      case EmailDisplayOption.dontDisplay:
        return "Don't Display";
    }
  }

  String _getContactFormReceiptTitle(ContactFormReceipt option) {
    switch (option) {
      case ContactFormReceipt.authorEmail:
        return 'Author Email';
      case ContactFormReceipt.listingEmails:
        return "Listing's emails";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAF5),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D3D53)),
          ),
        ),
      );
    }

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
            ...EmailDisplayOption.values.map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CustomRadioTile(
                  title: _getEmailDisplayTitle(option),
                  selected: _emailDisplayOption == option,
                  onTap: () {
                    setState(() {
                      _emailDisplayOption = option;
                    });
                  },
                ),
              );
            }),
            const SizedBox(height: 24),
            const Text(
              'Contact Listing Owner Form Receipt',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...ContactFormReceipt.values.map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CustomRadioTile(
                  title: _getContactFormReceiptTitle(option),
                  selected: _contactFormReceipt == option,
                  onTap: () {
                    setState(() {
                      _contactFormReceipt = option;
                    });
                  },
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              children: [
                Switch(
                  value: _hideContactForm,
                  onChanged: (value) {
                    setState(() {
                      _hideContactForm = value;
                    });
                  },
                  activeColor: const Color(0xFF2D3D53),
                  activeTrackColor: const Color(0xFF2D3D53).withOpacity(0.3),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey.withOpacity(0.3),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Hide contact form in my listings',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: _isSaving ? null : _savePreferences,
              child: Container(
                width: double.infinity,
                height: 48,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    8,
                  ), // More rectangular, less rounded
                  color:
                      _isSaving
                          ? const Color(0xFF4A5568).withOpacity(
                            0.6,
                          ) // Darker gray when saving
                          : const Color(
                            0xFF364C63,
                          ), // Dark blue-gray background
                  // Removed box shadow for flatter appearance
                ),
                child: Center(
                  child:
                      _isSaving
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600, // Slightly less bold
                              fontSize: 16,
                            ),
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomRadioTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback? onTap;

  const CustomRadioTile({
    super.key,
    required this.title,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? const Color(0xFF2D3D53) : Colors.black54,
                width: selected ? 2 : 1,
              ),
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
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: selected ? const Color(0xFF2D3D53) : Colors.black,
                fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
