import 'dart:async';
import 'dart:io';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:motion_toast/motion_toast.dart';
import 'package:provider/provider.dart';
import '../providers/internetavailabilitynotifier.dart';
import '../utils/InternetChecker.dart';
import '../utils/firebase_constants.dart';
import '../utils/fluttertoast.dart';
import '../utils/navigation.dart';
// import '../utils/snackbar.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  String email;
  String password;
  EmailVerificationScreen(
      {Key? key, required this.email, required this.password})
      : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isEmailVerified = false;
  Timer? timer;

  static Future<User?> signInUsingEmailPassword({
    required String email,
    required String password,
    context
  }) async {
    User? user;

    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        flutterToast("No user found for that email.");
      } else if (e.code == 'wrong-password') {
        flutterToast('Wrong password provided.');
      }
    }

    return user;
  }

  Timer? timer1;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    FirebaseAuth.instance.currentUser?.sendEmailVerification();
    // print('c111'+FirebaseAuth.instance.currentUser.toString());
    timer =
        Timer.periodic(const Duration(seconds: 3), (_) => checkEmailVerified());

    timer1 = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
       if (!mounted) {
    return; // exit if the widget is no longer mounted
  }
        final internetAvailabilityNotifier =
            Provider.of<InternetNotifier>(context, listen: false);
      
      try {
        final result = await InternetAddress.lookup('google.com');
        if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty)) {
          internetAvailabilityNotifier.setInternetAvailability(true);
        } else {}
      } on SocketException catch (_) {
        internetAvailabilityNotifier.setInternetAvailability(false);
      }
    });
  }

  checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser?.reload();
    if (mounted) {
      setState(() {
        isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
      });
    }

    if (isEmailVerified) {
      // TODO: implement your code after email verification
      final snackBar = SnackBar(
        /// need to set following properties for best effect of awesome_snackbar_content
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,

        content: AwesomeSnackbarContent(
          title: 'Success!',
          message:
          'Email Successfully Verified',

          /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
          contentType: ContentType.success,
        ),
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
      // showSnackBar(context, 'Email Successfully Verified');
      auth.signOut();
      navigateWithNoBack(context, const LoginScreen());
      timer?.cancel();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
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
          .showSnackBar(const SnackBar(content: Text('Press back again to exit')));
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context);
    return internetAvailabilityNotifier.getInternetAvailability() == false
        ? const InternetChecker()
        : WillPopScope(
            onWillPop: onWillPop,
            child: SafeArea(
              child: Scaffold(
                appBar: AppBar(
                    title: const Text('Verify Email'),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        navigateWithNoBack(context, const LoginScreen());
                      },
                    )),
                body: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      
                      const SizedBox(height: 35),
                      const Center(
                        child: Text(
                          'Note:Its not compulsory',
                          textAlign: TextAlign.center,
                          style:TextStyle(fontSize:8,color: Colors.grey)
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Center(
                        child: Text(
                          'Check your \n Email',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Center(
                          child: Text(
                            'We have sent you a Email on  ${auth.currentUser?.email}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.0),
                        child: Center(
                          child: Text(
                            'Verifying email....',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 57),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: ElevatedButton(
                          child: const Text('Resend'),
                          onPressed: () {
                            try {
                              FirebaseAuth.instance.currentUser
                                  ?.sendEmailVerification();
                            } catch (e) {
                              final snackBar = SnackBar(
                                /// need to set following properties for best effect of awesome_snackbar_content
                                elevation: 0,
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.transparent,

                                content: AwesomeSnackbarContent(
                                  title: 'Error!',
                                  message:
                                  e.toString(),

                                  /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                                  contentType: ContentType.failure,
                                ),
                              );

                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(snackBar);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
