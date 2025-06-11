import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  Future<void> _refreshPage() async {
    
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    
    final double padding = MediaQuery.of(context).size.width * 0.08;
    final double spacing = MediaQuery.of(context).size.height * 0.04;
    final double fontSize = MediaQuery.of(context).size.width * 0.04;
    final double imageSize = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
        title: Text(
          "Privacy Policy",
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.of(context).size.width * 0.06,
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshPage,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "At ",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          TextSpan(
                            text: "Herfa",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: const Color(0xFF0C8A7B), 
                              
                            ),
                          ),
                          TextSpan(
                            text:
                                " ,we are committed to protecting your privacy. This Privacy Policy explains how we collect and use your data:\n\n",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          TextSpan(
                            text: "Personal Data:",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: const Color(0xFF0C8A7B),
                              
                            ),
                          ),
                          TextSpan(
                            text:
                                " We collect basic information such as your name, email address, location, and payment methods when you register or place orders.\n\n",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          TextSpan(
                            text: "Data Usage:",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: const Color(0xFF0C8A7B),
                              
                            ),
                          ),
                          TextSpan(
                            text:
                                " Your data is used to provide services, process orders, and enhance user experience.\n\n",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          TextSpan(
                            text: "Data Sharing:",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: const Color(0xFF0C8A7B), 
                              
                            ),
                          ),
                          TextSpan(
                            text:
                                " We do not share your data with third parties, except when necessary to deliver services or comply with legal requirements.\n\n",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          TextSpan(
                            text: "Your Rights:",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: const Color(0xFF0C8A7B), 
                              
                            ),
                          ),
                          TextSpan(
                            text:
                                " You have the right to access, modify, or request deletion of your data at any time.\n\n"
                                "By using the app, you agree to the collection and use of your data in accordance with this policy.",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: spacing),
                  Image.asset(
                    'img/Privacy_Policy.png',
                    height: imageSize,
                    width: imageSize,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: spacing),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}