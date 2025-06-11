import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:image_picker/image_picker.dart';

class ProfileDetailsPage extends StatefulWidget {
  @override
  _ProfileDetailsPageState createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  TextEditingController fullNameController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  String gender = "Male";
  File? selectedImage;
  Map<String, dynamic>? userInfo;
  bool isLoading = true;
  bool isFullNameEmpty = false;
  bool isDobEmpty = false;
  bool isPhoneEmpty = false;
  bool isAddressEmpty = false;
  bool showPasswordFields = false;
  bool obscureOldPassword = true;
  bool obscureNewPassword = true;
  String? newPasswordError;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await _apiService.getMyInformation();
      if (userInfo.containsKey('error')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Error"),
            content: Text('Error: ${userInfo["error"]}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          this.userInfo = userInfo;
          fullNameController.text = userInfo['Full_Name'] ?? '';
          dobController.text = userInfo['Birth_Date']?.split('T')[0] ?? '';
          phoneController.text = userInfo['Phone'] ?? '';
          addressController.text = userInfo['Address'] ?? '';
          gender = userInfo['Gender'] ?? 'Male';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text('Error: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadUserInfo();
    setState(() {
      isFullNameEmpty = false;
      isDobEmpty = false;
      isPhoneEmpty = false;
      isAddressEmpty = false;
      showPasswordFields = false;
      oldPasswordController.clear();
      newPasswordController.clear();
      newPasswordError = null;
    });
  }

  Future<void> saveChanges() async {
    setState(() {
      isFullNameEmpty = fullNameController.text.trim().isEmpty;
      isDobEmpty = dobController.text.trim().isEmpty;
      isPhoneEmpty = phoneController.text.trim().isEmpty;
      isAddressEmpty = addressController.text.trim().isEmpty;
    });

    if (isFullNameEmpty || isDobEmpty || isPhoneEmpty || isAddressEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Input Error"),
          content: Text('Please fill in all required fields'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
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
          title: Text("Connection Error"),
          content: Text("No internet connection. Please check your network and try again."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await _apiService.updateMyInformation(
        fullName: fullNameController.text.trim(),
        phone: phoneController.text.trim(),
        birthDate: dobController.text.trim(),
        gender: gender,
        address: addressController.text.trim(),
        image: selectedImage,
      );

      setState(() {
        isLoading = false;
      });

      if (result.containsKey('error')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Error"),
            content: Text('Failed to save changes: ${result["error"]}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Success"),
            content: Text('Changes saved successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text('Error: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    final oldPassword = oldPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();

    setState(() {
      newPasswordError = null;
    });

    // Validate new password
    if (newPassword.isEmpty) {
      setState(() {
        newPasswordError = 'Please enter a new password';
      });
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        newPasswordError = 'Password must be at least 6 characters';
      });
      return;
    }

    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(newPassword)) {
      setState(() {
        newPasswordError = 'Password must contain letters and numbers';
      });
      return;
    }

    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Connection Error"),
          content: Text("No internet connection. Please check your network and try again."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await _apiService.changePassword(oldPassword, newPassword);

      setState(() {
        isLoading = false;
      });

      if (result.containsKey('error')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text(result['error']),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          showPasswordFields = false;
          oldPasswordController.clear();
          newPasswordController.clear();
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Success"),
            content: Text('Password changed successfully!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to change password: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    dobController.dispose();
    phoneController.dispose();
    addressController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (isLoading && userInfo == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.05),
                      child: Text(
                        'Edit Profile',
                        style: GoogleFonts.nunitoSans(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: screenWidth * 0.125,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: selectedImage != null
                                ? FileImage(selectedImage!)
                                : userInfo?['Image'] != null
                                    ? NetworkImage(userInfo!['Image'])
                                    : null,
                            child: selectedImage == null &&
                                    userInfo?['Image'] == null
                                ? Icon(
                                    Icons.person,
                                    size: screenWidth * 0.125,
                                    color: Colors.grey[600],
                                  )
                                : null,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black
                                  : Colors.white,
                              border: Border.all(color: Colors.grey),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: screenWidth * 0.05,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FULL NAME',
                            style: GoogleFonts.nunitoSans(
                              fontSize: screenWidth * 0.035,
                              color: Color(0xFF848688),
                            ),
                          ),
                          TextField(
                            controller: fullNameController,
                            style: GoogleFonts.nunitoSans(
                              fontSize: screenWidth * 0.04,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            decoration: InputDecoration(
                              border: UnderlineInputBorder(),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              errorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              errorText: isFullNameEmpty ? 'This field is required' : null,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.025),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DATE OF BIRTH',
                                      style: GoogleFonts.nunitoSans(
                                        fontSize: screenWidth * 0.035,
                                        color: Color(0xFF848688),
                                      ),
                                    ),
                                    TextField(
                                      controller: dobController,
                                      readOnly: true,
                                      onTap: () => _selectDate(context),
                                      style: GoogleFonts.nunitoSans(
                                        fontSize: screenWidth * 0.04,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                      decoration: InputDecoration(
                                        border: UnderlineInputBorder(),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.grey),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.grey),
                                        ),
                                        suffixIcon: Icon(
                                          Icons.calendar_today,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        errorBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.red),
                                        ),
                                        focusedErrorBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.red),
                                        ),
                                        errorText: isDobEmpty ? 'This field is required' : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.05),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PHONE NUMBER',
                                      style: GoogleFonts.nunitoSans(
                                        fontSize: screenWidth * 0.035,
                                        color: Color(0xFF848688),
                                      ),
                                    ),
                                    TextField(
                                      controller: phoneController,
                                      style: GoogleFonts.nunitoSans(
                                        fontSize: screenWidth * 0.04,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                      decoration: InputDecoration(
                                        border: UnderlineInputBorder(),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.grey),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.grey),
                                        ),
                                        errorBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.red),
                                        ),
                                        focusedErrorBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.red),
                                        ),
                                        errorText: isPhoneEmpty ? 'This field is required' : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.025),
                          Text(
                            'GENDER',
                            style: GoogleFonts.nunitoSans(
                              fontSize: screenWidth * 0.035,
                              color: Color(0xFF848688),
                            ),
                          ),
                          Row(
                            children: [
                              Row(
                                children: [
                                  Radio<String>(
                                    value: "Male",
                                    groupValue: gender,
                                    onChanged: (value) {
                                      setState(() {
                                        gender = value!;
                                      });
                                    },
                                  ),
                                  Text(
                                    "Male",
                                    style: GoogleFonts.nunitoSans(
                                      fontSize: screenWidth * 0.04,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: screenWidth * 0.05),
                              Row(
                                children: [
                                  Radio<String>(
                                    value: "Female",
                                    groupValue: gender,
                                    onChanged: (value) {
                                      setState(() {
                                        gender = value!;
                                      });
                                    },
                                  ),
                                  Text(
                                    "Female",
                                    style: GoogleFonts.nunitoSans(
                                      fontSize: screenWidth * 0.04,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.025),
                          Text(
                            'ADDRESS',
                            style: GoogleFonts.nunitoSans(
                              fontSize: screenWidth * 0.035,
                              color: Color(0xFF848688),
                            ),
                          ),
                          TextField(
                            controller: addressController,
                            style: GoogleFonts.nunitoSans(
                              fontSize: screenWidth * 0.04,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            decoration: InputDecoration(
                              border: UnderlineInputBorder(),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              errorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              errorText: isAddressEmpty ? 'This field is required' : null,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.025),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PASSWORD',
                                      style: GoogleFonts.nunitoSans(
                                        fontSize: screenWidth * 0.035,
                                        color: Color(0xFF848688),
                                      ),
                                    ),
                                    if (!showPasswordFields)
                                      TextField(
                                        obscureText: true,
                                        enabled: false,
                                        style: GoogleFonts.nunitoSans(
                                          fontSize: screenWidth * 0.04,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: '********',
                                          hintStyle: TextStyle(
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                          border: UnderlineInputBorder(),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Colors.grey),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    if (showPasswordFields) ...[
                                      TextField(
                                        controller: oldPasswordController,
                                        obscureText: obscureOldPassword,
                                        style: GoogleFonts.nunitoSans(
                                          fontSize: screenWidth * 0.04,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Enter old password',
                                          hintStyle: TextStyle(
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                          border: UnderlineInputBorder(),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Colors.grey),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Colors.grey),
                                          ),
                                          errorBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Colors.red),
                                          ),
                                          focusedErrorBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Colors.red),
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              obscureOldPassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                obscureOldPassword = !obscureOldPassword;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.025),
                                      TextField(
                                        controller: newPasswordController,
                                        obscureText: obscureNewPassword,
                                        style: GoogleFonts.nunitoSans(
                                          fontSize: screenWidth * 0.04,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Enter new password',
                                          hintStyle: TextStyle(
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                          border: UnderlineInputBorder(),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Colors.grey),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Colors.grey),
                                          ),
                                          errorBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Colors.red),
                                          ),
                                          focusedErrorBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Colors.red),
                                          ),
                                          errorText: newPasswordError,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              obscureNewPassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                obscureNewPassword = !obscureNewPassword;
                                              });
                                            },
                                          ),
                                        ),
                                        onChanged: (value) {
                                          if (value.isNotEmpty && newPasswordError != null) {
                                            setState(() {
                                              newPasswordError = null;
                                            });
                                          }
                                        },
                                      ),
                                      SizedBox(height: screenHeight * 0.025),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: isLoading ? null : _changePassword,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFF0C8A7B),
                                            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01875),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(screenWidth * 0.025),
                                            ),
                                          ),
                                          child: isLoading
                                              ? CircularProgressIndicator(color: Colors.white)
                                              : Text(
                                                  'Confirm Password Change',
                                                  style: GoogleFonts.nunitoSans(
                                                    fontSize: screenWidth * 0.04,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (!showPasswordFields)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      showPasswordFields = true;
                                    });
                                  },
                                  child: Text(
                                    'CHANGE PASSWORD',
                                    style: GoogleFonts.nunitoSans(
                                      fontSize: screenWidth * 0.035,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.0375),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF0C8A7B),
                                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01875),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                                ),
                              ),
                              child: isLoading
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      'SAVE CHANGE',
                                      style: GoogleFonts.nunitoSans(
                                        fontSize: screenWidth * 0.04,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.025),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}