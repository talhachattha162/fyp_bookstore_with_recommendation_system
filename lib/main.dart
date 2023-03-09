import 'dart:async';
import 'dart:io';
import 'package:bookstore_recommendation_system_fyp/providers/internetavailabilitynotifier.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/login_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/select_categories_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/user_main_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/firebase_constants.dart';
import 'package:bookstore_recommendation_system_fyp/utils/global_variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/authstatenotifier.dart';
import 'providers/themenotifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Request permission again
  // if (await Permission.contacts.request().isGranted) {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>(
          create: (_) => ThemeNotifier(ThemeData(
              appBarTheme: AppBarTheme(color: Colors.green[300]),
              primarySwatch: primarycolor,
              fontFamily: 'RobotoMono')),
        ),
        ChangeNotifierProvider<InternetNotifier>(
            create: (_) => InternetNotifier(false)),
        ChangeNotifierProvider<AuthState>(create: (context) => AuthState()),
        // Other providers here
      ],
      child: const MyApp(),
    ),
  );
//   } else {
//   // Permission is not granted
// SystemNavigator.pop();
// }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
    var firebaseUser = auth.currentUser;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context);
    return MaterialApp(
        title: 'FYP',
        theme: ThemeData(
            appBarTheme: AppBarTheme(color: Colors.green[300]),
            primarySwatch: primarycolor,
            primaryColor: primarycolor,
            fontFamily: 'RobotoMono'),
        darkTheme: themeNotifier.getTheme(),
        debugShowCheckedModeBanner: false,
        home:
            //  internetAvailabilityNotifier.getInternetAvailability() == true?

            Provider.of<AuthState>(context, listen: true).user == null
                ? const LoginScreen()
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('selectedcategories')
                        .snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      // if (snapshot.hasError) {
                      //   return Text('Error: ${snapshot.error}');
                      // }
                      if (snapshot.data != null) {
                        List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

                        for (var doc in docs) {
                          if (doc.id == firebaseUser!.uid) {
                            return MainScreenUser();
                          }
                        }
                      }
                      return SelectCategoriesScreen();
                    },
                  )

        // : InternetChecker()
        );
  }
}
