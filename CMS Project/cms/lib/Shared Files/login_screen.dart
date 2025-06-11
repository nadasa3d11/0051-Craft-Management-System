import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/admin/customNavigatorAdmin.dart';
import 'package:herfa/artisan/customNavigator.dart';
import 'package:herfa/client/customNavigatorClient.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:herfa/Shared%20Files/forget_password_screen.dart';
import 'package:herfa/Shared%20Files/sc_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService apiService = ApiService();
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool obscureText = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('AccessToken');
    final String? role = prefs.getString('Role');

    if (accessToken != null && role != null && accessToken.isNotEmpty && role.isNotEmpty) {
      Widget nextScreen;
      if (role == "Admin") {
        nextScreen = CustomNavigatorAdmin();
      } else if (role == "Client") {
        nextScreen = CombinedNavigation();
      } else if (role == "Artisan") {
        nextScreen = CustomNavigator();
      } else {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> saveTokensAndRole(String accessToken, String refreshToken, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('AccessToken', accessToken);
    await prefs.setString('RefreshToken', refreshToken);
    await prefs.setString('Role', role);
  }

  void showErrorDialog(BuildContext context, String message) async {
    await Future.delayed(Duration.zero);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          "Account Status",
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              "OK",
              style: TextStyle(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Future<Map<String, dynamic>> _loginUserInBackground(Map<String, dynamic> params) async {
    return await ApiService().loginUser(params['phone'], params['password']);
  }

  void login() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => isLoading = false);
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
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      Map<String, dynamic> response = await apiService.loginUser(
          phoneController.text, passwordController.text);

      if (response.containsKey("AccessToken") &&
          response.containsKey("RefreshToken")) {
        String accessToken = response["AccessToken"] ?? "";
        String refreshToken = response["RefreshToken"] ?? "";
        String role = response["Role"] ?? "";

        if (accessToken.isNotEmpty && refreshToken.isNotEmpty && role.isNotEmpty) {
          await saveTokensAndRole(accessToken, refreshToken, role);

          Widget nextScreen;
          if (role == "Admin") {
            nextScreen = CustomNavigatorAdmin();
          } else if (role == "Client") {
            nextScreen = CombinedNavigation();
          } else if (role == "Artisan") {
            nextScreen = CustomNavigator();
          } else {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Error"),
                content: Text("Unknown role: $role"),
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
            setState(() => isLoading = false);
            return;
          }

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => nextScreen),
            (Route<dynamic> route) => false,
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Error"),
              content: const Text("An error occurred during login. Please try again."),
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
      } else {
        String errorMessage = response["Message"] ?? response["error"] ?? "Invalid phone number or password";

        if (errorMessage.toLowerCase().contains("invalid or deleted")) {
          showErrorDialog(context, "Your account Invalid or deleted by an administrator.");
        } else if (errorMessage.toLowerCase() == "your account deactivated by an administrator.") {
          showErrorDialog(context, "Your account is temporarily deactivated by an administrator.");
        } else if (errorMessage.toLowerCase() == "invalid  password.") {
          showErrorDialog(context, "Invalid password. Please try again with the correct password.");
        } else {
          showErrorDialog(context, errorMessage);
        }
      }
    } catch (e) {
      showErrorDialog(context, "Login error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      phoneController.clear();
      passwordController.clear();
      isLoading = false;
      obscureText = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C8A7B),
        title: Text(
          "Herfa",
          style: GoogleFonts.vibur(
            fontSize: MediaQuery.of(context).size.width * 0.0625,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(MediaQuery.of(context).size.width * 0.05),
            bottomRight: Radius.circular(MediaQuery.of(context).size.width * 0.05),
          ),
        ),
      ),
      body: Builder(
        builder: (context) => RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.0125),
                  Text(
                    'Log into\nyour account',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.1175,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.125),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Enter your phone number',
                            labelStyle: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            prefixIcon: Icon(
                              Icons.phone,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFF0C8A7B),
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.0325),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFF0C8A7B),
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.0325),
                            ),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? "Phone must not be empty" : null,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.0375),
                        TextFormField(
                          controller: passwordController,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: obscureText,
                          decoration: InputDecoration(
                            labelText: 'Enter your Password',
                            labelStyle: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            prefixIcon: Icon(
                              Icons.lock,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureText ? Icons.visibility : Icons.visibility_off,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              onPressed: () =>
                                  setState(() => obscureText = !obscureText),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFF0C8A7B),
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.0325),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFF0C8A7B),
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.0325),
                            ),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? "Password must not be empty" : null,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ForgetPasswordScreen()));
                            },
                            child: const Text('Forgot password?',
                                style: TextStyle(color: Colors.blue)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.0875),
                  Center(
                    child: MaterialButton(
                      height: MediaQuery.of(context).size.height * 0.075,
                      minWidth: MediaQuery.of(context).size.width * 0.575,
                      onPressed: isLoading ? null : login,
                      color: const Color(0xFF0C8A7B),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.125)),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Login",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: MediaQuery.of(context).size.width * 0.055,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.00625),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.0375,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => ScScreen()));
                        },
                        child: Text(
                          " Sign Up",
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.0375,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
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