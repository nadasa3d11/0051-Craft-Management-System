import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/admin/artisanProfile.dart';
import 'package:herfa/admin/editArtisan.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:intl/intl.dart';

class ArtisansManagementScreen extends StatefulWidget {
  @override
  _ArtisansManagementScreenState createState() => _ArtisansManagementScreenState();
}

class _ArtisansManagementScreenState extends State<ArtisansManagementScreen> {
  List<Map<String, dynamic>> artisans = [];
  List<Map<String, dynamic>> filteredArtisans = [];
  bool isLoading = false;
  String searchQuery = '';
  bool sortByNewest = true;

  @override
  void initState() {
    super.initState();
    fetchArtisans();
  }

  Future<void> fetchArtisans() async {
    setState(() {
      isLoading = true;
    });
    final result = await ApiService().getAllArtisans();
    setState(() {
      isLoading = false;
      if (result.isNotEmpty && result[0].containsKey("error")) {
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
        artisans = result;
        filteredArtisans = List.from(artisans);
        sortArtisans();
      }
    });
  }

  Future<void> searchArtisans() async {
    setState(() {
      isLoading = true;
    });

    if (searchQuery.isEmpty) {
      setState(() {
        filteredArtisans = List.from(artisans);
        sortArtisans();
      });
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      filteredArtisans = artisans.where((artisan) {
        String phone = (artisan["Phone"]?.toString() ?? "").replaceAll(RegExp(r'\s+'), '');
        String ssn = (artisan["SSN"]?.toString() ?? "").replaceAll(RegExp(r'\s+'), '');

        String searchQueryCleaned = searchQuery.replaceAll(RegExp(r'\s+'), '');

        bool matchesPhone = phone.contains(searchQueryCleaned);
        bool matchesSSN = ssn.contains(searchQueryCleaned);

        return matchesPhone || matchesSSN;
      }).toList();

      sortArtisans();
      isLoading = false;
    });
  }

  void sortArtisans() {
    setState(() {
      filteredArtisans.sort((a, b) {
        int idA = int.tryParse(a["SSN"].toString().substring(0, 3)) ?? 0;
        int idB = int.tryParse(b["SSN"].toString().substring(0, 3)) ?? 0;
        return sortByNewest ? idB.compareTo(idA) : idA.compareTo(idB);
      });
    });
  }

  int calculateAge(String birthDate) {
    DateTime birth = DateTime.parse(birthDate);
    DateTime now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  String formatDate(String birthDate) {
    return DateFormat('dd/MM/yyyy').format(DateTime.parse(birthDate));
  }

  Future<void> deleteArtisan(String ssn) async {
    final result = await ApiService().deleteArtisan(ssn: ssn);
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
          content: Text(result["message"]),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                fetchArtisans();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void showSSNImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('No SSN image available'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("SSN Image"),
        content: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return Text("Failed to load image");
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Artisans Management',
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.bold,
            textStyle: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
              fontSize: screenWidth * 0.06,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search by Phone or SSN",
                      hintStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.075),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                      searchArtisans();
                    },
                  ),
                ),
                SizedBox(width: screenWidth * 0.025),
                DropdownButton<String>(
                  value: sortByNewest ? "Newest" : "Oldest",
                  items: ["Newest", "Oldest"].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      sortByNewest = value == "Newest";
                      sortArtisans();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredArtisans.isEmpty
                    ? Center(
                        child: Text(
                          "No artisans found",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchArtisans,
                        child: ListView.builder(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          itemCount: filteredArtisans.length,
                          itemBuilder: (context, index) {
                            final artisan = filteredArtisans[index];
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ArtisanProfile(ssn: artisan["SSN"]),
                                  ),
                                );
                              },
                              child: Card(
                                color: Theme.of(context).brightness == Brightness.light ? Colors.white : Theme.of(context).cardTheme.color,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.0375),
                                  side: BorderSide(
                                    color: Colors.teal,
                                    width: 1,
                                  ),
                                ),
                                margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                                child: Padding(
                                  padding: EdgeInsets.all(screenWidth * 0.03),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              artisan["Full_Name"] ?? "Unknown",
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.045,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit,
                                                  color: Colors.blue,
                                                  size: screenWidth * 0.06,
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          EditArtisanScreen(artisan: artisan),
                                                    ),
                                                  ).then((value) {
                                                    if (value == true) {
                                                      fetchArtisans();
                                                    }
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                  size: screenWidth * 0.06,
                                                ),
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: Text(
                                                        "Confirm Delete",
                                                        style: TextStyle(
                                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                                        ),
                                                      ),
                                                      content: Text(
                                                        "Are you sure you want to delete ${artisan["Full_Name"]}",
                                                        style: TextStyle(
                                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(context);
                                                          },
                                                          child: Text(
                                                            "Cancel",
                                                            style: TextStyle(
                                                              color: Theme.of(context).textTheme.bodyLarge?.color,
                                                            ),
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(context);
                                                            deleteArtisan(artisan["SSN"]);
                                                          },
                                                          child: Text(
                                                            "Delete",
                                                            style: TextStyle(
                                                              color: Theme.of(context).textTheme.bodyLarge?.color,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: screenHeight * 0.01),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${artisan["Gender"] ?? "Unknown"}",
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.03,
                                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                                  ),
                                                ),
                                                SizedBox(height: screenHeight * 0.01),
                                                Text(
                                                  "${artisan["Phone"] ?? "N/A"}",
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.03,
                                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                                  ),
                                                ),
                                                SizedBox(height: screenHeight * 0.01),
                                                Text(
                                                  artisan["Active"] == true ? "Active" : "Inactive",
                                                  style: TextStyle(
                                                    color: artisan["Active"] == true
                                                        ? Colors.green
                                                        : Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${artisan["SSN"] ?? "N/A"}",
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.03,
                                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                                  ),
                                                ),
                                                SizedBox(height: screenHeight * 0.01),
                                                Text(
                                                  "${artisan["Address"] ?? "N/A"}",
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.03,
                                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                                  ),
                                                ),
                                                SizedBox(height: screenHeight * 0.01),
                                                Text(
                                                  "${calculateAge(artisan["Birth_Date"])} years old",
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.03,
                                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    showSSNImage(artisan["SSNImage"]);
                                                  },
                                                  child: Container(
                                                    width: screenWidth * 0.2,
                                                    height: screenHeight * 0.05,
                                                    child: Image.network(
                                                      artisan["SSNImage"] ?? "",
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (context, child, loadingProgress) {
                                                        if (loadingProgress == null) return child;
                                                        return Center(child: CircularProgressIndicator());
                                                      },
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          color: Colors.grey[300],
                                                          child: Center(
                                                            child: Text(
                                                              "No Image",
                                                              style: TextStyle(
                                                                color: Colors.grey,
                                                                fontSize: screenWidth * 0.03,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}