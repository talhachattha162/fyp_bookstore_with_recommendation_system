import 'dart:async';
import 'dart:io';
import 'package:bookstore_recommendation_system_fyp/user_screens/home_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/library_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/trending_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/upload_book_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/InternetChecker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/authstatenotifier.dart';
import '../providers/bottomnavbarnotifier.dart';
import '../providers/internetavailabilitynotifier.dart';
import '../providers/themenotifier.dart';
import '../utils/global_variables.dart';
import 'login_screen.dart';
import 'user_profile_screen.dart';

class MainScreenUser extends StatefulWidget {
  const MainScreenUser({super.key});

  @override
  State<MainScreenUser> createState() => _MainScreenUserState();
}

class _MainScreenUserState extends State<MainScreenUser> {
  // int _selectedIndex = 0;
  static const List<Widget> _bottomNavigationItems = <Widget>[
    HomeScreen(),
    TrendingScreen(),
    UploadBookScreen(),
    LibraryScreen(),
    UserProfileScreen()
  ];

  void _onItemTapped(int index) {
    final state = Provider.of<BottomNavigationBarState>(context, listen: false);
    if (state.isEnabled()) {
      state.setSelectedIndex(index);
    }
  }


  Timer? timer;

  Future checkDarkMode(String userId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference documentReference =
        firestore.collection('darkmode').doc(userId);
    final DocumentSnapshot snapshot = await documentReference.get();
    // print(snapshot.id.toString());
    // print(snapshot.data());
    if (snapshot.exists) {
      final darkmode = snapshot.get('darkmode1');
      return darkmode;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // print('usermaininit');
    // timer = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
    //   final internetAvailabilityNotifier =
    //       Provider.of<InternetNotifier>(context, listen: false);
    //   try {
    //     final result = await InternetAddress.lookup('google.com');
    //     if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) ) {
    //       internetAvailabilityNotifier.setInternetAvailability(true);
    //     } else {}
    //   } on SocketException catch (_) {
    //     internetAvailabilityNotifier.setInternetAvailability(false);
    //   }
    // });
    Future.delayed(Duration.zero, () async {
      final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
      themeNotifier.setTheme(
          await checkDarkMode(FirebaseAuth.instance.currentUser!.uid) == true
              ? ThemeData.dark(useMaterial3: true).copyWith(
                  colorScheme: const ColorScheme.dark().copyWith(
                    primary: darkprimarycolor,
                    error: Colors.red,
                    onPrimary: darkprimarycolor,
                    outline: darkprimarycolor,
                    primaryVariant: darkprimarycolor,
                    onPrimaryContainer: darkprimarycolor,
                  ),
                )
              : ThemeData(
                  appBarTheme: AppBarTheme(color: Colors.green[300]),
                  primarySwatch: primarycolor,
                  fontFamily: GoogleFonts.acme().fontFamily));
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
        now.difference(currentBackPressTime) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: const Text('Press back again to exit')));
      return Future.value(false);
    }
    return Future.value(true);
  }


  @override
  Widget build(BuildContext context) {
    // print('usermain');
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    // final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context,listen: true);
    final state = Provider.of<BottomNavigationBarState>(context, listen: true);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body:
      // internetAvailabilityNotifier.getInternetAvailability() == false
      //     ? const InternetChecker()
      //     :
      Provider.of<AuthState>(context, listen: false).user == null
              ? const LoginScreen()
              : Center(
                  child: _bottomNavigationItems.elementAt(state.getSelectedIndex()),
                ),
      bottomNavigationBar:
          // internetAvailabilityNotifier.getInternetAvailability() == false
          //     ? null
          //     :
          Provider.of<AuthState>(context, listen: false).user == null
                  ? null
                  :
          BottomNavigationBar(
                          showUnselectedLabels: true,
                          items: <BottomNavigationBarItem>[
                              BottomNavigationBarItem(
                                icon: const Icon(
                                  CupertinoIcons.home,// Set the default color for the unselected icon
                                ),
                                label: 'Home',
                                backgroundColor: themeNotifier.getTheme() ==
                                        ThemeData.dark(useMaterial3: true).copyWith(
                                          colorScheme: const ColorScheme.dark().copyWith(
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
                              ),
                              BottomNavigationBarItem(
                                icon: const Icon(Icons.recommend_outlined),
                                label: 'Trendings',
                                backgroundColor: themeNotifier.getTheme() ==
                                        ThemeData.dark(useMaterial3: true).copyWith(
                                          colorScheme: const ColorScheme.dark().copyWith(
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
                              ),
                              BottomNavigationBarItem(
                                icon: const Icon(Icons.upload_outlined),
                                label: 'Upload Book',
                                backgroundColor: themeNotifier.getTheme() ==
                                        ThemeData.dark(useMaterial3: true).copyWith(
                                          colorScheme: const ColorScheme.dark().copyWith(
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
                              ),
                              BottomNavigationBarItem(
                                icon: const Icon(Icons.library_books_outlined),
                                label: 'Library',
                                backgroundColor: themeNotifier.getTheme() ==
                                        ThemeData.dark(useMaterial3: true).copyWith(
                                          colorScheme: const ColorScheme.dark().copyWith(
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
                              ),
                              BottomNavigationBarItem(
                                icon: const Icon(Icons.person_outline_outlined),
                                label: 'Profile',
                                backgroundColor: themeNotifier.getTheme() ==
                                        ThemeData.dark(useMaterial3: true).copyWith(
                                          colorScheme: const ColorScheme.dark().copyWith(
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
                              ),
                            ],
                          type: BottomNavigationBarType.shifting,
              currentIndex: state.getSelectedIndex(),
                          selectedItemColor: themeNotifier.getTheme() ==
                              ThemeData.dark(useMaterial3: true).copyWith(
                                colorScheme: const ColorScheme.dark().copyWith(
                                  primary: darkprimarycolor,
                                  error: Colors.red,
                                  onPrimary: darkprimarycolor,
                                  outline: darkprimarycolor,
                                  primaryVariant: darkprimarycolor,
                                  onPrimaryContainer: darkprimarycolor,
                                ),
                              )
                              ?Colors.white:Colors.black45,
                          // iconSize: 24,
                          // selectedLabelStyle: const TextStyle(fontSize: 10),
                          onTap: _onItemTapped,
                          elevation: 5)
    );
  }
}
