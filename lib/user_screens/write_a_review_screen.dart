import 'dart:async';
import 'dart:io';

import 'package:bookstore_recommendation_system_fyp/user_screens/user_main_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/view_book_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/global_variables.dart';
import 'package:bookstore_recommendation_system_fyp/utils/navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reviews_slider/reviews_slider.dart';

import '../Widgets/text_field.dart';
import '../models/book.dart';
import '../models/review.dart';
import '../providers/internetavailabilitynotifier.dart';
import '../utils/InternetChecker.dart';
import '../utils/firebase_constants.dart';
import '../utils/fluttertoast.dart';
import '../utils/snackbar.dart';

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
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context);
    return SafeArea(
      child: internetAvailabilityNotifier.getInternetAvailability() == false
          ? InternetChecker()
          : Scaffold(
              appBar: AppBar(
                  title: const Text('Write a review'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      navigateWithNoBack(context, MainScreenUser());
                    },
                  )),
              body: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    TextInputField(
                      hintText: 'Enter Review',
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
                        optionStyle: const TextStyle(color: primarycolor)),
                    const SizedBox(
                      height: 60,
                    ),
                    isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  isLoading = true;
                                });
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
                                    uploadedByUserId:
                                        FirebaseAuth.instance.currentUser!.uid,
                                    rating: rating,
                                    reviewtext: _reviewController.text);
                                await reviewCollection
                                    .doc(reviewid)
                                    .set(review.toMap())
                                    .then((value) async {})
                                    .onError((error, stackTrace) async {
                                  showSnackBar(
                                      context, 'Error:' + error.toString());
                                }).then((_) {
                                  flutterToast('Review Added');
                                });
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            },
                            child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 75.0, vertical: 12.0),
                                child: Text('Submit')),
                          ),
                  ],
                ),
              )),
    );
  }
}
