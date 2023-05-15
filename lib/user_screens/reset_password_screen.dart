import 'dart:async';
import 'dart:io';

import 'package:bookstore_recommendation_system_fyp/user_screens/signup_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/internetavailabilitynotifier.dart';
import '../utils/InternetChecker.dart';
import '../utils/firebase_constants.dart';
import '../utils/fluttertoast.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

enum AuthStatus {
  successful,
  wrongPassword,
  emailAlreadyExists,
  invalidEmail,
  weakPassword,
  unknown,
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  bool isLoading = false;
  resetPassword({required String email}) async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    await auth.sendPasswordResetEmail(email: email).then((value) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      flutterToast('Link send to $email for reset');
      navigateWithNoBack(context, LoginScreen());
    }).catchError((e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      flutterToast(e.toString());
    });
  }

  TextEditingController _emailforresetpasswordController =
      TextEditingController();

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

  Timer? timer;

  @override
  void initState() {
    // TODO: implement initState
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
    return internetAvailabilityNotifier.getInternetAvailability() == false
        ? InternetChecker()
        : WillPopScope(
            onWillPop: () async {
              navigateWithNoBack(context, LoginScreen());
              return false;
            },
            child: SafeArea(
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: AppBar(
                    title: const Text('Reset Passwords',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        navigateWithNoBack(context, const LoginScreen());
                      },
                    )
                ),
                body: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                        controller: _emailforresetpasswordController,
                      ),
                    ),
                    isLoading == true
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () {
                              resetPassword(
                                  email: _emailforresetpasswordController.text);
                            },
                            child: const Text('Reset Password'))
                  ],
                ),
              ),
            ),
          );
  }
}
