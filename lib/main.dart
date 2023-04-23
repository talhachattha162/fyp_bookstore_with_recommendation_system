import 'dart:async';
import 'dart:io';
import 'package:bookstore_recommendation_system_fyp/providers/internetavailabilitynotifier.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/intro_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/login_screen.dart';
// import 'package:bookstore_recommendation_system_fyp/user_screens/select_categories_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/user_main_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/firebase_constants.dart';
import 'package:bookstore_recommendation_system_fyp/utils/global_variables.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/paymentprovider.dart';
import 'providers/authstatenotifier.dart';
import 'providers/themenotifier.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_svg/svg.dart';
import '../utils/navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // FlutterError.onError = (FlutterErrorDetails details) {
  //   if (navigatorKey.currentContext != null) {
  //     showDialog(
  //       context: navigatorKey.currentContext!,
  //       builder: (context) {
  //         return AlertDialog(
  //           title: Text('Error'),
  //           content: Text('An error occurred. Please reload.'),
  //           actions: [
  //             ElevatedButton(
  //               child: Text('Reload'),
  //               onPressed: () {
  //                 // Dismiss the AlertDialog
  //                 navigateWithNoBack(context, MainScreenUser());
  //               },
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   }
  // };

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
        ChangeNotifierProvider(create: (_) => PaymentProvider())
        // Other providers here
      ],
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        home: Splash(),
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
//   } else {
//   // Permission is not granted
// SystemNavigator.pop();
// }
}

class ErrorPage extends StatefulWidget {
  @override
  _ErrorPageState createState() => _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('An error occurred. Please Reload the screen.'),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('Reload'),
              onPressed: () {
                // Reload the current screen
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  Widget build(BuildContext context) {
    return MyHomePage();
  }

  @override
  void initState() {
    super.initState();
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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? timer;
  bool _isFirstTime = true;
  bool _isLoggedIn = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAuthStatus();
  }

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
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

  Future<void> _checkFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFirstTime = prefs.getBool('isFirstTime') ?? true;
      if (_isFirstTime) {
        prefs.setBool('isFirstTime', false);
      }
    });
  }

  void _checkAuthStatus() {
    setState(() {
      _isLoggedIn = Provider.of<AuthState>(context, listen: true).user != null;
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

    // print('main');
    return 
          //  internetAvailabilityNotifier.getInternetAvailability() == true?
          _isFirstTime
              ? IntroScreen()
              : (_isLoggedIn ? MainScreenUser() : LoginScreen())
    ;
  }
}
