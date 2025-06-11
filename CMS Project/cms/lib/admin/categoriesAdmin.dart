import 'package:flutter/material.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({Key? key}) : super(key: key);

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _categories = [];
  List<TextEditingController> _controllers = [];
  bool _isLoading = true;
  String? _errorMessage;
  TextEditingController _newCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _apiService.getCategories();
    if (response.isNotEmpty && !response[0].containsKey('error')) {
      setState(() {
        _categories = response;
        _controllers = _categories
            .map((category) =>
                TextEditingController(text: category['Cat_Type'] ?? ''))
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = 'Please check your internet connection.';
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connection Error'),
          content: const Text('Please check your internet connection.'),
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

  Future<void> _addCategory(String catType) async {
    if (catType.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Category name cannot be empty'),
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

    final response = await _apiService.addCategory(catType: catType);
    if (response.containsKey('error')) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connection Error'),
          content: const Text('Please check your internet connection.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _newCategoryController.clear();
      });
      _fetchCategories();
    }
  }

  Future<void> _updateCategory(
      String oldCatType, String newCatType, int index) async {
    if (newCatType.isEmpty || oldCatType == newCatType) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(
            newCatType.isEmpty
                ? 'Category name cannot be empty'
                : 'No changes to update',
          ),
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

    final response = await _apiService.updateCategory(
      catType: oldCatType,
      newCatType: newCatType,
    );
    if (response.containsKey('error')) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connection Error'),
          content: const Text('Please check your internet connection.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      _fetchCategories();
    }
  }

  Future<void> _deleteCategory(String catType) async {
    final response = await _apiService.deleteCategory(catType: catType);
    if (response.containsKey('error')) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connection Error'),
          content: const Text('Please check your internet connection.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      _fetchCategories();
    }
  }

  void _confirmDeleteCategory(String catType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete the category "$catType"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(catType);
            },
            child: const Text('Yes'),
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
        title: Text(
          "Add Categories",
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchCategories,
                  child: ListView.builder(
                    itemCount: _categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _categories.length) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newCategoryController,
                                  decoration: InputDecoration(
                                    labelText: 'New Category',
                                    labelStyle: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color
                                          ?.withOpacity(0.5),
                                    ),
                                    border: const OutlineInputBorder(),
                                    enabledBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Color(0xFF0C8A7B)),
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              IconButton(
                                icon: Icon(
                                  Icons.add,
                                  color: Colors.green,
                                  size: screenWidth * 0.06,
                                ),
                                onPressed: () {
                                  _addCategory(_newCategoryController.text.trim());
                                },
                              ),
                            ],
                          ),
                        );
                      }
                      final categoryName = _categories[index]['Cat_Type'] ?? '';

                      return Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Category ${index + 1}',
                                  labelStyle: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color
                                        ?.withOpacity(0.5),
                                  ),
                                  border: const OutlineInputBorder(),
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(0xFF0C8A7B)),
                                  ),
                                ),
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            IconButton(
                              icon: Icon(
                                Icons.check,
                                color: Colors.blue,
                                size: screenWidth * 0.06,
                              ),
                              onPressed: () {
                                _updateCategory(
                                  categoryName,
                                  _controllers[index].text.trim(),
                                  index,
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: screenWidth * 0.06,
                              ),
                              onPressed: () {
                                _confirmDeleteCategory(categoryName);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}