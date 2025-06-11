// ignore_for_file: unused_field
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/create_new_password_screen.dart';
import 'package:http/http.dart' as http;

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ssnController = TextEditingController();
  bool _isLoading = false;
  String? _phoneError;
  String? _ssnError;
  final String _baseUrl = 'https://herfa-system-handmade.runasp.net'; 

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> resetPassword(
      String phone, String ssn, String newPassword) async {
    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      return {"error": "No internet connection. Please check your network and try again."};
    }

    try {
      final url = Uri.parse("$_baseUrl/api/Auth/reset-password");
      final body = jsonEncode({
        "Phone": phone,
        "SSN": ssn,
        "NewPassword": newPassword,
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {"message": "Password reset successfully"};
      } else {
        final responseData = jsonDecode(response.body);
        return {
          "error": responseData["message"] ??
              "Failed to reset password: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {"error": "Failed to reset password: $e"};
    }
  }

  void _validateAndGoToNextScreen() {
    String phone = _phoneController.text.trim();
    String ssn = _ssnController.text.trim();

    setState(() {
      _phoneError = null;
      _ssnError = null;

      if (phone.isEmpty) {
        _phoneError = 'Please enter your phone number.';
      } 

      if (ssn.isEmpty) {
        _ssnError = 'Please enter your national ID number.';
      }
    });

    if (_phoneError == null && _ssnError == null) {
      setState(() {
        _isLoading = true;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateNewPasswordScreen(phone: phone, ssn: ssn),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _phoneController.clear();
      _ssnController.clear();
      _phoneError = null;
      _ssnError = null;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _ssnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive dimensions based on screen size
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double fieldWidth = screenWidth * 0.85;
    final double padding = screenWidth * 0.05;
    final double titleFontSize = screenWidth * 0.12;
    final double subtitleFontSize = screenWidth * 0.07;
    final double buttonWidth = screenWidth * 0.5;
    final double buttonHeight = screenHeight * 0.07;
    final double spacing = screenHeight * 0.02;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.teal[900] : Colors.teal[600],
        title: Text(
          "Herfa",
          style: GoogleFonts.vibur(
            fontSize: screenWidth * 0.06,
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
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: spacing),
                Text(
                  'Forgot\nPassword ?',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: spacing),
                Text(
                  'Enter the phone number and SSN associated with your account to reset your password.',
                  style: TextStyle(
                    fontSize: subtitleFontSize,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.grey[400] : Colors.black54,
                  ),
                ),
                SizedBox(height: spacing * 2),
                Center(
                  child: SizedBox(
                    width: fieldWidth,
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.phone),
                        labelText: 'Phone Number',
                        labelStyle: GoogleFonts.nunitoSans(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        hintText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: isDarkMode ? Colors.teal[900]! : Colors.teal[600]!,
                          ),
                        ),
                        filled: true,
                        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        errorText: _phoneError,
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && _phoneError != null) {
                          setState(() {
                            _phoneError = null;
                          });
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: spacing),
                Center(
                  child: SizedBox(
                    width: fieldWidth,
                    child: TextField(
                      controller: _ssnController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.perm_identity),
                        labelText: 'SSN',
                        labelStyle: GoogleFonts.nunitoSans(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        hintText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: isDarkMode ? Colors.teal[900]! : Colors.teal[600]!,
                          ),
                        ),
                        filled: true,
                        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        errorText: _ssnError,
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && _ssnError != null) {
                          setState(() {
                            _ssnError = null;
                          });
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: spacing * 1.5),
                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : MaterialButton(
                          height: buttonHeight,
                          minWidth: buttonWidth,
                          onPressed: _validateAndGoToNextScreen,
                          color: isDarkMode ? Colors.teal[900] : Colors.teal[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            'Next',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.05,
                            ),
                          ),
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