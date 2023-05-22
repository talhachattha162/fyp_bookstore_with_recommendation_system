import 'package:bookstore_recommendation_system_fyp/main.dart';
import 'package:bookstore_recommendation_system_fyp/utils/global_variables.dart';
import 'package:bookstore_recommendation_system_fyp/utils/navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:widget_circular_animator/widget_circular_animator.dart';
import '../models/user.dart';
import '../providers/authstatenotifier.dart';
import '../providers/themenotifier.dart';
import '../utils/firebase_constants.dart';
import 'faqs_screen.dart';
import 'update_profile_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isSwitched = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final DocumentReference documentReference = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid);
  String photoUrl = '';
  String name1 = '';
  String balance = '';

  Future<void> loadData() async {
    final DocumentSnapshot documentSnapshot = await documentReference.get();

    if (documentSnapshot.exists) {
      final data = documentSnapshot.data() as Map<String, dynamic>;
      Users user1 = Users.fromMap(data);
      String name = user1.getName();
      final photo = user1.getPhoto();
      String balance1 = user1.getBalance.toString();
      if (mounted) {
        setState(() {
          name1 = name;
          photoUrl = photo;
          balance = balance1;
        });
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadData();
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
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Balance: \$$balance'),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
          WidgetCircularAnimator(
            size: 200,
            innerIconsSize: 3,
            outerIconsSize: 3,
            innerAnimation: Curves.easeInOutBack,
            outerAnimation: Curves.easeInOutBack,
            innerColor: Colors.deepPurple,
            outerColor: Colors.orangeAccent,
            innerAnimationSeconds: 10,
            outerAnimationSeconds: 10,
            child: Container(
              decoration:
              BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200]),
              child: CircleAvatar(
                    maxRadius: 40,
                    backgroundImage:
                        photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  ))),
                  const SizedBox(height: 10),
                  Text(name1,
                      style: TextStyle(
                          fontSize: subheadingSize,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                      height: height * 0.44,
                      width: width * 0.93,
                      child: ListView(
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(Icons.account_circle_outlined),
                            title: const Text('My Account'),
                            trailing: const Icon(Icons.chevron_right_sharp),
                            onTap: () {
                              navigateWithNoBack(
                                  context, const UpdateProfileScreen());
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.question_mark_outlined),
                            title: const Text('FAQS'),
                            trailing: const Icon(Icons.chevron_right_sharp),
                            onTap: () {
                              navigateWithNoBack(context, const FaqScreen());
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.mode_night_outlined),
                            title: const Text('Change Mode'),
                            trailing: Switch(
                                value: _isSwitched,
                                onChanged: (value) {
                                  themeNotifier.setTheme(themeNotifier
                                              .getTheme() ==
                                          ThemeData(
                                              // useMaterial3: true,
                                              appBarTheme: AppBarTheme(
                                                  color: Colors.green[300]),
                                              primarySwatch: primarycolor,
                                              fontFamily: GoogleFonts.acme().fontFamily)
                                      ? ThemeData.dark(useMaterial3: true,)
                                          .copyWith(
                                          colorScheme:
                                              ColorScheme.dark().copyWith(
                                            primary: darkprimarycolor,
                                            error: Colors.red,
                                            onPrimary: darkprimarycolor,
                                            outline: darkprimarycolor,
                                            primaryVariant: darkprimarycolor,
                                            onPrimaryContainer:
                                                darkprimarycolor,
                                          ),
                                  )
                                      : ThemeData(
                                          appBarTheme: AppBarTheme(
                                              color: Colors.green[300]),
                                          primarySwatch: primarycolor,

                                      fontFamily: GoogleFonts.acme().fontFamily));
                                  if (mounted) {
                                    setState(() {
                                      _isSwitched = value;
                                    });
                                  }
                                  if(themeNotifier
                                              .getTheme() ==
                                          ThemeData(
                                              // useMaterial3: true,
                                              appBarTheme: AppBarTheme(
                                                  color: Colors.green[300]),
                                              primarySwatch: primarycolor,
                                              fontFamily: GoogleFonts.acme().fontFamily)){
firestoreInstance
                                      .collection("darkmode")
                                      .doc(FirebaseAuth
                                          .instance.currentUser!.uid)
                                      .set({"darkmode1": false});
                                              }
                                              else{
                                                firestoreInstance
                                      .collection("darkmode")
                                      .doc(FirebaseAuth
                                          .instance.currentUser!.uid)
                                      .set({"darkmode1": true});
                                              }

                                }),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.privacy_tip_outlined),
                            title: const Text('Privacy Policy'),
                            trailing: const Icon(Icons.chevron_right_sharp),
                            onTap: () {
                              var url =
                                  'https://doc-hosting.flycricket.io/booksavvy-privacy-policy/1c26b399-2650-460b-aae0-a2fc294cc458/privacy';
                              launchUrl(Uri.parse(url));
                            },
                          ),
                          const Divider(),
                          ListTile(
                              leading: const Icon(Icons.logout_outlined),
                              title: const Text('Log out'),
                              trailing: const Icon(Icons.chevron_right_sharp),
                              onTap: () async {
                                try {
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  bool isLoggedIn = false;
                                  prefs.setBool('isLoggedIn', isLoggedIn);
                                  // sign out of Firebase
                                  await auth.signOut();

                                  // sign out of Google Sign-In
                                  await _googleSignIn.signOut();

                                  // clear the cache
                                  await _googleSignIn.disconnect();
                                } catch (e) {
                                  // handle error
                                  print('error' + e.toString());
                                }
                                User? user;
                                // navigateWithNoBackplus(context, LoginScreen());
                                if (user == null) {
                                  // print('hello');
                                  context.read<AuthState>().user = null;
                                  navigateWithNoBack(context, MyApp());
                                }
                              }),
                        ],
                      ))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
