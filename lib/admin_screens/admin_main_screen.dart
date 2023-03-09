import 'dart:async';
import 'dart:io';

import 'package:bookstore_recommendation_system_fyp/admin_screens/add_remove_categories_screen.dart';
import 'package:bookstore_recommendation_system_fyp/admin_screens/permissions_screen.dart';
import 'package:bookstore_recommendation_system_fyp/admin_screens/add_remove_users_screen.dart';
import 'package:bookstore_recommendation_system_fyp/providers/internetavailabilitynotifier.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/upload_book_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/themenotifier.dart';
import '../utils/InternetChecker.dart';
import '../utils/global_variables.dart';

class MainScreenAdmin extends StatefulWidget {
  const MainScreenAdmin({super.key});

  @override
  State<MainScreenAdmin> createState() => _MainScreenAdminState();
}

class _MainScreenAdminState extends State<MainScreenAdmin> {
  int _selectedIndex = 0;
  static const List<Widget> _bottomNavigationItems = <Widget>[
    AddRemoveUser(),
    UploadBookScreen(),
    AddRemoveCategories(),
    Permissions()
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
    return internetAvailabilityNotifier.getInternetAvailability() == false
        ? InternetChecker()
        : Scaffold(
            resizeToAvoidBottomInset: false,
            body: Center(
              child: _bottomNavigationItems.elementAt(_selectedIndex),
            ),
            bottomNavigationBar: BottomNavigationBar(
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                      icon: Icon(
                        Icons.supervised_user_circle_outlined,
                      ),
                      label: 'Users',
                      backgroundColor: themeNotifier.getTheme() ==
                              ThemeData.dark(useMaterial3: true)
                          ? darkprimarycolor
                          : primarycolor),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.upload),
                      label: 'Upload',
                      backgroundColor: themeNotifier.getTheme() ==
                              ThemeData.dark(useMaterial3: true)
                          ? darkprimarycolor
                          : primarycolor),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.category_outlined),
                      label: 'Categories',
                      backgroundColor: themeNotifier.getTheme() ==
                              ThemeData.dark(useMaterial3: true)
                          ? darkprimarycolor
                          : primarycolor),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.add_moderator_outlined),
                      label: 'Permissions',
                      backgroundColor: themeNotifier.getTheme() ==
                              ThemeData.dark(useMaterial3: true)
                          ? darkprimarycolor
                          : primarycolor),
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
