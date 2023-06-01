import 'dart:async';
import 'dart:io';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/user_main_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/view_book_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/global_variables.dart';
import 'package:bookstore_recommendation_system_fyp/utils/navigation.dart';
import 'package:bookstore_recommendation_system_fyp/utils/snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reviews_slider/reviews_slider.dart';

import '../Widgets/text_field.dart';
import '../models/book.dart';
import '../models/notificationitem.dart';
import '../models/review.dart';
import '../providers/internetavailabilitynotifier.dart';
import '../providers/themenotifier.dart';
import '../utils/InternetChecker.dart';
import '../utils/firebase_constants.dart';
import '../utils/fluttertoast.dart';

class WriteReviewScreen extends StatefulWidget {
  Book book;
  WriteReviewScreen({super.key, required this.book});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final TextEditingController _reviewController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  Timer? timer;
  int rating = 0;

  bool isLoading = false;
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

  Future<String> getName(String userId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference documentReference =
        firestore.collection('users').doc(userId);
    final DocumentSnapshot snapshot = await documentReference.get();
    final String name = snapshot.get('name');
    return name;
  }

  reviewNotification(title, reviewedby, userid) async {
    final name = await getName(reviewedby);
    NotificationItem item = NotificationItem(
        title + ' book is reviewed by $name', userid, Timestamp.now());
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference collectionReference =
        firestore.collection('notifications');
    await collectionReference.add(item.toMap());
    print('notification2:' + item.toMap().toString());
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context);
    return WillPopScope(
      onWillPop:  () async {
        navigateWithNoBack(context, ViewBookScreen(book: widget.book));
        return false;
      },
      child: SafeArea(
        child: internetAvailabilityNotifier.getInternetAvailability() == false
            ? const InternetChecker()
            : Scaffold(
                appBar: AppBar(
                    title: const Text('Write a review'),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        navigateWithNoBack(context, ViewBookScreen(book: widget.book));
                      },
                    )),
                body: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        TextInputField(
                          hintText: 'Enter Review',
                          suffixIcon: Text(''),
                          isPassword: false,
                          textInputType: TextInputType.text,
                          textEditingController: _reviewController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter Review';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 60,
                        ),
                        ReviewSlider(
                            onChange: (int value) {
                              //values are from 0 to 4
                              rating = value;
                            },
                            optionStyle: TextStyle(
                              color: themeNotifier.getTheme() ==
                                      ThemeData.dark(useMaterial3: true).copyWith(
                                        colorScheme: ColorScheme.dark().copyWith(
                                          primary: darkprimarycolor,
                                          error: Colors.red,
                                          onPrimary: darkprimarycolor,
                                          outline: darkprimarycolor,
                                          primaryVariant: darkprimarycolor,
                                          onPrimaryContainer: darkprimarycolor,
                                        ),
                                      )
                                  ? darkprimarycolor
                                  : primarycolor,
                            )),
                        const SizedBox(
                          height: 60,
                        ),
                        isLoading
                            ? const CircularProgressIndicator()
                            :  ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    if (mounted) {
                                      setState(() {
                                        isLoading = true;
                                      });
                                    }
                                    //user liked code//
                                    // List userid=[FirebaseAuth.instance.currentUser!.uid];
                                    // List usersReviewed=widget.book.userliked;
                                    // usersReviewed.addAll(userid);
                                    // DocumentReference docRef = firestoreInstance
                                    //     .collection('books')
                                    //     .doc(widget.book.bookid);

                                    // docRef
                                    //     .update({
                                    //       'userliked': '',
                                    //     })
                                    //     .then((value) => print(
                                    //         'Attribute updated successfully!'))
                                    //     .catchError((error) => print(
                                    //         'Failed to update attribute: $error'));
                                    CollectionReference reviewCollection =
                                        firestoreInstance.collection("reviews");
                                    String reviewid = reviewCollection.doc().id;
                                    Review review = Review(
                                        reviewId: reviewid,
                                        bookId: widget.book.bookid,
                                        uploadedByUserId: FirebaseAuth
                                            .instance.currentUser!.uid,
                                        rating: rating,
                                        reviewtext: _reviewController.text,
                                        created_at: Timestamp.now());
                                    try {
                                      await reviewCollection
                                          .doc(reviewid)
                                          .set(review.toMap())
                                          .then((value) async {})
                                          .onError((error, stackTrace) async {
                                        flutterToast('Error:' + error.toString());
                                      }).then((_) {

                                        final snackBar = SnackBar(
                                          /// need to set following properties for best effect of awesome_snackbar_content
                                          elevation: 0,
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: Colors.transparent,

                                          content: AwesomeSnackbarContent(
                                            title: 'Success!',
                                            message:
                                            'Review submitted.',

                                            /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                                            contentType: ContentType.success,
                                          ),
                                        );

                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(snackBar);
                                        // showSnackBar(context,'Review submitted');
                                        if (FirebaseAuth
                                                .instance.currentUser!.uid !=
                                            widget.book.userid) {
                                          reviewNotification(
                                              widget.book.title,
                                              FirebaseAuth
                                                  .instance.currentUser!.uid,
                                              widget.book.userid);
                                        }
                                      });
                                    } catch (e) {
                                      flutterToast('Error:' + e.toString());
                                    }
                                    if (mounted) {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  }
                                },
                                child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 75.0, vertical: 12.0),
                                    child:const Text('Submit')),
                              ),
                      ],
                    ),
                  ),
                )),
      ),
    );
  }
}
