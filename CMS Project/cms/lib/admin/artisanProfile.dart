import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/admin/productDetails.dart';
import '../Shared Files/databaseHelper.dart';

class ArtisanProfile extends StatefulWidget {
  final String ssn;
  const ArtisanProfile({super.key, required this.ssn});
  @override
  _ArtisanProfileState createState() => _ArtisanProfileState();
}

class _ArtisanProfileState extends State<ArtisanProfile> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _artisanProfileFuture;
  late Future<bool> _artisanStatusFuture;
  late Future<Map<String, dynamic>> _ratingsFuture;
  Map<int, double> ratingDistribution = {
    5: 0.0,
    4: 0.0,
    3: 0.0,
    2: 0.0,
    1: 0.0
  };

  @override
  void initState() {
    super.initState();
    _refreshArtisanProfile();
    _refreshArtisanStatus();
    _refreshRatings();
  }

  void _refreshArtisanProfile() {
    setState(() {
      _artisanProfileFuture = _apiService.getArtisanProfile(widget.ssn);
    });
  }

  void _refreshArtisanStatus() {
    setState(() {
      _artisanStatusFuture = _apiService.getAllArtisans().then((artisans) {
        if (artisans.isNotEmpty && artisans[0].containsKey("error")) {
          return false;
        }
        final artisan = artisans.firstWhere(
          (artisan) => artisan["SSN"] == widget.ssn,
          orElse: () => {"Active": false},
        );
        return artisan["Active"] == true;
      });
    });
  }

  void _refreshRatings() {
    setState(() {
      _ratingsFuture =
          _apiService.getArtisanRatings(widget.ssn).then((ratings) {
        if (ratings.containsKey("error")) {
          throw Exception(ratings["error"]);
        }

        List<dynamic> ratingsList = ratings["ratings"] ?? [];
        if (ratingsList.isNotEmpty) {
          Map<int, int> ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
          for (var rating in ratingsList) {
            int ratingValue = (rating["Artisan_Rate"] as num).toInt();
            ratingCounts[ratingValue] = (ratingCounts[ratingValue] ?? 0) + 1;
          }
          ratingDistribution = ratingCounts.map((rating, count) => MapEntry(
                rating,
                ratingsList.isNotEmpty
                    ? (count / ratingsList.length) * 100
                    : 0.0,
              ));
        }
        return ratings;
      });
    });
  }

  Future<void> _onRefresh() async {
    _refreshArtisanProfile();
    _refreshArtisanStatus();
    _refreshRatings();
  }

  Future<void> _toggleArtisan(
      {required String artisanName, required bool isActive}) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Confirm Toggle",
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          isActive
              ? "Are you sure you want to deactivate the account of $artisanName?"
              : "Are you sure you want to activate the account of $artisanName?",
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              "Cancel",
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await _apiService.toggleArtisan(ssn: widget.ssn);
              if (result.containsKey("error")) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Connection Error'),
                    content: Text('Please check your internet connection.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Success'),
                    content: Text(result["message"] ??
                        "Artisan status toggled successfully"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _refreshArtisanProfile();
                          _refreshArtisanStatus();
                        },
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: Text(
              "Yes",
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
        ],
      ),
    );
  }

  String formatRelativeTime(String createdAt) {
    try {
      DateTime dateTime = DateTime.parse(createdAt).toUtc();

      if (dateTime.year <= 1) {
        return "Unknown date";
      }

      DateTime now = DateTime.now().toUtc();
      Duration difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return "Just now";
      } else if (difference.inMinutes < 60) {
        return "${difference.inMinutes}m ago";
      } else if (difference.inHours < 24) {
        return "${difference.inHours}h ago";
      } else if (difference.inDays < 30) {
        return "${difference.inDays}d ago";
      } else if (difference.inDays < 365) {
        int months = (difference.inDays / 30).floor();
        return "${months}mo ago";
      } else {
        int years = (difference.inDays / 365).floor();
        return "${years}y ago";
      }
    } catch (e) {
      return "Unknown date";
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Artisan Profile',
          style: GoogleFonts.nunitoSans(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FutureBuilder<Map<String, dynamic>>(
                future: _artisanProfileFuture,
                builder: (context, profileSnapshot) {
                  return FutureBuilder<bool>(
                    future: _artisanStatusFuture,
                    builder: (context, statusSnapshot) {
                      String artisanName = 'Unknown Artisan';
                      String? imageUrl;
                      bool isActive = false;

                      if (profileSnapshot.connectionState ==
                              ConnectionState.done &&
                          !profileSnapshot.hasError &&
                          profileSnapshot.data != null) {
                        final artisanData = profileSnapshot.data!;

                        if (!artisanData.containsKey("error")) {
                          artisanName = artisanData["fullName"]?.toString() ??
                              'Unknown Artisan';
                          imageUrl = artisanData['profileImage']?.toString();
                        }
                      }

                      if (statusSnapshot.connectionState ==
                              ConnectionState.done &&
                          !statusSnapshot.hasError &&
                          statusSnapshot.data != null) {
                        isActive = statusSnapshot.data!;
                      }

                      return Padding(
                        padding: EdgeInsets.only(
                          top: screenHeight * 0.018,
                          bottom: screenHeight * 0.025,
                          left: screenWidth * 0.025,
                          right: screenWidth * 0.025,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: screenWidth * 0.075,
                              backgroundColor: Colors.grey[300],
                              child: imageUrl != null && imageUrl.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        width: screenWidth * 0.15,
                                        height: screenWidth * 0.15,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    (loadingProgress
                                                            .expectedTotalBytes ??
                                                        1)
                                                : null,
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(
                                            Icons.person,
                                            size: screenWidth * 0.075,
                                            color: Colors.grey[600],
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: screenWidth * 0.075,
                                      color: Colors.grey[600],
                                    ),
                            ),
                            SizedBox(width: screenWidth * 0.025),
                            Expanded(
                              child: Text(
                                artisanName,
                                style: GoogleFonts.nunitoSans(
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isActive ? Icons.lock_open : Icons.lock,
                                color:
                                    isActive ? Colors.grey : Colors.yellow[700],
                                size: screenWidth * 0.075,
                              ),
                              onPressed: () => _toggleArtisan(
                                  artisanName: artisanName, isActive: isActive),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              Padding(
                padding: EdgeInsets.only(left: 0.0, right: screenWidth * 0.04),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: screenWidth * 0.375,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0C8A7B),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.01,
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
              SizedBox(height: screenHeight * 0.02),
              FutureBuilder<Map<String, dynamic>>(
                future: _artisanProfileFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError ||
                      snapshot.data?.containsKey("error") == true) {
                    return Center(
                      child: Text(
                        "Please check your internet connection.",
                        style: GoogleFonts.nunitoSans(
                          fontSize: screenWidth * 0.04,
                          color: Colors.red,
                        ),
                      ),
                    );
                  } else {
                    final products =
                        snapshot.data?["products"] as List<dynamic>? ?? [];
                    if (products.isEmpty) {
                      return Center(
                        child: Text(
                          "No products available",
                          style: GoogleFonts.nunitoSans(
                            fontSize: screenWidth * 0.04,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: screenWidth * 0.04,
                          mainAxisSpacing: screenWidth * 0.04,
                          childAspectRatio: 0.63,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product =
                              products[index] as Map<String, dynamic>;
                          final images =
                              product['ProductImages'] as List<dynamic>? ?? [];
                          final productId = product['ProductID'] as int;

                          return FutureBuilder<Map<String, dynamic>>(
                            future: _apiService.getProductDetails(productId),
                            builder: (context, productSnapshot) {
                              String status = 'Unknown';

                              if (productSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              } else if (productSnapshot.hasError ||
                                  productSnapshot.data?.containsKey("error") ==
                                      true) {
                                status = 'Error';
                              } else {
                                status = productSnapshot.data?['status']
                                        ?.toString() ??
                                    'Unknown';
                              }

                              return Card(
                                elevation: 2,
                                color: Theme.of(context).cardTheme.color,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: screenHeight * 0.1625,
                                      width: double.infinity,
                                      child: images.isNotEmpty
                                          ? Image.network(
                                              images[0],
                                              fit: BoxFit.contain,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return const Center(
                                                    child:
                                                        CircularProgressIndicator());
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.broken_image,
                                                  size: screenWidth * 0.1,
                                                  color: Colors.grey,
                                                );
                                              },
                                            )
                                          : Icon(
                                              Icons.broken_image,
                                              size: screenWidth * 0.125,
                                              color: Colors.grey,
                                            ),
                                    ),
                                    Padding(
                                      padding:
                                          EdgeInsets.all(screenWidth * 0.02),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['ProductName']
                                                    ?.toString() ??
                                                'Unknown Product',
                                            style: GoogleFonts.nunitoSans(
                                              fontSize: screenWidth * 0.04,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          Text(
                                            '${product['Price']?.toString() ?? 'N/A'} LE',
                                            style: GoogleFonts.nunitoSans(
                                              fontSize: screenWidth * 0.035,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          Text(
                                            status,
                                            style: GoogleFonts.nunitoSans(
                                              fontSize: screenWidth * 0.035,
                                              color: status == 'Available'
                                                  ? const Color(0xFF0C8A7B)
                                                  : Colors.red,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          const SizedBox(height: 0),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ProductDetailsforArtisanPage(
                                                            productId: product[
                                                                'ProductID'],
                                                            ssn: widget.ssn),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF0C8A7B),
                                                padding: EdgeInsets.symmetric(
                                                    vertical:
                                                        screenHeight * 0.01),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          screenWidth * 0.02),
                                                ),
                                              ),
                                              child: Text(
                                                'DETAILS',
                                                style: GoogleFonts.nunitoSans(
                                                  fontSize: screenWidth * 0.035,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: screenHeight * 0.02),
              Padding(
                padding: EdgeInsets.only(left: 0.0, right: screenWidth * 0.04),
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
                      vertical: screenHeight * 0.01,
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
              FutureBuilder<Map<String, dynamic>>(
                future: _ratingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError ||
                      snapshot.data?.containsKey("error") == true) {
                    return Center(
                      child: Text(
                        "Please check your internet connection.",
                        style: GoogleFonts.nunitoSans(
                          fontSize: screenWidth * 0.04,
                          color: Colors.red,
                        ),
                      ),
                    );
                  } else {
                    final ratings =
                        snapshot.data?["ratings"] as List<dynamic>? ?? [];
                    if (ratings.isEmpty) {
                      return Center(
                        child: Text(
                          "No reviews available",
                          style: GoogleFonts.nunitoSans(
                            fontSize: screenWidth * 0.04,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                      child: Column(
                        children: ratings.map((rating) {
                          return Padding(
                            padding:
                                EdgeInsets.only(bottom: screenHeight * 0.02),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: screenWidth * 0.05,
                                  backgroundColor: Colors.grey[300],
                                  child: rating["ClientImage"] != null
                                      ? ClipOval(
                                          child: Image.network(
                                            rating["ClientImage"],
                                            fit: BoxFit.cover,
                                            width: screenWidth * 0.1,
                                            height: screenWidth * 0.1,
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return CircularProgressIndicator(
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        (loadingProgress
                                                                .expectedTotalBytes ??
                                                            1)
                                                    : null,
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Icon(
                                                Icons.person,
                                                color: Colors.white,
                                              );
                                            },
                                          ),
                                        )
                                      : Icon(
                                          Icons.person,
                                          color: Colors.white,
                                        ),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            rating["ClientName"] ?? "Unknown",
                                            style: GoogleFonts.nunitoSans(
                                              fontSize: screenWidth * 0.04,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color,
                                            ),
                                          ),
                                          Text(
                                            formatRelativeTime(
                                                rating["CreatedAt"] ?? ""),
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.035,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (index) => Icon(
                                            Icons.star,
                                            color: index <
                                                    (rating["Artisan_Rate"]
                                                            as num)
                                                        .toInt()
                                                ? const Color(0xFF0C8A7B)
                                                : Colors.grey[300],
                                            size: screenWidth * 0.04,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.005),
                                      Text(
                                        rating["Comment"] ?? "",
                                        style: GoogleFonts.nunitoSans(
                                          fontSize: screenWidth * 0.035,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color,
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
                    );
                  }
                },
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}