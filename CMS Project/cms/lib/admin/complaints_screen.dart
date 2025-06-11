import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/admin/models_complaint.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'complaint_details_screen.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Complaint> newComplaints = [];
  List<Complaint> resolvedComplaints = [];
  bool isLoading = true;
  String? errorMessage;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadComplaintsFromApi();
  }

  Future<void> _loadComplaintsFromApi() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      newComplaints = [];
      resolvedComplaints = [];
    });

    try {
      final newComplaintsData = await _apiService.fetchComplaintsByStatus("New");
      final resolvedComplaintsData = await _apiService.fetchComplaintsByStatus("Resolved");

      setState(() {
        if (newComplaintsData.isNotEmpty && newComplaintsData[0].containsKey("error")) {
          errorMessage = "Please check your internet connection.";
        } else {
          newComplaints = newComplaintsData.map((json) => Complaint.fromJson(json)).toList();
        }

        if (resolvedComplaintsData.isNotEmpty && resolvedComplaintsData[0].containsKey("error")) {
          errorMessage = "Please check your internet connection.";
        } else {
          resolvedComplaints = resolvedComplaintsData.map((json) => Complaint.fromJson(json)).toList();
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        if (e.toString().contains("401")) {
          errorMessage = "Unauthorized: The admin token may have expired. Please provide a new token.";
        } else {
          errorMessage = "Please check your internet connection.";
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 1,
        centerTitle: true,
        title: Text(
          "Complaints and Support",
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.bold,
            textStyle: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
              fontSize: screenWidth * 0.06,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        bottom: TabBar(
          dividerColor: Theme.of(context).scaffoldBackgroundColor,
          physics: const ClampingScrollPhysics(),
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Theme.of(context).textTheme.bodyLarge?.color,
          indicator: BoxDecoration(
            color: const Color(0xFF0C8A7B),
            borderRadius: BorderRadius.circular(screenWidth * 0.0625),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: TextStyle(fontSize: screenWidth * 0.0375),
          tabs: const [
            Tab(text: "New"),
            Tab(text: "Resolved"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.025),
                      ElevatedButton(
                        onPressed: _loadComplaintsFromApi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C8A7B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.05),
                          ),
                        ),
                        child: Text(
                          "Retry",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    
                    newComplaints.isEmpty
                        ? Center(
                            child: Text(
                              'No new complaints',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadComplaintsFromApi,
                            child: ListView.builder(
                              padding: EdgeInsets.all(screenWidth * 0.025),
                              itemCount: newComplaints.length,
                              itemBuilder: (context, index) {
                                final complaint = newComplaints[index];
                                return Card(
                                  color: Theme.of(context).brightness == Brightness.light ? Colors.white : Theme.of(context).cardTheme.color,
                                  margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.04,
                                      vertical: screenHeight * 0.01,
                                    ),
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Complaint from ${complaint.userName}",
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.04,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.005),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ComplaintDetailsScreen(
                                                        complaintId: complaint.id),
                                              ),
                                            );
                                            if (result == true) {
                                              _loadComplaintsFromApi();
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey[300],
                                            minimumSize: Size(screenWidth * 0.15, screenHeight * 0.0375),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(screenWidth * 0.05),
                                            ),
                                          ),
                                          child: Text(
                                            "Details",
                                            style: TextStyle(
                                              color: Theme.of(context).textTheme.bodyLarge?.color,
                                              fontSize: screenWidth * 0.035,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: SizedBox(
                                      width: screenWidth * 0.2,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          complaint.date,
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.035,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                    
                    resolvedComplaints.isEmpty
                        ? Center(
                            child: Text(
                              'No resolved complaints',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadComplaintsFromApi,
                            child: ListView.builder(
                              padding: EdgeInsets.all(screenWidth * 0.04),
                              itemCount: resolvedComplaints.length,
                              itemBuilder: (context, index) {
                                final complaint = resolvedComplaints[index];
                                return Card(
                                  color: Theme.of(context).brightness == Brightness.light ? Colors.white : Theme.of(context).cardTheme.color,
                                  margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.04,
                                      vertical: screenHeight * 0.01,
                                    ),
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Complaint from ${complaint.userName}",
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.04,
                                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                              ),
                                            ),
                                            SizedBox(height: screenHeight * 0.005),
                                            ElevatedButton(
                                              onPressed: () async {
                                                final result = await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ComplaintDetailsScreen(
                                                            complaintId: complaint.id),
                                                  ),
                                                );
                                                if (result == true) {
                                                  _loadComplaintsFromApi();
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.grey[300],
                                                minimumSize: Size(screenWidth * 0.15, screenHeight * 0.0375),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                                                ),
                                              ),
                                              child: Text(
                                                "Details",
                                                style: TextStyle(
                                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                                  fontSize: screenWidth * 0.035,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              complaint.date,
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.035,
                                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                              ),
                                            ),
                                            SizedBox(height: screenHeight * 0.005),
                                            Text(
                                              "Done",
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.045,
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ],
                ),
    );
  }
}