import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FAQforClient extends StatelessWidget {
  const FAQforClient({super.key});

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
                      'How do I place an order?',
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
                          'Browse the products on the Home page or search for a specific item. Once you find a product you like, tap on it to view its details. Then, tap "Add to Cart" and go to your Cart from the Bottom Navigation Bar. From there, you can proceed to checkout and place your order.',
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
                          'Tap on the "Orders" icon in the Bottom Navigation Bar. You’ll see a list of all the orders you’ve placed. Tap on any order to view its details, such as the product, price, and delivery status.',
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
                          'Go to the "Profile" page from the Bottom Navigation Bar (person icon). Tap on profile item to edit your details, such as your name, phone number, or address. Then, tap "Save" to update your information.',
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
                      'How can I track my order?',
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
                          'Go to the "Orders" section from the Bottom Navigation Bar. Find the order you want to track and tap on it. You’ll see the current status of your order, such as "Pending," "Processing," or "Shipped.',
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
                          'On the login page, tap on "Forgot Password?". Enter your SSN, and you’ll reset your password. Follow the instructions to set a new password.',
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
                          'Go to the "Support" page from the Drawer (tap the settings icon at the top right). You can send a message to the support team with your issue, and they’ll get back to you as soon as possible.',
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