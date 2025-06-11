import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageLoader extends StatefulWidget {
  final List<dynamic> images;
  final String productName;

  const ImageLoader({required this.images, required this.productName});

  @override
  __ImageLoaderState createState() => __ImageLoaderState();
}

class __ImageLoaderState extends State<ImageLoader> {
 
  String _cacheKeySuffix = DateTime.now().millisecondsSinceEpoch.toString();

  void _refreshImages() {
    setState(() {
      _cacheKeySuffix = DateTime.now().millisecondsSinceEpoch.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (widget.images.isEmpty) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: screenWidth * 0.13, 
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400] 
                : Colors.grey[600], 
          ),
          Positioned(
            bottom: screenHeight * 0.02, 
            child: ElevatedButton(
              onPressed: _refreshImages, 
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C8A7B), 
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03, 
                  vertical: screenHeight * 0.01,
                ),
                minimumSize: Size(
                  screenWidth * 0.2, 
                  screenHeight * 0.04, 
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.nunitoSans(
                  fontSize: screenWidth * 0.035, 
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return PageView.builder(
      itemCount: widget.images.length,
      itemBuilder: (context, index) {
        final imageUrl = widget.images[index].toString();
        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          cacheKey: imageUrl + _cacheKeySuffix, 
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70 
                  : const Color(0xFF0C8A7B), 
            ),
          ),
          errorWidget: (context, url, error) {
            print(
                "ImageLoader: Error loading image $url for ${widget.productName}: $error");
            return Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: screenWidth * 0.13, 
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
                Positioned(
                  bottom: screenHeight * 0.02, 
                  child: ElevatedButton(
                    onPressed: _refreshImages, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C8A7B), 
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenHeight * 0.01,
                      ),
                      minimumSize: Size(
                        screenWidth * 0.2,
                        screenHeight * 0.04,
                      ),
                    ),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.nunitoSans(
                        fontSize: screenWidth * 0.035, 
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}