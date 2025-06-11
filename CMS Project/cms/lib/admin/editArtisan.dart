import 'package:flutter/material.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:intl/intl.dart';

class EditArtisanScreen extends StatefulWidget {
  final Map<String, dynamic> artisan;

  const EditArtisanScreen({required this.artisan});

  @override
  _EditArtisanScreenState createState() => _EditArtisanScreenState();
}

class _EditArtisanScreenState extends State<EditArtisanScreen> {
  late TextEditingController fullNameController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController birthDateController;
  String gender = "Male";
  bool isLoading = false;

  bool isFullNameEmpty = false;
  bool isPhoneEmpty = false;
  bool isPhoneInvalid = false;
  bool isAddressEmpty = false;
  bool isBirthDateEmpty = false;

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController(text: widget.artisan["Full_Name"] ?? '');
    phoneController = TextEditingController(text: widget.artisan["Phone"] ?? '');
    addressController = TextEditingController(text: widget.artisan["Address"] ?? '');
    try {
      birthDateController = TextEditingController(
        text: widget.artisan["Birth_Date"] != null
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.artisan["Birth_Date"]))
            : '',
      );
    } catch (e) {
      birthDateController = TextEditingController(text: '');
    }
    gender = widget.artisan["Gender"] ?? "Male";
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

  bool validateFields() {
    setState(() {
      isFullNameEmpty = fullNameController.text.trim().isEmpty;
      isPhoneEmpty = phoneController.text.trim().isEmpty;
      isAddressEmpty = addressController.text.trim().isEmpty;
      isBirthDateEmpty = birthDateController.text.trim().isEmpty;

      if (!isPhoneEmpty) {
        final phonePattern = RegExp(r'^[0-9]+$');
        isPhoneInvalid = !phonePattern.hasMatch(phoneController.text) || phoneController.text.length < 10;
      } else {
        isPhoneInvalid = false;
      }
    });

    return !isFullNameEmpty && !isPhoneEmpty && !isPhoneInvalid && !isAddressEmpty && !isBirthDateEmpty;
  }

  Future<void> updateArtisan() async {
    bool hasChanges = fullNameController.text != (widget.artisan["Full_Name"] ?? '') ||
        phoneController.text != (widget.artisan["Phone"] ?? '') ||
        addressController.text != (widget.artisan["Address"] ?? '') ||
        birthDateController.text !=
            (widget.artisan["Birth_Date"] != null
                ? DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.artisan["Birth_Date"]))
                : '') ||
        gender != (widget.artisan["Gender"] ?? "Male");

    if (!hasChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("No Changes"),
          content: const Text("You did not make any edits."),
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

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService().updateArtisan(
        ssn: widget.artisan["SSN"],
        fullName: fullNameController.text,
        phone: phoneController.text,
        address: addressController.text,
        birthDate: DateFormat('dd/MM/yyyy').parse(birthDateController.text).toIso8601String(),
        gender: gender,
      );

      setState(() {
        isLoading = false;
      });

      if (result.containsKey("error")) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Update Failed"),
            content: const Text("Please check your internet connection."),
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
            content: Text(result["message"] ?? "Artisan updated successfully"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text("OK"),
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
          title: const Text("Error"),
          content: const Text("Please check your internet connection."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.artisan["Birth_Date"] != null
          ? DateTime.parse(widget.artisan["Birth_Date"])
          : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Artisan",
          style: TextStyle(
            fontSize: screenWidth * 0.05,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  fullNameController.text = widget.artisan["Full_Name"] ?? '';
                  phoneController.text = widget.artisan["Phone"] ?? '';
                  addressController.text = widget.artisan["Address"] ?? '';
                  birthDateController.text = widget.artisan["Birth_Date"] != null
                      ? DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.artisan["Birth_Date"]))
                      : '';
                  setState(() {
                    gender = widget.artisan["Gender"] ?? "Male";
                    isFullNameEmpty = false;
                    isPhoneEmpty = false;
                    isPhoneInvalid = false;
                    isAddressEmpty = false;
                    isBirthDateEmpty = false;
                  });
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Full Name",
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                      TextField(
                        controller: fullNameController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          errorBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          errorText: isFullNameEmpty ? "This field cannot be empty" : null,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Date of Birth",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                  ),
                                ),
                                TextField(
                                  controller: birthDateController,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    suffixIcon: const Icon(Icons.calendar_today),
                                    errorBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.red),
                                    ),
                                    focusedErrorBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.red),
                                    ),
                                    errorText: isBirthDateEmpty ? "This field cannot be empty" : null,
                                  ),
                                  readOnly: true,
                                  onTap: () => selectDate(context),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Phone number",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                  ),
                                ),
                                TextField(
                                  controller: phoneController,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    errorBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.red),
                                    ),
                                    focusedErrorBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.red),
                                    ),
                                    errorText: isPhoneEmpty
                                        ? "This field cannot be empty"
                                        : isPhoneInvalid
                                            ? "Enter a valid phone number (at least 10 digits)"
                                            : null,
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        "Gender",
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
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
                          const Text("Male"),
                          Radio<String>(
                            value: "Female",
                            groupValue: gender,
                            onChanged: (value) {
                              setState(() {
                                gender = value!;
                              });
                            },
                          ),
                          const Text("Female"),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        "Address",
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                      TextField(
                        controller: addressController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          errorBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          errorText: isAddressEmpty ? "This field cannot be empty" : null,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.025),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            if (validateFields()) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Confirm Edit"),
                                  content: Text("Are you sure you want to edit ${fullNameController.text}?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        updateArtisan();
                                      },
                                      child: const Text("Edit"),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          child: Text(
                            "Edit",
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C8A7B),
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.125,
                              vertical: screenHeight * 0.01875,
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