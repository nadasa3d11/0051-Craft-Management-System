import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/ComplaintsPage.dart';
import 'package:herfa/artisan/FAQforArtisan.dart';
import 'package:herfa/client/FAQforClient.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Support extends StatefulWidget {
  @override
  _SupportState createState() => _SupportState();
}

class _SupportState extends State<Support> {
  final ApiService _apiService = ApiService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController problemController = TextEditingController();
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('Role');
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    problemController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    final String name = nameController.text.trim();
    final String phone = phoneController.text.trim();
    final String problem = problemController.text.trim();

    if (name.isEmpty || phone.isEmpty || problem.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            "Error",
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Please fill all fields (Name, Phone Number, and Problem Description) before submitting.",
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "OK",
                style: TextStyle(
                  color: const Color(0xFF0C8A7B),
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Connection Error"),
          content: const Text("No internet connection. Please check your network and try again."),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    final result = await _apiService.createComplaint(
      problem: problem,
      phoneNumber: phone,
      complainer: name,
    );

    if (result.containsKey("error")) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: Text(result["error"]),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Success"),
          content: const Text("Complaint submitted successfully"),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                nameController.clear();
                phoneController.clear();
                problemController.clear();
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      nameController.clear();
      phoneController.clear();
      problemController.clear();
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        centerTitle: true,
        title: Text(
          "Support",
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.06,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Container(
            padding: EdgeInsets.only(
              left: screenWidth * 0.0125,
              right: screenWidth * 0.0125,
              bottom: screenHeight * 0.1,
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text.rich(
                    textAlign: TextAlign.center,
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "If You have a Problem You can Call Us at ",
                          style: GoogleFonts.nunitoSans(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.0375,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: "89863\n",
                          style: GoogleFonts.nunitoSans(
                            fontWeight: FontWeight.w800,
                            fontSize: screenWidth * 0.0625,
                            color: const Color(0xFF0C8A7B),
                          ),
                        ),
                        TextSpan(
                          text: "or\nSend Your Problem\n\n",
                          style: GoogleFonts.nunitoSans(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.0375,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: screenWidth * 0.8,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.025,
                                horizontal: screenWidth * 0.025,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF0C8A7B),
                                  width: 1.2,
                                ),
                                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF0C8A7B),
                                ),
                                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                              ),
                            ),
                          ),
                          Positioned(
                            left: screenWidth * 0.0375,
                            top: -screenHeight * 0.0175,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.0125),
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black
                                  : Colors.white,
                              child: Text(
                                "Enter Your Name",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: -screenWidth * 0.075,
                            top: screenHeight * 0.575,
                            child: Image.asset(
                              'img/Support.png',
                              height: screenHeight * 0.125,
                              width: screenWidth * 0.25,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.only(top: screenHeight * 0.025)),
                SizedBox(
                  width: screenWidth * 0.8,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.025,
                                horizontal: screenWidth * 0.025,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF0C8A7B),
                                  width: 1.2,
                                ),
                                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF0C8A7B),
                                ),
                                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                              ),
                            ),
                          ),
                          Positioned(
                            left: screenWidth * 0.0375,
                            top: -screenHeight * 0.0175,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.0125),
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black
                                  : Colors.white,
                              child: Text(
                                "Enter Your Phone Number",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.only(top: screenHeight * 0.025)),
                SizedBox(
                  width: screenWidth * 0.8,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          TextField(
                            controller: problemController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.025,
                                horizontal: screenWidth * 0.025,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF0C8A7B),
                                  width: 1.2,
                                ),
                                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF0C8A7B),
                                ),
                                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                              ),
                            ),
                          ),
                          Positioned(
                            left: screenWidth * 0.0375,
                            top: -screenHeight * 0.0175,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.0125),
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black
                                  : Colors.white,
                              child: Text(
                                "What’s Your Problem?",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.only(top: screenHeight * 0.0125)),
                TextButton(
                  onPressed: _submitComplaint,
                  child: Container(
                    width: screenWidth * 0.75,
                    height: screenHeight * 0.0875,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C8A7B),
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    ),
                    child: Align(
                      child: Text(
                        "Submit",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.only(top: screenHeight * 0.0125)),
                Padding(
                  padding: EdgeInsets.only(
                    right: screenWidth * 0.1,
                    left: screenWidth * 0.1,
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      textAlign: TextAlign.center,
                      "This guide can answer your questions before reaching out to support",
                      style: TextStyle(
                        fontSize: screenWidth * 0.0375,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (userRole == "Artisan") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FAQPage()),
                      );
                    } else if (userRole == "Client") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FAQforClient()),
                      );
                    }
                  },
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "FAQ",
                      style: GoogleFonts.nunitoSans(
                        fontWeight: FontWeight.bold,
                        textStyle: TextStyle(
                          color: const Color(0xFF0C8A7B),
                          fontSize: screenWidth * 0.08,
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFF0C8A7B),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.only(top: screenHeight * 0.025)),
                Text(
                  "we are available from 9:00AM to 10:00PM",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.0375,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ComplaintsPage()),
            );
          } catch (e) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Error"),
                content: Text("Error navigating to Complaints: $e"),
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]
                    : Colors.white,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
        },
        backgroundColor: Color(0xFF0C8A7B),
        child: Icon(Icons.list, color: Colors.white),
      ),
    );
  }
}