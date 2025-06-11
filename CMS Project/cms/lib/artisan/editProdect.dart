import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import '../Shared Files/databaseHelper.dart';

class Edit_Product extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  Edit_Product({required this.productId, required this.productData});

  @override
  _Edit_Product createState() => _Edit_Product();
}

class _Edit_Product extends State<Edit_Product> {
  int quantity = 0;
  String selectedStatus = 'Available';
  String selectedCategory = '';
  List<String> categories = [
    'Accessories',
    'Bags',
    'Clothes',
    'Wood',
    'Flowers',
    'Mobile Cover',
    'Decore',
    'Pottery',
    'Blacksmithing',
    'Textiles'
  ];
  List<XFile> _selectedImages = [];
  List<String> _existingImages = [];
  List<int> _imagesToDelete = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ApiService _apiService = ApiService();
  final String _baseUrl = "https://herfa-system-handmade.runasp.net/";
  Interpreter? _interpreter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProductData();
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

  Future<void> _fetchProductData() async {
    try {
      final productsData = await _apiService.getProducts();
      if (productsData.containsKey("error")) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Error"),
            content: Text('Error fetching product: ${productsData["error"]}'),
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

      final products = productsData['Products'] as List<dynamic>? ?? [];
      final productData = products.firstWhere(
        (product) => product['ProductID'].toString() == widget.productId,
        orElse: () => null,
      );

      if (productData == null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Error"),
            content: Text('Product not found'),
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
        _nameController.text = productData['ProductName'] ??
            productData['Name'] ??
            productData['Product_Name'] ??
            '';
        _priceController.text = productData['Price']?.toString() ??
            productData['Product_Price']?.toString() ??
            '';
        _descriptionController.text = productData['Description'] ??
            productData['Product_Description'] ??
            '';
        quantity = productData['Quantity']?.toInt() ??
            productData['Product_Quantity']?.toInt() ??
            0;
        String category = productData['Category'] ??
            productData['CategoryName'] ??
            productData['Cat_Type'] ??
            '';
        selectedCategory = category.isNotEmpty
            ? categories.firstWhere(
                (cat) => cat.toLowerCase() == category.toLowerCase(),
                orElse: () => '',
              )
            : '';
        selectedStatus = productData['Status']?.toString() ?? 'Available';

        if (productData['Images'] != null && productData['Images'] is List) {
          _existingImages = (productData['Images'] as List<dynamic>).map((img) {
            if (img is Map && img.containsKey('Url')) {
              return img['Url'].toString();
            } else if (img is String) {
              return img.startsWith('http') ? img : '$_baseUrl$img';
            }
            return '';
          }).where((url) => url.isNotEmpty).cast<String>().toList();
        } else if (productData['Product_Images'] != null &&
            productData['Product_Images'] is List) {
          _existingImages = (productData['Product_Images'] as List<dynamic>).map((img) {
            if (img is Map && img.containsKey('Url')) {
              return img['Url'].toString();
            } else if (img is String) {
              return img.startsWith('http') ? img : '$_baseUrl$img';
            }
            return '';
          }).where((url) => url.isNotEmpty).cast<String>().toList();
        } else {
          _existingImages = [];
        }
      });
    } catch (e) {
      setState(() {
        _nameController.text = widget.productData['ProductName'] ??
            widget.productData['Name'] ??
            widget.productData['Product_Name'] ??
            '';
        _priceController.text = widget.productData['Price']?.toString() ??
            widget.productData['Product_Price']?.toString() ??
            '';
        _descriptionController.text = widget.productData['Description'] ??
            widget.productData['Product_Description'] ??
            '';
        quantity = widget.productData['Quantity']?.toInt() ??
            widget.productData['Product_Quantity']?.toInt() ??
            0;
        String category = widget.productData['Category'] ??
            widget.productData['CategoryName'] ??
            widget.productData['Cat_Type'] ??
            '';
        selectedCategory = category.isNotEmpty
            ? categories.firstWhere(
                (cat) => cat.toLowerCase() == category.toLowerCase(),
                orElse: () => '',
              )
            : '';
        selectedStatus = widget.productData['Status']?.toString() ?? 'Available';

        if (widget.productData['Images'] != null &&
            widget.productData['Images'] is List) {
          _existingImages = (widget.productData['Images'] as List<dynamic>).map((img) {
            if (img is Map && img.containsKey('Url')) {
              return img['Url'].toString();
            } else if (img is String) {
              return img.startsWith('http') ? img : '$_baseUrl$img';
            }
            return '';
          }).where((url) => url.isNotEmpty).cast<String>().toList();
        } else if (widget.productData['Product_Images'] != null &&
            widget.productData['Product_Images'] is List) {
          _existingImages = (widget.productData['Product_Images'] as List<dynamic>).map((img) {
            if (img is Map && img.containsKey('Url')) {
              return img['Url'].toString();
            } else if (img is String) {
              return img.startsWith('http') ? img : '$_baseUrl$img';
            }
            return '';
          }).where((url) => url.isNotEmpty).cast<String>().toList();
        } else {
          _existingImages = [];
        }
      });
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
          imageMatrix[pixelIndex++] = pixel.r / 255.0;
          imageMatrix[pixelIndex++] = pixel.g / 255.0;
          imageMatrix[pixelIndex++] = pixel.b / 255.0;
        }
      }

      final input = imageMatrix.reshape([1, 224, 224, 3]);
      final output = List.filled(1 * 2, 0.0).reshape([1, 2]);

      _interpreter!.run(input, output);

      final prediction = output[0] as List<double>;
      final maxConfidence = prediction.reduce((a, b) => a > b ? a : b);
      final classId = prediction.indexOf(maxConfidence);

      if (classId == 1 && maxConfidence >= 0.4) {
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

  Future<void> _editProduct() async {
    // ignore: unnecessary_null_comparison
    if (widget.productId == null || widget.productId.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text("Product ID is missing"),
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
    if (quantity < 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Input Error"),
          content: Text("Quantity cannot be less than 0"),
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
    if (images.isEmpty && _existingImages.isEmpty) {
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

    final List<String> formattedExistingImages = _existingImages.map((url) {
      return url.startsWith(_baseUrl) ? url.replaceFirst(_baseUrl, '') : url;
    }).toList();

    final List<int> imagesToDelete = [];

    final result = await _apiService.editProduct(
      productId: widget.productId,
      name: name,
      price: double.parse(priceText),
      quantity: quantity,
      description: description,
      images: images,
      existingImages: formattedExistingImages,
      catType: selectedCategory,
      status: selectedStatus,
      imagesToDelete: imagesToDelete,
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
          content: Text("Product updated successfully!"),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final productsData = await _apiService.getProducts();
                if (productsData.containsKey("error")) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Error"),
                      content: Text('Error fetching updated product: ${productsData["error"]}'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context, true);
                          },
                          child: Text("OK"),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                final products = productsData['Products'] as List<dynamic>? ?? [];
                final updatedProduct = result['UpdatedProduct'] ?? products.firstWhere(
                  (product) => product['ProductID'].toString() == widget.productId,
                  orElse: () => null,
                );

                if (updatedProduct == null) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Error"),
                      content: Text('Updated product not found'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context, true);
                          },
                          child: Text("OK"),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                setState(() {
                  if (updatedProduct['Images'] != null && updatedProduct['Images'] is List) {
                    _existingImages = (updatedProduct['Images'] as List<dynamic>).map((img) {
                      if (img is Map && img.containsKey('Url')) {
                        return img['Url'].toString();
                      } else if (img is String) {
                        return img.startsWith('http') ? img : '$_baseUrl$img';
                      }
                      return '';
                    }).where((url) => url.isNotEmpty).cast<String>().toList();
                  } else if (updatedProduct['Product_Images'] != null &&
                      updatedProduct['Product_Images'] is List) {
                    _existingImages = (updatedProduct['Product_Images'] as List<dynamic>).map((img) {
                      if (img is Map && img.containsKey('Url')) {
                        return img['Url'].toString();
                      } else if (img is String) {
                        return img.startsWith('http') ? img : '$_baseUrl$img';
                      }
                      return '';
                    }).where((url) => url.isNotEmpty).cast<String>().toList();
                  } else {
                    _existingImages = [];
                  }
                  _imagesToDelete.clear();
                  _nameController.clear();
                  _priceController.clear();
                  _descriptionController.clear();
                  quantity = 0;
                  _selectedImages.clear();
                  selectedCategory = '';
                  selectedStatus = 'Available';
                });

                Navigator.pop(context, updatedProduct);
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _onRefresh() async {
    await _fetchProductData();
    setState(() => _imagesToDelete.clear());
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
                  vertical: screenWidth * 0.0375, horizontal: screenWidth * 0.0375),
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

    if (quantity == 0 && selectedStatus != 'Not Available') {
      setState(() {
        selectedStatus = 'Not Available';
      });
    } else if (quantity > 0 && selectedStatus == 'Not Available') {
      setState(() {
        selectedStatus = 'Available';
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        title:  Text(
            "Edit Product",
            style: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.bold,
              textStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontSize: screenWidth * 0.06,
                decoration: TextDecoration.none,
              ),
            ),
          
        ),
      ),
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
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
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Color(0xFF0C8A7B),
                                        width: 1.2,
                                      ),
                                      borderRadius: BorderRadius.circular(screenWidth * 0.025),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove, color: Colors.grey),
                                          onPressed: () => setState(() {
                                            if (quantity > 0) {
                                              quantity--;
                                              if (quantity == 0) {
                                                selectedStatus = 'Not Available';
                                              }
                                            }
                                          }),
                                        ),
                                        Text(
                                          quantity.toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.add,
                                            color: Color.fromARGB(255, 8, 103, 92),
                                          ),
                                          onPressed: () => setState(() {
                                            quantity++;
                                            if (quantity > 0 && selectedStatus == 'Not Available') {
                                              selectedStatus = 'Available';
                                            }
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    left: screenWidth * 0.0375,
                                    top: -screenWidth * 0.035,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.0125),
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.black
                                          : Colors.white,
                                      child: Text(
                                        "Quantity",
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.045,
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
                      ],
                    ),
                    Padding(padding: EdgeInsets.only(bottom: screenHeight * 0.025)),
                    SizedBox(
                      width: screenWidth * 0.825,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                          child: _buildTextFieldWithLabel(
                            controller: _descriptionController,
                            label: "Description",
                            maxLines: 5,
                            width: screenWidth * 0.825,
                          ),
                        ),
                      ),
                    ),
                    Padding(padding: EdgeInsets.only(bottom: screenHeight * 0.025)),
                    SizedBox(
                      width: screenWidth * 0.825,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: EdgeInsets.all(screenWidth * 0.025),
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xFF0C8A7B), width: 1.2),
                                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black
                                    : Colors.white,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_existingImages.isNotEmpty)
                                    Wrap(
                                      spacing: screenWidth * 0.02,
                                      runSpacing: screenWidth * 0.02,
                                      children: _existingImages
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        // ignore: unused_local_variable
                                        int index = entry.key;
                                        String imageUrl = entry.value;
                                        return Container(
                                          width: screenWidth * 0.225,
                                          height: screenWidth * 0.225,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                            image: DecorationImage(
                                              image: CachedNetworkImageProvider(
                                                imageUrl,
                                                cacheKey: imageUrl +
                                                    DateTime.now()
                                                        .millisecondsSinceEpoch
                                                        .toString(),
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  if (_selectedImages.isNotEmpty)
                                    Wrap(
                                      spacing: screenWidth * 0.02,
                                      runSpacing: screenWidth * 0.02,
                                      children: _selectedImages
                                          .asMap()
                                          .entries
                                          .map((entry) {
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
                                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                                  ),
                                                ),
                                                content: Text(
                                                  "Are you sure you want to delete this image?",
                                                  style: TextStyle(
                                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: Text(
                                                      "Cancel",
                                                      style: TextStyle(
                                                        color: Theme.of(context).textTheme.bodyLarge?.color,
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
                                              borderRadius: BorderRadius.circular(screenWidth * 0.02),
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
                              left: screenWidth * 0.0375,
                              top: -screenWidth * 0.035,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.0125),
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black
                                    : Colors.white,
                                child: Text(
                                  "Images",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
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
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                              child: DropdownButtonFormField<String>(
                                value: selectedCategory.isEmpty ? null : selectedCategory,
                                items: categories.map((category) {
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedCategory = value ?? '';
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: "Category",
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
                                      vertical: screenWidth * 0.0375, horizontal: screenWidth * 0.025),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF0C8A7B),
                                      width: 1.2,
                                    ),
                                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF0C8A7B),
                                      width: 1.2,
                                    ),
                                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.black
                                      : Colors.white,
                                ),
                                dropdownColor: Theme.of(context).brightness == Brightness.dark
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
                    SizedBox(
                      width: screenWidth * 0.5,
                      height: screenWidth * 0.13,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                          child: DropdownButtonFormField<String>(
                            value: selectedStatus,
                            items: ['Available', 'Not Available']
                                .map((status) => DropdownMenuItem<String>(
                                      value: status,
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                    ),
                                  )).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedStatus = value ?? 'Available';
                              });
                            },
                            decoration: InputDecoration(
                              labelText: "Status",
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
                                  vertical: screenWidth * 0.0375, horizontal: screenWidth * 0.025),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFF0C8A7B),
                                  width: 1.2,
                                ),
                                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFF0C8A7B),
                                  width: 1.2,
                                ),
                                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black
                                  : Colors.white,
                            ),
                            dropdownColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Padding(padding: EdgeInsets.only(bottom: screenHeight * 0.025)),
                    TextButton(
                      onPressed: _editProduct,
                      child: Container(
                        width: screenWidth * 0.75,
                        height: screenHeight * 0.0875,
                        decoration: BoxDecoration(
                          color: Color(0xFF0C8A7B),
                          borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        ),
                        child: Align(
                          child: Text(
                            "Edit",
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