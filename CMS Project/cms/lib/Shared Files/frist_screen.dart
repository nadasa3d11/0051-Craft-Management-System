import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/Hello1.dart';
import 'package:herfa/Shared%20Files/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({Key? key}) : super(key: key);

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
  }

  Future<void> _onRefresh(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 1));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحديث'),
        content: const Text('تم التحديث!'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () => _onRefresh(context),
          child: SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: Stack(
              children: [
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  height: double.infinity,
                  width: double.infinity,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: screenHeight * 0.1),
                        Image.asset(
                          "img/logo.png",
                          height: screenHeight * 0.3,
                          width: screenWidth * 0.6,
                        ),
                        Text(
                          "WELCOME",
                          style: GoogleFonts.tiroBangla(
                            fontSize: screenWidth * 0.08,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          "to",
                          style: GoogleFonts.tiroBangla(
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          "Herfa Store!",
                          style: GoogleFonts.vibur(
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          "The home for crafts",
                          style: GoogleFonts.tiroBangla(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const Hello1()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.2,
                              vertical: screenHeight * 0.025,
                            ),
                            backgroundColor: const Color(0xFF0C8A7B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            "Let’s Get Started",
                            style: GoogleFonts.tiroDevanagariHindi(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'I already have an account',
                              style: GoogleFonts.nunitoSans(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              iconSize: screenWidth * 0.1,
                              icon: const Icon(Icons.arrow_circle_right),
                              color: const Color(0xFF0C8A7B),
                              onPressed: () async {
                                await _completeOnboarding();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.1),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Image.asset(
                    "img/up.png",
                    width: screenWidth * 0.4,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Image.asset(
                    "img/down.png",
                    width: screenWidth * 0.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}