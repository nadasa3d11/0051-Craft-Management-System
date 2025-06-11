import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class About_Us extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        centerTitle: true,
        title: Text(
          "About Us",
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.06, 
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Container(
          padding: EdgeInsets.only(
            top: screenHeight * 0.0375, 
            left: screenWidth * 0.0375, 
            right: screenWidth * 0.0375, 
            bottom: screenHeight * 0.1, 
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.center,
                child: Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(children: [
                    TextSpan(
                      text: "Welcome to ",
                      style: GoogleFonts.nunitoSans(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.0375, 
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: "Herfa!\n\n",
                      style: GoogleFonts.nunitoSans(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.0375, 
                        color: const Color(0xFF0C8A7B),
                      ),
                    ),
                    TextSpan(
                      text:
                          "We are a dedicated team committed to supporting handcrafted arts and making them easily accessible to customers in a modern, seamless way. Our goal is to provide a platform that connects creative artisans with customers seeking unique, high-quality handmade products.\n\n"
                          "Our mission is to empower artisans to showcase their products and expand their reach, while providing a unique and effortless experience for customers in search of distinctive pieces.\n"
                          "Our vision is to be the bridge that unites authenticity and innovation in the world of handicrafts.",
                      style: GoogleFonts.nunitoSans(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.0375, 
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ]),
                ),
              ),
              SizedBox(height: screenHeight * 0.0375), 
              Image.asset(
                'img/About_Us.png',
                height: screenHeight * 0.4375, 
                width: screenWidth * 0.875, 
              ),
              SizedBox(height: screenHeight * 0.0375), 
            ],
          ),
        ),
      ),
    );
  }
}