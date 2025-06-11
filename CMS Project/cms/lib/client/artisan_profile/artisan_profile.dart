import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/client/artisan_profile/rate_artisan.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:herfa/client/home_screen/details_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ArtisanProfileforClient extends StatefulWidget {
  final String artisanSSN;
  const ArtisanProfileforClient({super.key, required this.artisanSSN});

  @override
  State<ArtisanProfileforClient> createState() =>
      _ArtisanProfileforClientState();
}

class _ArtisanProfileforClientState extends State<ArtisanProfileforClient> {
  bool isLoading = true;
  bool isRatingsLoading = true;
  String? errorMessage;
  String? ratingsErrorMessage;
  Artisan? artisanData;
  List<Rating> ratings = [];

  @override
  void initState() {
    super.initState();
    fetchArtisanData();
    fetchRatings();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> fetchArtisanData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    bool isConnected = await _checkInternetConnection();
    print('Internet connection for fetchArtisanData: $isConnected');
    if (!isConnected) {
      setState(() {
        errorMessage =
            "No internet connection. Please check your network and try again.";
        isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Connection Error"),
          content: const Text(
              "No internet connection. Please check your network and try again."),
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

    try {
      final apiService = ApiService();
      final data = await apiService.fetchArtisanData(widget.artisanSSN);
      print(
          'Fetched Artisan Data: SSN: "${data.ssn}", FullName: "${data.fullName}", ProfileImage: "${data.profileImage}"');
      if (data.fullName.isEmpty) {
        setState(() {
          errorMessage = "Artisan data not found.";
          isLoading = false;
        });
        return;
      }
      setState(() {
        artisanData = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error in fetchArtisanData: $e');
      setState(() {
        errorMessage = 'Failed to load artisan data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchRatings() async {
    setState(() {
      isRatingsLoading = true;
      ratingsErrorMessage = null;
    });

    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      setState(() {
        ratingsErrorMessage =
            "No internet connection. Please check your network and try again.";
        isRatingsLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Connection Error"),
          content: const Text(
              "No internet connection. Please check your network and try again."),
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

    try {
      final apiService = ApiService();
      final fetchedRatings =
          await apiService.fetchArtisanRatings(widget.artisanSSN);
      setState(() {
        ratings = fetchedRatings;
        isRatingsLoading = false;
      });
    } catch (e) {
      setState(() {
        ratingsErrorMessage = 'Failed to load ratings: $e';
        isRatingsLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> getProductDetails(int productId) async {
    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      return {
        "error":
            "No internet connection. Please check your network and try again."
      };
    }

    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse(
          "https://herfa-system-handmade.runasp.net/api/Home/product/$productId?productId=$productId");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "productId": data["Product_ID"] as int? ?? 0,
          "name": data["Name"]?.toString() ?? "Unknown",
          "price": (data["Price"] as num?)?.toDouble() ?? 0.0,
          "quantity": data["Quantity"] as int? ?? 0,
          "description": data["Description"]?.toString() ?? "",
          "ratingAverage": (data["Rating_Average"] as num?)?.toDouble() ?? 0.0,
          "status": data["Status"]?.toString() ?? "Unknown",
          "artisan": {
            "ssn": data["Artisan"]?["SSN"]?.toString() ?? "Unknown",
            "fullName": data["Artisan"]?["Full_Name"]?.toString() ?? "Unknown",
            "profileImage": data["Artisan"]?["ProfileImage"]?.toString() ?? "",
          },
          "category": data["Category"]?.toString() ?? "Unknown",
          "images": List<String>.from(data["Images"] ?? []),
        };
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          "error": responseData["message"] ??
              "Failed to load product details: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {"error": "Failed to load product details: $e"};
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isLoading || artisanData == null
              ? 'Loading...'
              : artisanData!.fullName,
          style: GoogleFonts.nunitoSans(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchArtisanData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await fetchArtisanData();
                    await fetchRatings();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            top: screenHeight * 0.05,
                            bottom: screenHeight * 0.025,
                            left: screenWidth * 0.025,
                            right: screenWidth * 0.025,
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: screenWidth * 0.15,
                                backgroundColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[600]
                                    : Colors.grey[300],
                                child: artisanData!.profileImage != null &&
                                        artisanData!.profileImage!.isNotEmpty
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: artisanData!.profileImage!,
                                          fit: BoxFit.cover,
                                          width: screenWidth * 0.3,
                                          height: screenWidth * 0.3,
                                          placeholder: (context, url) =>
                                              const Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                          errorWidget: (context, url, error) {
                                            return Icon(
                                              Icons.person,
                                              size: screenWidth * 0.075,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            );
                                          },
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: screenWidth * 0.075,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              SizedBox(height: screenHeight * 0.01),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 5),
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color(0xFF0C8A7B),
                                ),
                                onPressed: () {
                                  if (widget.artisanSSN.isEmpty) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Error"),
                                        content: const Text(
                                            'Cannot rate artisan: Invalid artisan SSN'),
                                        backgroundColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.grey[900]
                                                : Colors.white,
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RateArtisanPage(
                                        artisanSSN: widget.artisanSSN,
                                      ),
                                    ),
                                  ).then((_) => fetchRatings());
                                },
                                child: Text(
                                  'Rate me',
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: screenWidth * 0.04,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            left: 0.0,
                            right: screenWidth * 0.04,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: screenWidth * 0.35,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0C8A7B),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015,
                                horizontal: screenWidth * 0.04,
                              ),
                              child: Text(
                                'Products',
                                style: GoogleFonts.nunitoSans(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.005),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: screenWidth * 0.04,
                              mainAxisSpacing: screenWidth * 0.04,
                              childAspectRatio: 0.65,
                            ),
                            itemCount: artisanData!.products?.length ?? 0,
                            itemBuilder: (context, index) {
                              final product = artisanData!.products![index];
                              return FutureBuilder<Map<String, dynamic>>(
                                future: getProductDetails(product.productId),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError ||
                                      snapshot.data?["error"] != null) {
                                    return Card(
                                      elevation: 2,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey[900]
                                          : Colors.white,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            height: screenHeight * 0.18,
                                            width: double.infinity,
                                            child: product.images.isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: product.images[0],
                                                    fit: BoxFit.contain,
                                                    placeholder: (context,
                                                            url) =>
                                                        const Center(
                                                            child:
                                                                CircularProgressIndicator()),
                                                    errorWidget:
                                                        (context, url, error) {
                                                      return Icon(
                                                        Icons.broken_image,
                                                        size: screenWidth * 0.1,
                                                        color: Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.dark
                                                            ? Colors.grey[400]
                                                            : Colors.grey,
                                                      );
                                                    },
                                                  )
                                                : Icon(
                                                    Icons.broken_image,
                                                    size: screenWidth * 0.125,
                                                    color: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.grey[400]
                                                        : Colors.grey,
                                                  ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(
                                                screenWidth * 0.02),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style: GoogleFonts.nunitoSans(
                                                    fontSize:
                                                        screenWidth * 0.04,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                                Text(
                                                  '${product.price}LE',
                                                  style: GoogleFonts.nunitoSans(
                                                    fontSize:
                                                        screenWidth * 0.035,
                                                    color: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                                const SizedBox(height: 0),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: Text(
                                                    'Error loading stock',
                                                    style: TextStyle(
                                                      fontSize:
                                                          screenWidth * 0.04,
                                                      color: Colors.red,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  final quantity =
                                      snapshot.data!["quantity"] as int;
                                  return InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetails(
                                            product: {
                                              'ProductID': product.productId,
                                              'ProductName': product.name,
                                              'Price': product.price,
                                              'Quantity': quantity,
                                              'Description':
                                                  product.description,
                                              'Category': product.category,
                                              'Status':
                                                  snapshot.data!["status"],
                                              'Images': product.images,
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    child: Card(
                                      elevation: 2,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey[900]
                                          : Colors.white,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            height: screenHeight * 0.18,
                                            width: double.infinity,
                                            child: product.images.isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: product.images[0],
                                                    fit: BoxFit.contain,
                                                    placeholder: (context,
                                                            url) =>
                                                        const Center(
                                                            child:
                                                                CircularProgressIndicator()),
                                                    errorWidget:
                                                        (context, url, error) {
                                                      return Icon(
                                                        Icons.broken_image,
                                                        size: screenWidth * 0.1,
                                                        color: Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.dark
                                                            ? Colors.grey[400]
                                                            : Colors.grey,
                                                      );
                                                    },
                                                  )
                                                : Icon(
                                                    Icons.broken_image,
                                                    size: screenWidth * 0.125,
                                                    color: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.grey[400]
                                                        : Colors.grey,
                                                  ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(
                                                screenWidth * 0.02),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style: GoogleFonts.nunitoSans(
                                                    fontSize:
                                                        screenWidth * 0.04,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                                Text(
                                                  '${product.price}LE',
                                                  style: GoogleFonts.nunitoSans(
                                                    fontSize:
                                                        screenWidth * 0.035,
                                                    color: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                                const SizedBox(height: 0),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: quantity > 0
                                                      ? ElevatedButton(
                                                          onPressed: () async {
                                                            bool isConnected =
                                                                await _checkInternetConnection();
                                                            if (!isConnected) {
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) =>
                                                                        AlertDialog(
                                                                  title: const Text(
                                                                      "Connection Error"),
                                                                  content:
                                                                      const Text(
                                                                          "No internet connection. Please check your network and try again."),
                                                                  backgroundColor: Theme.of(context)
                                                                              .brightness ==
                                                                          Brightness
                                                                              .dark
                                                                      ? Colors.grey[
                                                                          900]
                                                                      : Colors
                                                                          .white,
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed:
                                                                          () =>
                                                                              Navigator.pop(context),
                                                                      child: const Text(
                                                                          "OK"),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                              return;
                                                            }

                                                            try {
                                                              await ApiService()
                                                                  .addToCart(product
                                                                      .productId);
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) =>
                                                                        AlertDialog(
                                                                  title: const Text(
                                                                      "Success"),
                                                                  content:
                                                                      const Text(
                                                                          'Product added to cart successfully!'),
                                                                  backgroundColor: Theme.of(context)
                                                                              .brightness ==
                                                                          Brightness
                                                                              .dark
                                                                      ? Colors.grey[
                                                                          900]
                                                                      : Colors
                                                                          .white,
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed:
                                                                          () =>
                                                                              Navigator.pop(context),
                                                                      child: const Text(
                                                                          "OK"),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            } catch (e) {
                                                              if (e
                                                                  .toString()
                                                                  .contains(
                                                                      'Product is out of stock')) {
                                                                showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (context) =>
                                                                          AlertDialog(
                                                                    title: const Text(
                                                                        "Error"),
                                                                    content:
                                                                        const Text(
                                                                            'This product is out of stock.'),
                                                                    backgroundColor: Theme.of(context).brightness ==
                                                                            Brightness
                                                                                .dark
                                                                        ? Colors.grey[
                                                                            900]
                                                                        : Colors
                                                                            .white,
                                                                    actions: [
                                                                      TextButton(
                                                                        onPressed:
                                                                            () =>
                                                                                Navigator.pop(context),
                                                                        child: const Text(
                                                                            "OK"),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              } else {
                                                                showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (context) =>
                                                                          AlertDialog(
                                                                    title: const Text(
                                                                        "Error"),
                                                                    content: Text(
                                                                        'Failed to add product to cart: $e'),
                                                                    backgroundColor: Theme.of(context).brightness ==
                                                                            Brightness
                                                                                .dark
                                                                        ? Colors.grey[
                                                                            900]
                                                                        : Colors
                                                                            .white,
                                                                    actions: [
                                                                      TextButton(
                                                                        onPressed:
                                                                            () =>
                                                                                Navigator.pop(context),
                                                                        child: const Text(
                                                                            "OK"),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              }
                                                            }
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                const Color(
                                                                    0xFF0C8A7B),
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        screenHeight *
                                                                            0.01),
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                      screenWidth *
                                                                          0.02),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            'Add to Cart',
                                                            style: GoogleFonts
                                                                .nunitoSans(
                                                              fontSize:
                                                                  screenWidth *
                                                                      0.035,
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        )
                                                      : Text(
                                                          'Product is out of stock',
                                                          style: TextStyle(
                                                            fontSize:
                                                                screenWidth *
                                                                    0.04,
                                                            color: Colors.red,
                                                            fontStyle: FontStyle
                                                                .italic,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Padding(
                          padding: EdgeInsets.only(
                            left: 0.0,
                            right: screenWidth * 0.04,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: screenWidth * 0.325,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0C8A7B),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015,
                                horizontal: screenWidth * 0.04,
                              ),
                              child: Text(
                                'Reviews',
                                style: GoogleFonts.nunitoSans(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04),
                          child: isRatingsLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ratingsErrorMessage != null
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(ratingsErrorMessage!),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: fetchRatings,
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ratings.isEmpty
                                      ? Center(
                                          child: Text(
                                            "No reviews available",
                                            style: GoogleFonts.nunitoSans(
                                              fontSize: screenWidth * 0.04,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        )
                                      : Column(
                                          children: ratings.map((rating) {
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                  bottom: screenHeight * 0.02),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  CircleAvatar(
                                                    radius: screenWidth * 0.05,
                                                    backgroundColor: Theme.of(
                                                                    context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.grey[600]
                                                        : Colors.grey[300],
                                                    child: rating.clientImage !=
                                                                null &&
                                                            rating.clientImage!
                                                                .isNotEmpty
                                                        ? ClipOval(
                                                            child:
                                                                CachedNetworkImage(
                                                              imageUrl: rating
                                                                  .clientImage!,
                                                              fit: BoxFit.cover,
                                                              width:
                                                                  screenWidth *
                                                                      0.1,
                                                              height:
                                                                  screenWidth *
                                                                      0.1,
                                                              placeholder: (context,
                                                                      url) =>
                                                                  const Center(
                                                                      child:
                                                                          CircularProgressIndicator()),
                                                              errorWidget:
                                                                  (context, url,
                                                                      error) {
                                                                return Icon(
                                                                  Icons.person,
                                                                  color: Colors
                                                                      .white,
                                                                );
                                                              },
                                                            ),
                                                          )
                                                        : Icon(
                                                            Icons.person,
                                                            color: Colors.white,
                                                          ),
                                                  ),
                                                  SizedBox(
                                                      width:
                                                          screenWidth * 0.03),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              rating.userName ??
                                                                  "Unknown",
                                                              style: GoogleFonts
                                                                  .nunitoSans(
                                                                fontSize:
                                                                    screenWidth *
                                                                        0.04,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Theme.of(context)
                                                                            .brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                              ),
                                                            ),
                                                            Text(
                                                              rating.createdAt !=
                                                                      null
                                                                  ? _formatTimeAgo(
                                                                      rating
                                                                          .createdAt!)
                                                                  : "Unknown",
                                                              style: GoogleFonts
                                                                  .nunitoSans(
                                                                fontSize:
                                                                    screenWidth *
                                                                        0.035,
                                                                color: Theme.of(context)
                                                                            .brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Colors.grey[
                                                                        400]
                                                                    : Colors
                                                                        .grey,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Row(
                                                          children:
                                                              List.generate(
                                                            5,
                                                            (index) => Icon(
                                                              Icons.star,
                                                              color: index <
                                                                      rating
                                                                          .artisanRate
                                                                          .toInt()
                                                                  ? const Color(
                                                                      0xFF0C8A7B)
                                                                  : Theme.of(context)
                                                                              .brightness ==
                                                                          Brightness
                                                                              .dark
                                                                      ? Colors.grey[
                                                                          600]
                                                                      : Colors.grey[
                                                                          300],
                                                              size:
                                                                  screenWidth *
                                                                      0.04,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                            height:
                                                                screenHeight *
                                                                    0.005),
                                                        Text(
                                                          rating.comment ?? "",
                                                          style: GoogleFonts
                                                              .nunitoSans(
                                                            fontSize:
                                                                screenWidth *
                                                                    0.035,
                                                            color: Theme.of(context)
                                                                        .brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? Colors.white
                                                                : Colors.black,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                        ),
                        SizedBox(height: screenHeight * 0.1),
                      ],
                    ),
                  ),
                ),
    );
  }
}
