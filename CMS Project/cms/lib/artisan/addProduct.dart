import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/artisan/myProfile.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import '../Shared Files/databaseHelper.dart';

class Add_Product extends StatefulWidget {
  @override
  _Add_Product createState() => _Add_Product();
}

class _Add_Product extends State<Add_Product> {
  int quantity = 0;
  List<String> categories = [
    'Accessories',
    'Bags',
    'Clothes',
    'Wood',
    'Flowers',
    'Mobile Cover',
    'Decor',
    'Pottery',
    'Blacksmith',
    'Textiles'
  ];
  String selectedCategory = '';
  List<XFile> _selectedImages = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ApiService _apiService = ApiService();
  Interpreter? _interpreter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model_no_quant.tflite');
      setState(() {});
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Model Error"),
          content: Text("Failed to load the classification model. Please try again later."),
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

  Future<void> _pickImages() async {
    final ImagePicker _picker = ImagePicker();
    final List<XFile>? pickedImages = await _picker.pickMultiImage();

    if (pickedImages != null && pickedImages.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      List<XFile> validImages = [];
      for (var image in pickedImages) {
        bool isHandmade = await _classifyImage(File(image.path));
        if (!isHandmade) {
          setState(() {
            _isLoading = false;
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Invalid Product"),
              content: Text(
                  "One or more images were classified as Machine-made (50% or more). Machine-made products are not allowed. Please upload Handmade products only."),
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
        validImages.add(image);
      }

      setState(() {
        _selectedImages.addAll(validImages);
        _isLoading = false;
      });
    }
  }

  Future<bool> _classifyImage(File imageFile) async {
    if (_interpreter == null) {
      return false;
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        return false;
      }

      
      image = img.copyResize(image, width: 224, height: 224);

      
      final imageMatrix = Float32List(1 * 224 * 224 * 3);
      int pixelIndex = 0;
      for (var y = 0; y < 224; y++) {
        for (var x = 0; x < 224; x++) {
          final pixel = image.getPixel(x, y);
          imageMatrix[pixelIndex++] = pixel.r / 255.0; // R
          imageMatrix[pixelIndex++] = pixel.g / 255.0; // G
          imageMatrix[pixelIndex++] = pixel.b / 255.0; // B
        }
      }

      
      final input = imageMatrix.reshape([1, 224, 224, 3]);
      final output = List.filled(1 * 2, 0.0).reshape([1, 2]);

      
      _interpreter!.run(input, output);

      
      final prediction = output[0] as List<double>;
      final maxConfidence = prediction.reduce((a, b) => a > b ? a : b);
      final classId = prediction.indexOf(maxConfidence);

      
      if (classId == 1 && maxConfidence * 100 >= 40) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
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

  Future<void> _addProduct() async {
    final String name = _nameController.text.trim();
    final String priceText = _priceController.text.trim();
    final String description = _descriptionController.text.trim();
    final List<File> images =
        _selectedImages.map((xFile) => File(xFile.path)).toList();

    if (name.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Input Error"),
          content: Text("Please enter product name"),
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
    if (priceText.isEmpty || double.tryParse(priceText) == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Input Error"),
          content: Text("Please enter a valid price"),
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
    if (quantity <= 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Input Error"),
          content: Text("Please set a quantity greater than 0"),
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
    if (description.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Input Error"),
          content: Text("Please enter a description"),
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
    if (images.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Input Error"),
          content: Text("Please select at least one image"),
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
    if (selectedCategory.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Input Error"),
          content: Text("Please select a category"),
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

    final result = await _apiService.addProduct(
      name: name,
      price: double.parse(priceText),
      quantity: quantity,
      description: description,
      images: images,
      catType: selectedCategory,
    );

    if (result.containsKey('error')) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text("Error: ${result["error"]}"),
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
          content: Text("Product added successfully!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _nameController.clear();
                _priceController.clear();
                _descriptionController.clear();
                setState(() {
                  quantity = 0;
                  _selectedImages.clear();
                  selectedCategory = '';
                });
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => MainProfilePage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _nameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      quantity = 0;
      _selectedImages.clear();
      selectedCategory = '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _interpreter?.close();
    super.dispose();
  }

  Widget _buildTextFieldWithLabel({
    required TextEditingController controller,
    required String label,
    int? maxLines,
    TextInputType? keyboardType,
    double? width,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: width ?? double.infinity,
      height: maxLines != null ? null : screenWidth * 0.13,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontSize: screenWidth * 0.045,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontWeight: FontWeight.bold,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              floatingLabelStyle: TextStyle(
                fontSize: screenWidth * 0.045,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontWeight: FontWeight.bold,
              ),
              contentPadding: EdgeInsets.symmetric(
                  vertical: screenWidth * 0.0375,
                  horizontal: screenWidth * 0.0375),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF0C8A7B), width: 1.2),
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF0C8A7B)),
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
              ),
            ),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
    );
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
        title: Align(
          alignment: Alignment.center,
          child: Text(
            "Add Product",
            style: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.bold,
              textStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color.fromARGB(255, 0, 0, 0),
                fontSize: screenWidth * 0.06,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.05,
                screenWidth * 0.05,
                screenWidth * 0.05,
                screenHeight * 0.01,
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: screenHeight * 0.025),
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF0C8A7B),
                          Color(0xFF16BFA9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(screenWidth * 0.0375),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: screenWidth * 0.06,
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Text(
                            "Important Note:\nPlease do not use multiple colors for a single product. If your product has multiple colors, add each color as a separate item. This helps customers easily choose their preferred color without confusion.\n"
                            "Make sure your handmade product images are clear and that there are no other items around them to prevent distracting the model.",
                            style: GoogleFonts.nunitoSans(
                              color: Colors.white,
                              fontSize: screenWidth * 0.035,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTextFieldWithLabel(
                        controller: _nameController,
                        label: "Name",
                        width: screenWidth * 0.5,
                      ),
                      SizedBox(
                        width: screenWidth * 0.375,
                        height: screenWidth * 0.13,
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.025),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Color(0xFF0C8A7B),
                                      width: 1.2,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(screenWidth * 0.025),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove, color: Colors.grey),
                                        onPressed: () => setState(() {
                                          if (quantity > 0) quantity--;
                                        }),
                                      ),
                                      Text(
                                        quantity.toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.add,
                                          color: Color.fromARGB(255, 8, 103, 92),
                                        ),
                                        onPressed: () => setState(() {
                                          quantity++;
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  left: screenWidth * 0.025,
                                  top: -screenWidth * 0.025,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.02,
                                        vertical: screenWidth * 0.005),
                                    color:
                                        Theme.of(context).brightness == Brightness.dark
                                            ? Colors.black
                                            : Colors.white,
                                    child: Text(
                                      "Quantity",
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.0325,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : const Color.fromARGB(255, 0, 0, 0),
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
                    ],
                  ),
                  Padding(padding: EdgeInsets.only(bottom: screenHeight * 0.025)),
                  SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                        child: _buildTextFieldWithLabel(
                          controller: _descriptionController,
                          label: "Description",
                          maxLines: 5,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                  Padding(padding: EdgeInsets.only(bottom: screenHeight * 0.025)),
                  SizedBox(
                    width: screenWidth * 0.825,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: EdgeInsets.all(screenWidth * 0.025),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Color(0xFF0C8A7B), width: 1.2),
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.025),
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black
                                  : Colors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_selectedImages.isNotEmpty)
                                  Wrap(
                                    spacing: screenWidth * 0.02,
                                    runSpacing: screenWidth * 0.02,
                                    children: _selectedImages.asMap().entries.map((entry) {
                                      int index = entry.key;
                                      XFile image = entry.value;
                                      return GestureDetector(
                                        onLongPress: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(
                                                "Delete image",
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.color,
                                                ),
                                              ),
                                              content: Text(
                                                "Are you sure you want to delete this image?",
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.color,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text(
                                                    "Cancel",
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.color,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedImages.removeAt(index);
                                                    });
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text(
                                                    "Delete",
                                                    style: TextStyle(color: Colors.red),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: screenWidth * 0.225,
                                          height: screenWidth * 0.225,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                screenWidth * 0.02),
                                            image: DecorationImage(
                                              image: FileImage(File(image.path)),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: IconButton(
                                    onPressed: _pickImages,
                                    icon: Icon(Icons.add_a_photo_outlined),
                                    color: Color(0xFF0C8A7B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: screenWidth * 0.025,
                            top: -screenWidth * 0.025,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.02,
                                  vertical: screenWidth * 0.005),
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black
                                  : Colors.white,
                              child: Text(
                                "Images",
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
                  Padding(padding: EdgeInsets.only(bottom: screenHeight * 0.025)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: screenWidth * 0.5,
                        height: screenWidth * 0.13,
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.025),
                            child: DropdownButtonFormField<String>(
                              value: selectedCategory.isEmpty ? null : selectedCategory,
                              items: categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCategory = value!;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: "Category",
                                labelStyle: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  color:
                                      Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                floatingLabelStyle: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  color:
                                      Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: screenWidth * 0.0375,
                                    horizontal: screenWidth * 0.0375),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFF0C8A7B),
                                    width: 1.2,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(screenWidth * 0.025),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFF0C8A7B),
                                    width: 1.2,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(screenWidth * 0.025),
                                ),
                              ),
                              dropdownColor:
                                  Theme.of(context).brightness == Brightness.dark
                                      ? Colors.black
                                      : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      _buildTextFieldWithLabel(
                        controller: _priceController,
                        label: "Price",
                        keyboardType: TextInputType.number,
                        width: screenWidth * 0.375,
                      ),
                    ],
                  ),
                  Padding(padding: EdgeInsets.only(bottom: screenHeight * 0.025)),
                  TextButton(
                    onPressed: _addProduct,
                    child: Container(
                      width: screenWidth * 0.75,
                      height: screenHeight * 0.0875,
                      decoration: BoxDecoration(
                        color: Color(0xFF0C8A7B),
                        borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      ),
                      child: Align(
                        child: Text(
                          "Add",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}