import 'package:bookstore_recommendation_system_fyp/providers/bookListProvider.dart';
import 'package:bookstore_recommendation_system_fyp/providers/categoriesProvider.dart';
import 'package:bookstore_recommendation_system_fyp/providers/fileNamesProvider.dart';
import 'package:bookstore_recommendation_system_fyp/providers/freeRentPaidProvider.dart';
import 'package:bookstore_recommendation_system_fyp/providers/linkprovider.dart';
import 'package:bookstore_recommendation_system_fyp/providers/loadingProvider.dart';
import 'package:bookstore_recommendation_system_fyp/providers/loginsignupProvider.dart';
import 'package:bookstore_recommendation_system_fyp/providers/notificationLengthProvider.dart';
import 'package:bookstore_recommendation_system_fyp/providers/pdfProvider.dart';
import 'package:bookstore_recommendation_system_fyp/providers/selectedCategoryProvider.dart';
import 'package:bookstore_recommendation_system_fyp/providers/switchProvider.dart';
import 'package:bookstore_recommendation_system_fyp/providers/tagProvider.dart';
import 'package:bookstore_recommendation_system_fyp/providers/trendingProvider.dart';
import 'package:bookstore_recommendation_system_fyp/providers/userProfileProvider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:io';
import 'package:bookstore_recommendation_system_fyp/providers/bottomnavbarnotifier.dart';
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
import 'admin_screens/admin_main_screen.dart';
import 'providers/TimeLeftProvider.dart';
import 'providers/favoritebookProvider.dart';
import 'providers/hasDataFviewbookprovider.dart';
import 'providers/isDownloadingViewbookprovider.dart';
import 'providers/paymentprovider.dart';
import 'providers/authstatenotifier.dart';
import 'providers/recommendationViewBookProvider.dart';
import 'providers/subscribeViewBookProvider.dart';
import 'providers/themenotifier.dart';
import 'providers/userdataViewBookProvider.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
// import 'package:flutter_svg/svg.dart';
// import '../utils/navigation.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';

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
  // Stripe.publishableKey =
  //     "pk_test_51MWx8OAVMyklfe3CsjEzA1CiiY0XBTlHYbZ8jQlGtVFIwQi4aNeGv8J1HUw4rgSavMTLzTwgn0XRlwoTVRFXyu2h00mRUeWmAf";
  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider<ThemeNotifier>(
        create: (_) => ThemeNotifier(ThemeData(
            appBarTheme: AppBarTheme(color: Colors.green[300]),
            primarySwatch: primarycolor,
            fontFamily: GoogleFonts.acme().fontFamily)),
      ),
      ChangeNotifierProvider<InternetNotifier>(
          create: (_) => InternetNotifier(false)),
      ChangeNotifierProvider<AuthState>(create: (context) => AuthState()),
      ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ChangeNotifierProvider(
        create: (_) => BottomNavigationBarState(),
      ),
  ChangeNotifierProvider(
  create: (context) => BookListProvider(),),
      ChangeNotifierProvider(
        create: (context) => CategoryProvider(),
      ),
      ChangeNotifierProvider(
        create: (context) => NotificationLengthProvider(),
      ),
      ChangeNotifierProvider(
        create: (context) => TagProvider(),
      ),
      ChangeNotifierProvider(
        create: (context) => LoadingProvider(),
      ),
      ChangeNotifierProvider(
        create: (context) => TrendingProvider(),
      ),
      ChangeNotifierProvider(
        create: (context) => SwitchProvider(),
      ),
      ChangeNotifierProvider(
        create: (context) => UserProfileProvider(),
      ),
      ChangeNotifierProvider(
        create: (context) => PdfProvider(),
      ),
      ChangeNotifierProvider(
        create: (context) => SelectedCategoryProvider(),
      ),
  ChangeNotifierProvider(
  create: (context) => FreeRentPaidProvider(),
  ),
      ChangeNotifierProvider(
        create: (context) => FileNamesProvider(),
      ),
      ChangeNotifierProvider(
        create: (context) => LinkProvider(),
      ),
      ChangeNotifierProvider(
        create: (context) => LoginSignupProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => SubscribeViewBookProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => TimeLeftViewBookProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => FavoriteViewBookProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => isDownloadingViewBookProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => RecViewBookProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => UserViewBookProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => SubscribeViewBookProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => HasDataBookProvider(),
      )

      // Other providers here
    ], child: const beforeSplash()),
  );
//   } else {
//   // Permission is not granted
// SystemNavigator.pop();
// }
}

class beforeSplash extends StatefulWidget {
  const beforeSplash({super.key});

  @override
  State<beforeSplash> createState() => _beforeSplashState();
}

class _beforeSplashState extends State<beforeSplash> {
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      theme: ThemeData(
          appBarTheme: AppBarTheme(color: Colors.green[300]),textTheme: GoogleFonts.acmeTextTheme(),
          primarySwatch: primarycolor,
          primaryColor: primarycolor,
          fontFamily: GoogleFonts.acme().fontFamily),
      darkTheme: themeNotifier.getTheme(),
      debugShowCheckedModeBanner: false,
      home: const Splash(),
    );
  }
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
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('An error occurred. Please Reload the screen.'),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('Reload'),
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

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return MyHomePage();
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
    // timer = Timer.periodic(Duration(seconds: 1), (Timer t) async {
    //   final internetAvailabilityNotifier =
    //       Provider.of<InternetNotifier>(context, listen: false);
    //   try {
    //     final result = await InternetAddress.lookup('google.com');
    //     final result2 = await InternetAddress.lookup('facebook.com');
    //     // final result3 = await InternetAddress.lookup('microsoft.com');
    //     if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) ||
    //         (result2.isNotEmpty && result2[0].rawAddress.isNotEmpty)
    //         // ||
    //         // (result3.isNotEmpty && result3[0].rawAddress.isNotEmpty)
    //     ) {
    //       internetAvailabilityNotifier.setInternetAvailability(true);
    //     } else {}
    //   } on SocketException catch (_) {
    //     internetAvailabilityNotifier.setInternetAvailability(false);
    //   }
    // });
    Timer(
        const Duration(seconds: 3),
        () => Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const MyApp())));
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
  bool _isFirstTime = false;
  bool _isLoggedIn = false;

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  // }

  bool isAdminLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // timer = Timer.periodic(const Duration(seconds: 0), (Timer t) async {
    //   final internetAvailabilityNotifier =
    //       Provider.of<InternetNotifier>(context, listen: false);
    //   try {
    //     final result = await InternetAddress.lookup('google.com');
    //     // final result3 = await InternetAddress.lookup('microsoft.com');
    //     if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty)
    //         // ||
    //         // (result3.isNotEmpty && result3[0].rawAddress.isNotEmpty)
    //     ) {
    //       internetAvailabilityNotifier.setInternetAvailability(true);
    //     } else {}
    //   } on SocketException catch (_) {
    //     internetAvailabilityNotifier.setInternetAvailability(false);
    //   }
    // });


    Future.microtask(() async {
      await _checkFirstTime();
      if (auth.currentUser != null) {
        context.read<AuthState>().user = 1;

        // print('admin:::' + isAdminLoggedIn.toString());
        // print('chatthasohail');
      } else {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool? isLogged = prefs.getBool('isLoggedIn');
        if (isLogged == true) {
          setState(() {
            isAdminLoggedIn = isLogged!;
          });
        }
        context.read<AuthState>().user = null;
        // print('chatthasohail7');
      }
    });
  }

  Future<void> _checkFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(mounted) {
      setState(() {
        _isFirstTime = prefs.getBool('isFirstTime') ?? true;
        if (_isFirstTime) {
          prefs.setBool('isFirstTime', false);
        }
      });
    }
  }




  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final themeNotifier = Provider.of<ThemeNotifier>(context);
    // final authState = Provider.of<AuthState>(context);
    print('main');
    return
        //  internetAvailabilityNotifier.getInternetAvailability() == true?
        _isFirstTime
            ? const IntroScreen()
            :
        (

            Consumer<AuthState>(
        builder: (context, authState, _) {
          return
      authState.user==1
    ?  const MainScreenUser()
                : (isAdminLoggedIn ? const MainScreenAdmin() : const LoginScreen());
  }
            )
        );
  }
}

