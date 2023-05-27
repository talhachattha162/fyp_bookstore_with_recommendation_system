import 'dart:async';
import 'dart:io';

import 'package:bookstore_recommendation_system_fyp/user_screens/view_book_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/global_variables.dart';
import 'package:bookstore_recommendation_system_fyp/utils/navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../providers/internetavailabilitynotifier.dart';
import '../providers/reviewnotifier.dart';
import '../utils/InternetChecker.dart';

class ViewAllReviewsScreen extends StatefulWidget {
  Book book;
  ViewAllReviewsScreen({super.key, required this.book});

  @override
  State<ViewAllReviewsScreen> createState() => _ViewAllReviewsScreenState();
}

class _ViewAllReviewsScreenState extends State<ViewAllReviewsScreen> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) async {
      final internetAvailabilityNotifier =
          Provider.of<InternetNotifier>(context, listen: false);
      try {
        final result = await InternetAddress.lookup('google.com');
        if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) ) {
          internetAvailabilityNotifier.setInternetAvailability(true);
        } else {}
      } on SocketException catch (_) {
        internetAvailabilityNotifier.setInternetAvailability(false);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }


  DateTime currentBackPressTime = DateTime.now();

  Future<bool> onWillPop() async {
    final now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Press back again to exit')));
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context);
    double height = MediaQuery.of(context).size.height;
    return WillPopScope(
      onWillPop:  () async {
        navigateWithNoBack(context, ViewBookScreen(book: widget.book));
        return false;
      },
      child: SafeArea(
        child: internetAvailabilityNotifier.getInternetAvailability() == false
            ? InternetChecker()
            : MultiProvider(
                providers: [
                  ChangeNotifierProvider(
                    create: (_) =>
                        ReviewProvider()..getReviews(widget.book.bookid),
                  )
                ],
                child: Scaffold(
                  appBar: AppBar(
                      title: const Text('Reviews'),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          navigateWithNoBack(
                              context,
                              ViewBookScreen(
                                book: widget.book,
                              ));
                        },
                      )),
                  body: Consumer<ReviewProvider>(
                    builder: (context, provider, child) {
                      return SizedBox(
                        height: height * 0.9,
                        child: provider.reviews.isEmpty
                            ? const Center(child: Text('No Reviews found'))
                            : ListView.builder(
                                itemCount: provider.reviews.length,
                                itemBuilder: (context, index) {
                                  if (index == provider.reviews.length) {
                                    return Container();
                                  }
    
                                  if (provider.users.length > index) {
                                    var review = provider.reviews[index];
                                    var user = provider.users[index];
                                    return Padding(
                                      padding: const EdgeInsets.all(15.0),
                                      child: Card(
                                        shadowColor: primarycolor[300],
                                        elevation: 6,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceAround,
                                                children: [
                                                  SizedBox(
                                                    height: 30,
                                                    width: 30,
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      child: Image.network(
                                                        user.photo,
                                                        errorBuilder: (context,
                                                            error, stackTrace) {
                                                          return Icon(Icons.error,
                                                              size: 20);
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    user.name.length > 15
                                                        ? user.name.substring(
                                                                0, 15) +
                                                            '...'
                                                        : user.name,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.star,
                                                        color: Colors.amber,
                                                      ),
                                                      Text((review.rating + 1)
                                                              .toString() +
                                                          '/5'),
                                                    ],
                                                  )
                                                ],
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        10.0, 0, 0, 0),
                                                child: Wrap(children: [
                                                  Text(
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                      review.reviewtext)
                                                ]),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return Container();
                                  }
                                },
                              ),
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }
}
