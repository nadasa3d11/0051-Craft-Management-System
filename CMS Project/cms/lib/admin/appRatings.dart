import 'package:flutter/material.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';

class RatingsPage extends StatefulWidget {
  @override
  _RatingsPageState createState() => _RatingsPageState();
}

class _RatingsPageState extends State<RatingsPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late AnimationController _animationController;
  late Future<Map<String, dynamic>> _ratingsFuture;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..forward();
    _ratingsFuture = _apiService.getAppRatings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshRatings() async {
    setState(() {
      _ratingsFuture = _apiService.getAppRatings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF0C8A7B),
          brightness: MediaQuery.of(context).platformBrightness,
        ).copyWith(
          primary: Color(0xFF0C8A7B),
          onPrimary: Colors.white,
          secondary: Colors.amber,
        ),
      ),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'App Ratings',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              elevation: 0,
            ),
            body: RefreshIndicator(
              onRefresh: _refreshRatings,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: FutureBuilder<Map<String, dynamic>>(
                        future: _ratingsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError ||
                              snapshot.data!.containsKey("error")) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Connection Error'),
                                  content: Text(
                                      'Please check your internet connection.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            });
                            return Center(child: SizedBox());
                          }

                          final data = snapshot.data!;
                          final averageRating = data["averageRating"] as double;
                          final totalRatings = data["totalRatings"] as int;
                          final ratings = data["ratings"] as List<dynamic>;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(
                                    MediaQuery.of(context).size.width * 0.06),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF0C8A7B),
                                      const Color.fromARGB(255, 130, 128, 128)
                                    ],
                                    end: Alignment.bottomLeft,
                                  ),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Average Rating',
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.06,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                    ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.02),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          averageRating.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.12,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                          ),
                                        ),
                                        SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.02),
                                        Icon(Icons.star,
                                            color: Colors.amber,
                                            size: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.12),
                                      ],
                                    ),
                                    Text(
                                      'Based on $totalRatings reviews',
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.04,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(
                                    MediaQuery.of(context).size.width * 0.04),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: ratings.length,
                                  itemBuilder: (context, index) {
                                    final rating = ratings[index];
                                    return FadeTransition(
                                      opacity: Tween<double>(begin: 0, end: 1)
                                          .animate(
                                        CurvedAnimation(
                                          parent: _animationController,
                                          curve: Interval(
                                            index * 0.1,
                                            1.0,
                                            curve: Curves.easeInOut,
                                          ),
                                        ),
                                      ),
                                      child: Card(
                                        elevation: 5,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        margin: EdgeInsets.symmetric(
                                            vertical: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.01),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundImage: NetworkImage(rating[
                                                    "ProfileImage"] ??
                                                'https://via.placeholder.com/50'),
                                            radius: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.06,
                                          ),
                                          title: Text(
                                            rating["RatedBy"] ?? 'Anonymous',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: List.generate(5,
                                                    (starIndex) {
                                                  return Icon(
                                                    Icons.star,
                                                    color: starIndex <
                                                            (rating["Rating"] ??
                                                                0)
                                                        ? Colors.amber
                                                        : Colors.grey[300],
                                                    size: MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.05,
                                                  );
                                                }),
                                              ),
                                              if (rating["Comment"]
                                                      ?.isNotEmpty ??
                                                  false)
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                      top:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.01),
                                                  child: Text(
                                                    rating["Comment"] ?? '',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.grey[600]),
                                                  ),
                                                ),
                                              Text(
                                                '${DateTime.now().difference(DateTime.parse(rating["CreatedAt"] ?? DateTime.now().toIso8601String())).inMinutes} minutes ago',
                                                style: TextStyle(
                                                    fontSize:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.03,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
