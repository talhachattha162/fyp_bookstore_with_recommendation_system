import 'dart:async';
import 'dart:io';
import 'package:bookstore_recommendation_system_fyp/providers/internetavailabilitynotifier.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/login_screen.dart';
// import 'package:bookstore_recommendation_system_fyp/user_screens/select_categories_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/user_main_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/firebase_constants.dart';
import 'package:bookstore_recommendation_system_fyp/utils/global_variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/authstatenotifier.dart';
import 'providers/themenotifier.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_svg/svg.dart';

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
      child: Splash(),
    ),
  );
//   } else {
//   // Permission is not granted
// SystemNavigator.pop();
// }
}

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
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
    Timer(
        Duration(seconds: 3),
        () => Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => MyApp())));
            
  }
    @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.white,
        child: Hero(
            tag: "logo",
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset('lib/assets/images/logo.png'),
              ),
            )));
  }
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
  
    Future.microtask(() {
      if (auth.currentUser != null) {
        context.read<AuthState>().user = 1;
        // print('chatthasohail');
      } else {
        context.read<AuthState>().user = null;
        // print('chatthasohail7');
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

    // print('main');
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
                : MainScreenUser());
  }
}
