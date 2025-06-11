import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  Future<void> _refreshPage() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final double padding = MediaQuery.of(context).size.width * 0.04;
    final double spacing = MediaQuery.of(context).size.height * 0.02;
    final double fontSizeTitle = MediaQuery.of(context).size.width * 0.045;
    final double fontSizeBody = MediaQuery.of(context).size.width * 0.035;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C8A7B),
        title: Text(
          'Frequently Asked Questions',
          style: GoogleFonts.nunitoSans(
            fontSize: MediaQuery.of(context).size.width * 0.05,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20.0),
            bottomRight: Radius.circular(20.0),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshPage,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ExpansionTile(
                    title: Text(
                      'How do I add a new product?',
                      style: GoogleFonts.nunitoSans(
                        fontSize: fontSizeTitle,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
                        child: Text(
                          'To add a new product, tap on the "Add" icon in the Bottom Navigation Bar. This will open the Add Product page. Enter the product details (name, description, price, images) and tap "Save". The product will be uploaded and displayed on your page.',
                          style: GoogleFonts.nunitoSans(
                            fontSize: fontSizeBody,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text(
                      'How can I view my orders?',
                      style: GoogleFonts.nunitoSans(
                        fontSize: fontSizeTitle,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
                        child: Text(
                          'Tap on the "Order" icon in the Bottom Navigation Bar. You’ll see a list of all the orders you’ve received. You can tap on any order to view its details and update its status (e.g., mark it as "Delivered").',
                          style: GoogleFonts.nunitoSans(
                            fontSize: fontSizeBody,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text(
                      'How do I edit my profile information?',
                      style: GoogleFonts.nunitoSans(
                        fontSize: fontSizeTitle,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
                        child: Text(
                          'Go to the "Profile" page from the Bottom Navigation Bar (person icon). You’ll see your Page. Tap on "Your Name", choose the Profile item , update your details (like name, phone number, photo), and then tap "Save".',
                          style: GoogleFonts.nunitoSans(
                            fontSize: fontSizeBody,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text(
                      'How can I check my notifications?',
                      style: GoogleFonts.nunitoSans(
                        fontSize: fontSizeTitle,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
                        child: Text(
                          'Tap on the "Alerts" icon in the Bottom Navigation Bar. You’ll see all the notifications you’ve received, such as new order notifications or messages from customers.',
                          style: GoogleFonts.nunitoSans(
                            fontSize: fontSizeBody,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text(
                      'What should I do if I forget my password?',
                      style: GoogleFonts.nunitoSans(
                        fontSize: fontSizeTitle,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
                        child: Text(
                          'Go to the login page and tap on "Forgot Password?". You’ll be asked to enter your SSN, and then reset your password.',
                          style: GoogleFonts.nunitoSans(
                            fontSize: fontSizeBody,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text(
                      'How can I contact support if I still need help?',
                      style: GoogleFonts.nunitoSans(
                        fontSize: fontSizeTitle,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
                        child: Text(
                          'Open the Drawer (from the settings icon at the top right), and select "Support". You’ll be able to send a message to the support team, and they’ll respond to you as soon as possible.',
                          style: GoogleFonts.nunitoSans(
                            fontSize: fontSizeBody,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}