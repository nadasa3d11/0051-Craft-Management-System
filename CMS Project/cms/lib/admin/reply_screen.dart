import 'package:flutter/material.dart';
import 'models_complaint.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';

class ReplyScreen extends StatefulWidget {
  final Complaint complaint;

  const ReplyScreen({super.key, required this.complaint});

  @override
  State<ReplyScreen> createState() => _ReplyScreenState();
}

class _ReplyScreenState extends State<ReplyScreen> {
  final TextEditingController _solutionController = TextEditingController();
  bool isSending = false;
  String? errorMessage;
  final ApiService _apiService = ApiService();
  // ignore: unused_field
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _solutionController.dispose();
    super.dispose();
  }

  Future<void> _sendSolution() async {
    if (_solutionController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Input Required'),
          content: const Text('Please write a solution before sending.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      isSending = true;
      errorMessage = null;
    });

    try {
      final result = await _apiService.sendSolution(widget.complaint.id, _solutionController.text);

      if (result.containsKey("error")) {
        throw Exception(result["error"]);
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Solution sent successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        isSending = false;
        if (e.toString().contains("401")) {
          errorMessage = "Unauthorized: Please check your admin token.";
        } else {
          errorMessage = "Please check your internet connection.";
        }
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: e.toString().contains("401") ? const Text('Unauthorized') : const Text('Error'),
          content: Text(errorMessage!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
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
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: RefreshIndicator(
          onRefresh: () async {
            _solutionController.clear();
            setState(() {
              errorMessage = null;
              isSending = false;
            });
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  color: const Color(0xFF0C8A7B),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${widget.complaint.userName} \nthe problem is:",
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Container(
                        height: screenHeight * 0.125,
                        width: double.infinity,
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.grey[800],
                          borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        ),
                        child: Text(
                          widget.complaint.details,
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.0625),
                Text(
                  "The Solution:",
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                TextField(
                  controller: _solutionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Write the solution here...",
                    hintStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: isSending ? null : _sendSolution,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C8A7B),
                        minimumSize: Size(screenWidth * 0.375, screenHeight * 0.0625),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.0625),
                        ),
                      ),
                      child: isSending
                          ? SizedBox(
                              height: screenHeight * 0.025,
                              width: screenHeight * 0.025,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Send",
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