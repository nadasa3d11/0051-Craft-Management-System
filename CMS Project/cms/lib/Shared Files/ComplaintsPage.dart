import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';

class ComplaintsPage extends StatefulWidget {
  @override
  _ComplaintsPageState createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _complaintsFuture;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..forward();
    _checkAndFetchComplaints();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _checkAndFetchComplaints() async {
    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Connection Error"),
          content: Text("No internet connection. Please check your network and try again."),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
      setState(() {
        _complaintsFuture = Future.value([]);
      });
    } else {
      setState(() {
        _complaintsFuture = _apiService.getMyComplaints();
      });
    }
  }

  Future<void> _refreshComplaints() async {
    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Connection Error"),
          content: Text("No internet connection. Please check your network and try again."),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
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
      _complaintsFuture = _apiService.getMyComplaints();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF0C8A7B),
          brightness: MediaQuery.of(context).platformBrightness,
        ).copyWith(
          primary: Color(0xFF0C8A7B),
          onPrimary: Colors.white,
          secondary: Colors.amber,
          surface: Color(0xFF1E2A32),
        ),
        cardTheme: CardTheme(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        textTheme: TextTheme(
          bodyLarge: GoogleFonts.notoSans(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          titleMedium: GoogleFonts.notoSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 4,
          title: Text(
            'My Complaints',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0C8A7B), Color(0xFF0A6A5B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshComplaints,
          color: Theme.of(context).colorScheme.secondary,
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _complaintsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              }
              if (snapshot.hasError || (snapshot.hasData && snapshot.data!.any((item) => item.containsKey("error")))) {
                return Center(
                  child: ElevatedButton(
                    onPressed: _refreshComplaints,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Retry',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white),
                    ),
                  ),
                );
              }
              final complaints = snapshot.data!;
              if (complaints.isEmpty) {
                return Center(
                  child: Text(
                    'No complaints found.',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.all(screenWidth * 0.04),
                itemCount: complaints.length,
                itemBuilder: (context, index) {
                  final complaint = complaints[index];
                  return FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _fadeController,
                        curve: Interval(0.1 * index, 1, curve: Curves.easeInOut),
                      ),
                    ),
                    child: Card(
                      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              Theme.of(context).colorScheme.surface,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Complaint #${complaint["ComplaintId"]}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Chip(
                                  label: Text(
                                    complaint["Status"],
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontSize: screenWidth * 0.035,
                                    ),
                                  ),
                                  backgroundColor: complaint["Status"] == "Resolved"
                                      ? Colors.green
                                      : complaint["Status"] == "UnderReview"
                                          ? Colors.orange
                                          : Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'Problem: ${complaint["Problem"]}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'Date: ${complaint["ProblemDate"].toString().split('T')[0]}',
                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: screenWidth * 0.04),
                            ),
                            if (complaint["Response"] != "No response yet")
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: screenHeight * 0.01),
                                  Text(
                                    'Response: ${complaint["Response"]}',
                                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    'Response Date: ${complaint["ResponseDate"]?.toString().split('T')[0] ?? "N/A"}',
                                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: screenWidth * 0.04),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}