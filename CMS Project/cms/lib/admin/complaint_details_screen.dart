import 'package:flutter/material.dart';
import 'package:herfa/admin/models_complaint.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'reply_screen.dart';

class ComplaintDetailsScreen extends StatefulWidget {
  final int complaintId;

  const ComplaintDetailsScreen({super.key, required this.complaintId});

  @override
  State<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  Complaint? complaint;
  bool isLoading = true;
  String? errorMessage;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchComplaintDetails();
  }

  Future<void> _fetchComplaintDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final jsonData = await _apiService.fetchAllComplaints();

      if (jsonData.isNotEmpty && jsonData[0].containsKey("error")) {
        throw Exception(jsonData[0]["error"]);
      }

      final selectedComplaint = jsonData.firstWhere(
        (complaintJson) => complaintJson['ComplaintId'] == widget.complaintId,
        // ignore: null_check_always_fails
        orElse: () => null!,
      );

      // ignore: unnecessary_null_comparison
      if (selectedComplaint == null) {
        throw Exception("Complaint with ID ${widget.complaintId} not found.");
      }

      setState(() {
        complaint = Complaint.fromJson(selectedComplaint);
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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        centerTitle: true,
        title: Text(
          "Complaints and Support",
          style: TextStyle(
            fontSize: screenWidth * 0.0625,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
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
                        onPressed: _fetchComplaintDetails,
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
              : RefreshIndicator(
                  onRefresh: _fetchComplaintDetails,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Problem Details",
                            style: TextStyle(
                              fontSize: screenWidth * 0.075,
                              color: const Color(0xFF0C8A7B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(top: screenHeight * 0.025),
                            padding: EdgeInsets.all(screenWidth * 0.075),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C8A7B),
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(screenWidth * 0.02),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: screenWidth * 0.75,
                                  padding: EdgeInsets.all(screenWidth * 0.025),
                                  color: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.grey[800],
                                  child: Text(
                                    "Problem From: ${complaint!.userName}",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                Container(
                                  width: screenWidth * 0.75,
                                  padding: EdgeInsets.all(screenWidth * 0.025),
                                  color: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.grey[800],
                                  child: Text(
                                    "Phone Number: ${complaint!.phoneNumber}",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Text(
                                  "the problem is:",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.0575,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                Container(
                                  width: double.infinity,
                                  height: screenHeight * 0.3375,
                                  padding: EdgeInsets.all(screenWidth * 0.02),
                                  color: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.grey[800],
                                  child: Text(
                                    complaint!.details,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                                if (complaint!.response != null) ...[
                                  SizedBox(height: screenHeight * 0.02),
                                  Text(
                                    "Solution:",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.0575,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(screenWidth * 0.02),
                                    color: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.grey[800],
                                    child: Text(
                                      complaint!.response!,
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ),
                                ],
                                if (complaint!.respondedAt != null) ...[
                                  SizedBox(height: screenHeight * 0.02),
                                  Text(
                                    "Responded At:",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.0575,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(screenWidth * 0.02),
                                    color: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.grey[800],
                                    child: Text(
                                      complaint!.respondedAt!,
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (complaint!.response == null)
                                ElevatedButton(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ReplyScreen(complaint: complaint!),
                                      ),
                                    );
                                    if (result == true) {
                                      await _fetchComplaintDetails();
                                      Navigator.pop(context, true);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0C8A7B),
                                    minimumSize: Size(screenWidth * 0.5, screenHeight * 0.0625),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(screenWidth * 0.0625),
                                    ),
                                  ),
                                  child: Text(
                                    "Accept & Reply",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.05,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}