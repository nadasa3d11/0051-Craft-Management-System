import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/admin/editClient.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:intl/intl.dart';

class ClientsManagementScreen extends StatefulWidget {
  @override
  _ClientsManagementScreenState createState() =>
      _ClientsManagementScreenState();
}

class _ClientsManagementScreenState extends State<ClientsManagementScreen> {
  List<Map<String, dynamic>> clients = [];
  List<Map<String, dynamic>> filteredClients = [];
  bool isLoading = false;
  String searchQuery = '';
  bool sortByNewest = true;

  @override
  void initState() {
    super.initState();
    fetchClients();
  }

  Future<void> fetchClients() async {
    setState(() {
      isLoading = true;
    });
    final result = await ApiService().getAllClients();
    setState(() {
      isLoading = false;
      if (result.isNotEmpty && result[0].containsKey("error")) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(result[0]["error"].toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        clients = result;
        filteredClients = List.from(clients);
        sortClients();
      }
    });
  }

  Future<void> searchClients() async {
    setState(() {
      isLoading = true;
    });

    if (searchQuery.isEmpty) {
      setState(() {
        filteredClients = List.from(clients);
        sortClients();
        isLoading = false;
      });
      return;
    }

    setState(() {
      filteredClients = clients.where((client) {
        String phone =
            (client["Phone"]?.toString() ?? "").replaceAll(RegExp(r'\s+'), '');
        String ssn =
            (client["SSN"]?.toString() ?? "").replaceAll(RegExp(r'\s+'), '');
        String searchQueryCleaned = searchQuery.replaceAll(RegExp(r'\s+'), '');
        bool matchesPhone = phone.contains(searchQueryCleaned);
        bool matchesSSN = ssn.contains(searchQueryCleaned);
        return matchesPhone || matchesSSN;
      }).toList();
      sortClients();
      isLoading = false;
    });
  }

  void sortClients() {
    setState(() {
      filteredClients.sort((a, b) {
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
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  String formatDate(String birthDate) {
    return DateFormat('dd/MM/yyyy').format(DateTime.parse(birthDate));
  }

  Future<void> deleteClient(String ssn) async {
    setState(() {
      isLoading = true;
    });
    final result = await ApiService().deleteClient(ssn: ssn);
    setState(() {
      isLoading = false;
    });
    if (result.containsKey("error")) {
      String errorMessage = result["error"].toString();
      if (errorMessage.contains("404")) {
        errorMessage = "Client not found.";
      } else if (errorMessage.contains("500")) {
        errorMessage = "Server error, please try again later.";
      } else if (errorMessage.contains("SocketException")) {
        errorMessage = "No internet connection, please try again.";
      } else if (errorMessage.contains("User not logged in")) {
        errorMessage = "Session expired, please log in again.";
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            if (errorMessage.contains("SocketException"))
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  deleteClient(ssn);
                },
                child: const Text('Retry'),
              ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: Text(result["message"] ?? "Client deleted successfully"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                fetchClients();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> toggleClientStatus(String ssn) async {
    setState(() {
      isLoading = true;
    });
    final result = await ApiService().toggleClient(ssn);
    setState(() {
      isLoading = false;
    });
    if (result.containsKey("error")) {
      String errorMessage = result["error"].toString();
      if (errorMessage.contains("404")) {
        errorMessage = "Client not found.";
      } else if (errorMessage.contains("500")) {
        errorMessage = "Server error, please try again later.";
      } else if (errorMessage.contains("SocketException")) {
        errorMessage = "No internet connection, please try again.";
      } else if (errorMessage.contains("User not logged in")) {
        errorMessage = "Session expired, please log in again.";
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            if (errorMessage.contains("SocketException"))
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  toggleClientStatus(ssn);
                },
                child: const Text('Retry'),
              ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content:
              Text(result["message"] ?? "Client status toggled successfully"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                fetchClients();
              },
              child: const Text('OK'),
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
          title: const Text('Error'),
          content: const Text('No SSN image available'),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'SSN Image',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return Text(
              'Failed to load image',
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
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
          'Clients Management',
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.bold,
            textStyle: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
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
                      hintText: 'Search by Phone or SSN',
                      hintStyle: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(screenWidth * 0.075),
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
                      searchClients();
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
                      sortClients();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredClients.isEmpty
                    ? Center(
                        child: Text(
                          "No clients found",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchClients,
                        child: ListView.builder(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          itemCount: filteredClients.length,
                          itemBuilder: (context, index) {
                            final client = filteredClients[index];
                            return Card(
                              color: Theme.of(context).brightness == Brightness.light ? Colors.white : Theme.of(context).cardTheme.color,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(screenWidth * 0.0375),
                                side: BorderSide(color: Colors.teal, width: 1),
                              ),
                              margin: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.01),
                              child: Padding(
                                padding: EdgeInsets.all(screenWidth * 0.03),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            client["Full_Name"]?.toString() ??
                                                "Unknown",
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.045,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color,
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
                                                        EditClientScreen(
                                                            client: client),
                                                  ),
                                                ).then((value) {
                                                  if (value == true) {
                                                    fetchClients();
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
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: Text(
                                                      "Confirm Delete",
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge
                                                            ?.color,
                                                      ),
                                                    ),
                                                    content: Text(
                                                      "Are you sure you want to delete ${client["Full_Name"]?.toString() ?? "this client"}?",
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
                                                            Navigator.pop(
                                                                context),
                                                        child: Text(
                                                          "Cancel",
                                                          style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyLarge
                                                                ?.color,
                                                          ),
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                          deleteClient(client[
                                                                      "SSN"]
                                                                  ?.toString() ??
                                                              "");
                                                        },
                                                        child: Text(
                                                          "Delete",
                                                          style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyLarge
                                                                ?.color,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                client["Active"] == true
                                                    ? Icons.lock_open
                                                    : Icons.lock,
                                                color: client["Active"] == true
                                                    ? Colors.grey
                                                    : Colors.yellow[700],
                                                size: screenWidth * 0.075,
                                              ),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: Text(
                                                      "Confirm Toggle",
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge
                                                            ?.color,
                                                      ),
                                                    ),
                                                    content: Text(
                                                      client["Active"] == true
                                                          ? "Are you sure you want to deactivate the account of ${client["Full_Name"]?.toString() ?? "this client"}?"
                                                          : "Are you sure you want to activate the account of ${client["Full_Name"]?.toString() ?? "this client"}?",
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
                                                            Navigator.pop(
                                                                context),
                                                        child: Text(
                                                          "Cancel",
                                                          style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyLarge
                                                                ?.color,
                                                          ),
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                          toggleClientStatus(
                                                              client["SSN"]
                                                                      ?.toString() ??
                                                                  "");
                                                        },
                                                        child: Text(
                                                          "Yes",
                                                          style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyLarge
                                                                ?.color,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${client["Gender"]?.toString() ?? "Unknown"}",
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.03,
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.color,
                                                ),
                                              ),
                                              SizedBox(
                                                  height: screenHeight * 0.01),
                                              Text(
                                                "${client["Phone"]?.toString() ?? "Not provided"}",
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.03,
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.color,
                                                ),
                                              ),
                                              SizedBox(
                                                  height: screenHeight * 0.01),
                                              Text(
                                                client["Active"] == true
                                                    ? "Active"
                                                    : "Inactive",
                                                style: TextStyle(
                                                  color:
                                                      client["Active"] == true
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${client["SSN"]?.toString() ?? "Not provided"}",
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.03,
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.color,
                                                ),
                                              ),
                                              SizedBox(
                                                  height: screenHeight * 0.01),
                                              Text(
                                                "${client["Address"]?.toString() ?? "Not provided"}",
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.03,
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.color,
                                                ),
                                              ),
                                              SizedBox(
                                                  height: screenHeight * 0.01),
                                              Text(
                                                "${calculateAge(client["Birth_Date"]?.toString() ?? DateTime.now().toString())} years old",
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.03,
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.color,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  showSSNImage(
                                                      client["SSNImage"]
                                                          ?.toString());
                                                },
                                                child: Container(
                                                  width: screenWidth * 0.2,
                                                  height: screenHeight * 0.05,
                                                  child: Image.network(
                                                    client["SSNImage"]
                                                            ?.toString() ??
                                                        "",
                                                    fit: BoxFit.contain,
                                                    loadingBuilder: (context,
                                                        child,
                                                        loadingProgress) {
                                                      if (loadingProgress ==
                                                          null) return child;
                                                      return Center(
                                                          child:
                                                              CircularProgressIndicator());
                                                    },
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return Container(
                                                        color: Colors.grey[300],
                                                        child: Center(
                                                          child: Text(
                                                            "No Image",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.grey,
                                                              fontSize:
                                                                  screenWidth *
                                                                      0.03,
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
