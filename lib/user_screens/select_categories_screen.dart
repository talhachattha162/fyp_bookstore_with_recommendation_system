import 'dart:async';
import 'dart:io';

import 'package:bookstore_recommendation_system_fyp/user_screens/user_main_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/global_variables.dart';
import 'package:bookstore_recommendation_system_fyp/utils/navigation.dart';
import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/categories.dart';
import '../providers/internetavailabilitynotifier.dart';
import '../utils/InternetChecker.dart';
import '../utils/firebase_constants.dart';
import '../utils/fluttertoast.dart';

class SelectCategoriesScreen extends StatefulWidget {
  const SelectCategoriesScreen({super.key});

  @override
  State<SelectCategoriesScreen> createState() => _SelectCategoriesScreenState();
}

class _SelectCategoriesScreenState extends State<SelectCategoriesScreen> {
  List<String> tags = [];

  Stream<List<String>> getCategories() {
    return FirebaseFirestore.instance.collection('categories').snapshots().map(
        (QuerySnapshot snapshot) => snapshot.docs
            .map((DocumentSnapshot document) => document.get('name') as String)
            .toList());
  }

  List<String> _categories = [];

  bool isLoading = false;
  int? _value = 1;
  bool loading = false;
  Timer? timer;
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
              // appBar: AppBar(
              //   title: const Text(
              //     'Select Categories',
              //   ),
              // ),

              body: loading == true
                  ? Center(child: CircularProgressIndicator())
                  : Column(children: [
                      const SizedBox(
                        height: 10,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      StreamBuilder<List<String>>(
                          stream: getCategories(),
                          builder: (BuildContext context,
                              AsyncSnapshot<List<String>> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  loading = true;
                                });
                              });
                            }
                            if (!snapshot.hasData) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  loading = false;
                                });
                              });
                              return Text('No categories found');
                            } else if (snapshot.hasError) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  loading = false;
                                });
                              });
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            } else {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  loading = false;
                                });
                              });
                              _categories = snapshot.data!;
                              return _categories.isEmpty
                                  ? Text('No categories found')
                                  : Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Padding(
                                        padding: const EdgeInsets.all(3.0),
                                        child: _categories.isEmpty
                                            ? null
                                            : ChipsChoice<String>.multiple(
                                                choiceCheckmark: true,
                                                wrapped: true,
                                                value: tags,
                                                onChanged: (val) =>
                                                    setState(() => tags = val),
                                                choiceItems: C2Choice.listFrom<
                                                    String, String>(
                                                  source: _categories,
                                                  value: (i, v) => v,
                                                  label: (i, v) => v,
                                                ),
                                              ),
                                      ));
                            }
                            return Container();
                          }),
                      const SizedBox(height: 30),
                      isLoading == true
                          ? CircularProgressIndicator()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                isLoading == true
                                    ? CircularProgressIndicator()
                                    : ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            isLoading = true;
                                          });
                                          if (tags.isNotEmpty) {
                                            Categories category1 =
                                                Categories(tags);
                                            var firebaseUser = auth.currentUser;
                                            try {
                                              firestoreInstance
                                                  .collection(
                                                      "selectedcategories")
                                                  .doc(firebaseUser!.uid)
                                                  .set(category1.toMap())
                                                  .then((value) async {})
                                                  .onError((error,
                                                      stackTrace) async {});
                                            } catch (e) {
                                              flutterToast(e.toString());
                                            }
                                          }
                                          setState(() {
                                            isLoading = false;
                                          });
                                          navigateWithNoBack(
                                              context, const MainScreenUser());
                                        },
                                        child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 80.0,
                                                vertical: 12.0),
                                            child: Text('Next')),
                                      ),
                              ],
                            ),
                    ])),
    );
  }
}
