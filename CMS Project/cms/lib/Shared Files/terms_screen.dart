import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/shared_state.dart';

class MyApp1 extends StatelessWidget {
  const MyApp1({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const TermsScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0C8A7B),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.nunitoSansTextTheme(),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0C8A7B),
        scaffoldBackgroundColor: Colors.grey[900],
        textTheme: GoogleFonts.nunitoSansTextTheme().apply(bodyColor: Colors.white),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      themeMode: ThemeMode.system,
    );
  }
}

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  _TermsScreenState createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
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
          "Herfa",
          style: GoogleFonts.vibur(
            fontSize: MediaQuery.of(context).size.width * 0.06,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Registration and Use Agreement for 'Herfa' Platform",
                        style: GoogleFonts.nunitoSans(
                          fontSize: fontSizeTitle,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      SizedBox(height: spacing),
                      RichText(
                        text: TextSpan(
                          text: "Welcome to ",
                          style: GoogleFonts.nunitoSans(
                            fontSize: fontSizeBody,
                            height: 1.5,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          children: [
                            TextSpan(
                              text: "'Herfa'",
                              style: GoogleFonts.nunitoSans(
                                fontSize: fontSizeBody,
                                color: const Color(0xFF0C8A7B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: "! By registering and using our services, you agree to the following terms and conditions:",
                              style: GoogleFonts.nunitoSans(
                                fontSize: fontSizeBody,
                                height: 1.5,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: spacing),
                      _buildSectionTitle(context, '1. Free Registration:', fontSizeBody),
                      _buildBulletPoint(
                        context,
                        """- When registering for the first time on 'Herfa', registration will be free.
- This offer is valid for a limited period. After this period, fees will be applied to artisans, and these fees will be communicated in due time.
- Fee Terms: After the free registration period, a fee will be charged on the products you sell through the app, which is a percentage of the product price, collected upon completing the sale.""",
                        fontSizeBody,
                      ),
                      _buildSectionTitle(context, '2. Product Fees:', fontSizeBody),
                      _buildBulletPoint(
                        context,
                        """- After the free registration period ends, a percentage fee 5% of the value of each product sold via the app will be charged.
- If you provide services in addition to products, such as repair or customization services, additional fees will apply for those services, and they will be determined later.""",
                        fontSizeBody,
                      ),
                      _buildSectionTitle(context, '3. Artisan Obligations:', fontSizeBody),
                      _buildBulletPoint(
                        context,
                        """- The artisan is required to ensure the accuracy of all data provided in the app.
- The artisan must provide products in accordance with the quality standards defined by 'Herfa' to ensure customer satisfaction.
- The artisan must adhere to delivery schedules and communicate with customers in case of any delays.
- In case of customer complaints regarding product or service quality, the artisan is obligated to address and respond to them promptly.""",
                        fontSizeBody,
                      ),
                      _buildSectionTitle(context, '4. Privacy:', fontSizeBody),
                      _buildBulletPoint(
                        context,
                        """- We are committed to protecting your personal data and using it only in accordance with our privacy policy.
- All data you provide through the app will be treated according to the highest security standards.""",
                        fontSizeBody,
                      ),
                      _buildSectionTitle(context, '5. Account Cancellation:', fontSizeBody),
                      _buildBulletPoint(
                        context,
                        """- The artisan can cancel their account at any time, but must handle any pending orders before cancellation.
- If there are any outstanding fees at the time of cancellation, they must be settled before account termination.""",
                        fontSizeBody,
                      ),
                      _buildSectionTitle(context, '6. Amendments:', fontSizeBody),
                      _buildBulletPoint(
                        context,
                        """- We reserve the right to modify the terms and conditions at any time, and will notify artisans of any changes to the agreement.
- The continued use of the app by the artisan after any modifications will be deemed as implied acceptance of the modified terms.""",
                        fontSizeBody,
                      ),
                      _buildSectionTitle(context, '7. Product Retention and Pricing:', fontSizeBody),
                      _buildBulletPoint(
                        context,
                        """- The artisan is responsible for setting the prices for their products and services, but we reserve the right to impose restrictions on pricing or prohibit certain products if they violate policies.
- The artisan is expected to provide an accurate description of their products and services, and all content on the app must comply with local and international standards.""",
                        fontSizeBody,
                      ),
                      _buildSectionTitle(context, '8. Usage Prohibition:', fontSizeBody),
                      _buildBulletPoint(
                        context,
                        """- 'Herfa' reserves the right to suspend or terminate the artisan's account if any of the terms and conditions are violated, or if harmful or inappropriate content is provided.""",
                        fontSizeBody,
                      ),
                      _buildSectionTitle(context, '9. Applicable Laws:', fontSizeBody),
                      _buildBulletPoint(
                        context,
                        """- This agreement is governed and interpreted in accordance with the local laws of Egypt, and any disputes arising will be subject to the jurisdiction of the competent courts in Egypt.""",
                        fontSizeBody,
                      ),
                      _buildSectionTitle(context, '10. Acceptance:', fontSizeBody),
                      _buildBulletPoint(
                        context,
                        """- By accepting this agreement and registering on 'Herfa', you agree to all the terms and conditions outlined herein.""",
                        fontSizeBody,
                      ),
                    ],
                  ),
                  SizedBox(height: spacing),
                  ValueListenableBuilder<bool>(
                    valueListenable: termsAgreed,
                    builder: (context, value, child) {
                      return Row(
                        children: [
                          Checkbox(
                            value: value,
                            onChanged: (newValue) {
                              termsAgreed.value = newValue!;
                            },
                            activeColor: const Color(0xFF0C8A7B),
                          ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: "I agree to the Terms and Conditions and Privacy Policy of ",
                                style: GoogleFonts.nunitoSans(
                                  fontSize: fontSizeBody,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                                children: [
                                  TextSpan(
                                    text: "'Herfa'",
                                    style: GoogleFonts.nunitoSans(
                                      fontSize: fontSizeBody,
                                      color: const Color(0xFF0C8A7B),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: spacing),
                  ValueListenableBuilder<bool>(
                    valueListenable: termsAgreed,
                    builder: (context, value, child) {
                      return GestureDetector(
                        onTap: value
                            ? () {
                                Navigator.pop(context);
                              }
                            : null,
                        child: Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.06,
                          decoration: BoxDecoration(
                            color: value ? const Color(0xFF0C8A7B) : Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Back',
                              style: GoogleFonts.nunitoSans(
                                fontSize: MediaQuery.of(context).size.width * 0.05,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, double fontSize) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.01),
      child: Text(
        title,
        style: GoogleFonts.nunitoSans(
          fontSize: fontSize + 0.01,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text, double fontSize) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.005),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: GoogleFonts.nunitoSans(
              fontSize: fontSize,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: text.split("'Herfa'").map((part) {
                  return TextSpan(
                    text: part,
                    style: GoogleFonts.nunitoSans(
                      fontSize: fontSize,
                      height: 1.5,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  );
                }).expand((span) => [
                      span,
                      if (span.text != text) 
                        TextSpan(
                          text: "'Herfa'",
                          style: GoogleFonts.nunitoSans(
                            fontSize: fontSize,
                            color: const Color(0xFF0C8A7B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ]).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}