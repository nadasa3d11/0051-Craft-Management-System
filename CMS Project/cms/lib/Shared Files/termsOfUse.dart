import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfUse extends StatelessWidget {
  const TermsOfUse({super.key});

  Future<void> _refreshPage() async {
   
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    
    final double padding = MediaQuery.of(context).size.width * 0.08;
    final double spacing = MediaQuery.of(context).size.height * 0.04;
    final double fontSize = MediaQuery.of(context).size.width * 0.04;
    final double imageSize = MediaQuery.of(context).size.width * 0.6;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
        title: Text(
          "Terms of Use",
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
                            text: "Welcome to ",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          TextSpan(
                            text: "Herfa!",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: const Color(0xFF0C8A7B), 
                            ),
                          ),
                          TextSpan(
                            text:
                                " By using this application, you agree to the following terms and conditions:\n\n",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          TextSpan(
                            text: "Proper Use:",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: const Color(0xFF0C8A7B), 
                              
                            ),
                          ),
                          TextSpan(
                            text:
                                " The application may not be used for any unlawful purposes or to share harmful or inappropriate content.\n\n",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          TextSpan(
                            text: "Orders and Payment:",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: const Color(0xFF0C8A7B), 
                              
                            ),
                          ),
                          TextSpan(
                            text:
                                " Customers must make payments according to the available options. Artisans must provide their services as agreed upon with customers.\n\n",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          TextSpan(
                            text: "Cancellation and Refund Policy:",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: const Color(0xFF0C8A7B), 
                            ),
                          ),
                          TextSpan(
                            text:
                                " Customers may cancel orders within 24 hours from the booking time. Refunds will be issued according to the specified policies.\n\n",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          TextSpan(
                            text: "Privacy:",
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: const Color(0xFF0C8A7B),
                              
                            ),
                          ),
                          TextSpan(
                            text:
                                " We respect your privacy. For more information on how we handle your data, please review our Privacy Policy.\n\n"
                                "By continuing to use the app, you agree to adhere to these terms.",
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
                    'img/Terms_of_Use.png',
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