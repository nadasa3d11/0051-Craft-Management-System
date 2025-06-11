import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/sc_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Hello3 extends StatelessWidget {
  const Hello3({Key? key}) : super(key: key);

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
  }

  Future<void> _onRefresh(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                decoration: const BoxDecoration(
                  color: Color(0xFF0C8A7B), 
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                height: screenHeight * 0.6,
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.05),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Herfa",
                        style: GoogleFonts.vibur(
                          fontWeight: FontWeight.w100,
                          fontSize: screenWidth * 0.06,
                          color: Colors.white, 
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    Text(
                      textAlign: TextAlign.center,
                      "Enhancing communication between artisans and customers",
                      style: GoogleFonts.tiroDevanagariHindi(
                        fontWeight: FontWeight.w100,
                        fontSize: screenWidth * 0.055,
                        color: Colors.white, 
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    CircleAvatar(
                      radius: screenWidth * 0.35,
                      backgroundImage: const AssetImage('img/Hello3.jpg'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.1),
              SizedBox(
                width: screenWidth * 0.8,
                height: screenHeight * 0.08,
                child: ElevatedButton(
                  onPressed: () async {
                    await _completeOnboarding();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const ScScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C8A7B), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    "Next",
                    style: GoogleFonts.tiroDevanagariHindi(
                      fontWeight: FontWeight.w100,
                      fontSize: screenWidth * 0.04,
                      color: Colors.white, 
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: screenWidth * 0.12,
                    height: screenWidth * 0.12,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Container(
                    width: screenWidth * 0.12,
                    height: screenWidth * 0.12,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Container(
                    width: screenWidth * 0.12,
                    height: screenWidth * 0.12,
                    decoration: BoxDecoration(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}