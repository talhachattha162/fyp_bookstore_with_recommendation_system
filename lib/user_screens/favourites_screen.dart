import 'dart:async';
import 'dart:io';

import 'package:bookstore_recommendation_system_fyp/providers/internetavailabilitynotifier.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../utils/InternetChecker.dart';
import '../utils/navigation.dart';
import 'user_main_screen.dart';
import 'view_book_screen.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  Timer? timer;

  getBooks() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    Query favouritesQuery = firestore.collection('favourites');
    QuerySnapshot favouritesQuerySnapshot = await favouritesQuery.get();
    List<String> bookIds = [];
    for (QueryDocumentSnapshot favourite in favouritesQuerySnapshot.docs) {
      bookIds.add(favourite.get('bookid'));
    }
    // Query booksQuery = firestore
    //     .collectionGroup('books')
    //     .where('bookid', whereIn: bookIds);
    // QuerySnapshot booksQuerySnapshot = await booksQuery.get();

    // List<Map<String, dynamic>> matchingBooks = [];
    // for (QueryDocumentSnapshot book in booksQuerySnapshot.docs) {
    //   matchingBooks.add(book.data());
    // }

    // print('Matching books:');
    // for (Map<String, dynamic> matchingBook in matchingBooks) {
    //   print(matchingBook);
    // }
  }

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) async {
      final internetAvailabilityNotifier =
          Provider.of<InternetNotifier>(context, listen: false);
      try {
        final result = await InternetAddress.lookup('google.com');
        final result2 = await InternetAddress.lookup('facebook.com');
        final result3 = await InternetAddress.lookup('microsoft.com');
        if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) ||
            (result2.isNotEmpty && result2[0].rawAddress.isNotEmpty) ||
            (result3.isNotEmpty && result3[0].rawAddress.isNotEmpty)) {
          internetAvailabilityNotifier.setInternetAvailability(true);
        } else {}
      } on SocketException catch (_) {
        internetAvailabilityNotifier.setInternetAvailability(false);
      }
    });
    // getBooks();
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

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context);
    double height = MediaQuery.of(context).size.height;
    return WillPopScope(
      onWillPop: onWillPop,
      child: SafeArea(
        child: internetAvailabilityNotifier.getInternetAvailability() == false
            ? InternetChecker()
            : Scaffold(
                appBar: AppBar(
                    title: const Text('Favourites'),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        navigateWithNoBack(context, const MainScreenUser());
                      },
                    )),
                body: SizedBox(
                  width: double.infinity,
                  height: height * 0.73,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: firestore
                        .collection('favourities')
                        .where('userid',
                            isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                        .snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Visibility(
                          visible: true,
                          child: Center(child: Text('No favourites found')),
                        );
                      }
                      if (snapshot.hasData) {
                        List<String> bookIds = [];
                        for (QueryDocumentSnapshot favourite
                            in snapshot.data!.docs) {
                          bookIds.add(favourite.get('bookid'));
                        }
                        return GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 6,
                                  mainAxisSpacing: 6,
                                  mainAxisExtent: 230),
                          padding: const EdgeInsets.all(8.0),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (BuildContext context, int index) {
                            QueryDocumentSnapshot favourite =
                                snapshot.data!.docs[index];
                            return StreamBuilder<DocumentSnapshot>(
                              stream: firestore
                                  .collection('books')
                                  .doc(favourite.get('bookid'))
                                  .snapshots(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                }
                                if (!snapshot.hasData) {
                                  return Text('No favourites found');
                                }
                                Map<String, dynamic>? bookData = snapshot.data!
                                    .data() as Map<String, dynamic>?;
                                if (bookData != null) {
                                  return InkWell(
                                    onTap: () {
                                      navigateWithNoBack(
                                          context,
                                          ViewBookScreen(
                                            book: Book.fromMap(bookData),
                                          ));
                                    },
                                    child: Card(
                                      elevation: 10,
                                      borderOnForeground: true,
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Column(
                                          children: [
                                            CachedNetworkImage(
                                              height: 170,
                                              width: double.infinity,
                                              fit: BoxFit.fill,
                                              imageUrl:
                                                  bookData['coverPhotoFile'],
                                              placeholder: (context, url) => Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      new Icon(Icons.error),
                                            ),
                                            SizedBox(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(4.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        bookData['title']
                                                                    .length >
                                                                20
                                                            ? bookData['title']
                                                                    .substring(
                                                                        0, 20) +
                                                                '...'
                                                            : bookData['title'],
                                                        style: TextStyle(
                                                            fontSize: 12),
                                                      ),
                                                    ),
                                                    Text(
                                                      "\$" +
                                                          bookData['price']
                                                              .toString(),
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  return Text('No favourites found');
                                }
                              },
                            );
                          },
                        );
                      }

                      return Text('No favourites found');
                    },
                  ),
                )),
      ),
    );
  }
}
