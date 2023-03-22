import 'dart:async';
import 'dart:io';
import 'package:bookstore_recommendation_system_fyp/user_screens/home_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/library_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/trending_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/upload_book_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/InternetChecker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/authstatenotifier.dart';
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
  int _selectedIndex = 0;
  static const List<Widget> _bottomNavigationItems = <Widget>[
    HomeScreen(),
    TrendingScreen(),
    UploadBookScreen(),
    LibraryScreen(),
    UserProfileScreen()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: internetAvailabilityNotifier.getInternetAvailability() == false
          ? InternetChecker()
          : Provider.of<AuthState>(context, listen: true).user == null
              ? LoginScreen()
              : Center(
                  child: _bottomNavigationItems.elementAt(_selectedIndex),
                ),
      bottomNavigationBar:
          internetAvailabilityNotifier.getInternetAvailability() == false
              ? null
              : Provider.of<AuthState>(context, listen: true).user == null
                  ? null
                  : BottomNavigationBar(
                      items: <BottomNavigationBarItem>[
                          BottomNavigationBarItem(
                            icon: Icon(
                              CupertinoIcons.home,
                            ),
                            label: 'Home',
                            backgroundColor: themeNotifier.getTheme() ==
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
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.recommend_outlined),
                            label: 'Trendings',
                            backgroundColor: themeNotifier.getTheme() ==
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
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.upload_outlined),
                            label: 'Upload Book',
                            backgroundColor: themeNotifier.getTheme() ==
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
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.library_books_outlined),
                            label: 'Library',
                            backgroundColor: themeNotifier.getTheme() ==
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
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.person_outline_outlined),
                            label: 'Profile',
                            backgroundColor: themeNotifier.getTheme() ==
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
                          ),
                        ],
                      type: BottomNavigationBarType.shifting,
                      currentIndex: _selectedIndex,
                      selectedItemColor: Colors.white,
                      iconSize: 24,
                      selectedLabelStyle: const TextStyle(fontSize: 10),
                      onTap: _onItemTapped,
                      elevation: 5),
    );
  }
}
