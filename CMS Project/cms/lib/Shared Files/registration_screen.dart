import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:herfa/Shared%20Files/terms_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'package:herfa/Shared%20Files/shared_state.dart';

class RegistrationScreen extends StatefulWidget {
  final String role;
  const RegistrationScreen({super.key, required this.role});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController cpasswordController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController ssnController = TextEditingController();
  File? idCardImage;
  final ImagePicker _picker = ImagePicker();
  String? _gender;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    termsAgreed.addListener(_updateAgreedStatus);
  }

  @override
  void dispose() {
    termsAgreed.removeListener(_updateAgreedStatus);
    super.dispose();
  }

  void _updateAgreedStatus() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        idCardImage = File(pickedFile.path);
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_gender == null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: const Text("Please select a gender"),
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
      if (!termsAgreed.value) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: const Text("You must agree to the terms"),
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
      if (idCardImage == null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: const Text("Please upload an ID image"),
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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      ApiService apiService = ApiService();
      var response = await apiService.registerUser(
        fullName: nameController.text,
        phone: phoneController.text,
        birthDate: dateController.text,
        ssn: ssnController.text,
        gender: _gender!,
        password: passwordController.text,
        address: addressController.text,
        idCardImage: idCardImage!,
        role: widget.role,
      );

      Navigator.pop(context);

      if (response.containsKey("error")) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: Text(response["error"]),
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
            content: const Text("Registration Successful!"),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.white,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (widget.role.toLowerCase() == "artisan") {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  } else if (widget.role.toLowerCase() == "client") {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Error"),
                        content: const Text("Invalid role. Please try again."),
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[900]
                            : Colors.white,
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      nameController.clear();
      phoneController.clear();
      passwordController.clear();
      cpasswordController.clear();
      addressController.clear();
      dateController.clear();
      ssnController.clear();
      idCardImage = null;
      _gender = null;
      termsAgreed.value = false;
      _isPasswordVisible = false;
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
        backgroundColor: const Color(0xFF0C8A7B),
        title: Text(
          "Herfa",
          style: GoogleFonts.vibur(
            fontSize: screenWidth * 0.0625,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(screenWidth * 0.05),
            bottomRight: Radius.circular(screenWidth * 0.05),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create\nyour account',
                  style: TextStyle(
                    fontSize: screenWidth * 0.1,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),
                _buildTextField(nameController, 'Full Name', Icons.person,
                    screenWidth: screenWidth, screenHeight: screenHeight),
                _buildTextField(phoneController, 'Phone Number', Icons.phone,
                    keyboardType: TextInputType.phone,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight),
                _buildTextField(passwordController, 'Password', Icons.lock,
                    obscureText: !_isPasswordVisible,
                    isPassword: true,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight),
                _buildTextField(cpasswordController, 'Confirm Password', Icons.lock,
                    obscureText: !_isPasswordVisible,
                    isConfirmPassword: true,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight),
                _buildTextField(addressController, 'Address', Icons.location_on,
                    screenWidth: screenWidth, screenHeight: screenHeight),
                _buildTextField(dateController, 'YYYY-MM-DD', Icons.calendar_today,
                    onTap: _pickDate,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight),
                _buildTextField(ssnController, 'SSN', Icons.badge,
                    screenWidth: screenWidth, screenHeight: screenHeight),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(
                    Icons.image,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  label: Text(
                    idCardImage == null ? "Upload ID Image" : "Image Selected",
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
                if (idCardImage != null) ...[
                  Container(
                    margin: EdgeInsets.symmetric(vertical: screenHeight * 0.0125),
                    height: screenHeight * 0.25,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF0C8A7B), width: 1.2),
                      borderRadius: BorderRadius.circular(screenWidth * 0.025),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.025),
                      child: Image.file(
                        idCardImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Text("Error loading image"),
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: screenHeight * 0.01875),
                Row(
                  children: [
                    Text(
                      "Gender",
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    Radio<String>(
                      value: 'Male',
                      groupValue: _gender,
                      onChanged: (value) => setState(() => _gender = value),
                      activeColor: const Color(0xFF0C8A7B),
                    ),
                    Text(
                      'Male',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    Radio<String>(
                      value: 'Female',
                      groupValue: _gender,
                      onChanged: (value) => setState(() => _gender = value),
                      activeColor: const Color(0xFF0C8A7B),
                    ),
                    Text(
                      'Female',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: termsAgreed,
                      builder: (context, value, child) {
                        return Checkbox(
                          value: value,
                          onChanged: (newValue) {
                            termsAgreed.value = newValue!;
                          },
                          activeColor: const Color(0xFF0C8A7B),
                        );
                      },
                    ),
                    Text(
                      "I agree to the terms ,",
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TermsScreen()),
                      ),
                      child: const Text("View Terms"),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.01875),
                Center(
                  child: MaterialButton(
                    height: screenHeight * 0.075,
                    minWidth: screenWidth * 0.575,
                    color: const Color(0xFF0C8A7B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.125),
                    ),
                    onPressed: _submitForm,
                    child: Text(
                      "Register",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.055,
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

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon,
      {TextInputType keyboardType = TextInputType.text,
      bool obscureText = false,
      bool isPassword = false,
      bool isConfirmPassword = false,
      VoidCallback? onTap,
      required double screenWidth,
      required double screenHeight}) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.0125),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black54,
          ),
          icon: Icon(
            icon,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : null,
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
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(screenWidth * 0.025),
          ),
        ),
        validator: (input) => (input!.isEmpty)
            ? "$label must not be empty"
            : (isConfirmPassword && input != passwordController.text)
                ? "Passwords do not match"
                : null,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
    }
  }
}