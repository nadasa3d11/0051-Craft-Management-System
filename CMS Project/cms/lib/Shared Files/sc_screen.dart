import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/registration_screen.dart';

class ScScreen extends StatefulWidget {
  const ScScreen({super.key});

  @override
  State<ScScreen> createState() => _ScScreenState();
}

class _ScScreenState extends State<ScScreen> {
  String? selectedRole;

  void navigateToRegistration(String role) {
    setState(() {
      selectedRole = role;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegistrationScreen(role: selectedRole!)),
    );
  }

  Future<void> _onRefresh() async {
    setState(() {
      selectedRole = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: screenHeight * 0.4375,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('img/Mask group.png'),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.025,
                    left: screenWidth * 0.025,
                    child: Text(
                      "Herfa",
                      style: GoogleFonts.vibur(
                        fontSize: screenWidth * 0.08,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.0625),
              Text(
                'Are you',
                style: GoogleFonts.tiroDevanagariHindi(
                  fontSize: screenWidth * 0.0875,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.0375),
              Center(
                child: MaterialButton(
                  height: screenHeight * 0.0875,
                  minWidth: screenWidth * 0.75,
                  onPressed: () => navigateToRegistration("Client"),
                  color: const Color(0xFF0C8A7B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.05)),
                  child: Text("Client", style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.0625)),
                ),
              ),
              SizedBox(height: screenHeight * 0.025),
              Text(
                'or',
                style: GoogleFonts.tiroDevanagariHindi(
                  fontSize: screenWidth * 0.0875,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.025),
              Center(
                child: MaterialButton(
                  height: screenHeight * 0.0875,
                  minWidth: screenWidth * 0.75,
                  onPressed: () => navigateToRegistration("Artisan"),
                  color: const Color(0xFF0C8A7B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.05)),
                  child: Text("Artisan", style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.0625)),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                "?",
                style: GoogleFonts.tiroDevanagariHindi(
                  fontSize: screenWidth * 0.0875,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}