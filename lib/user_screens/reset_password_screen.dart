import 'package:bookstore_recommendation_system_fyp/utils/navigation.dart';
import 'package:flutter/material.dart';

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
    setState(() {
      isLoading = true;
    });
    await auth.sendPasswordResetEmail(email: email).then((value) {
      setState(() {
        isLoading = false;
      });
      flutterToast('Link send to $email for reset');
      navigateWithNoBack(context, LoginScreen());
    }).catchError((e) {
      setState(() {
        isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
              title: const Text('Reset Passwords',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  navigateWithNoBack(context, const LoginScreen());
                },
              )),
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
