import 'dart:async';
import 'dart:io';

import 'package:bookstore_recommendation_system_fyp/user_screens/login_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../Widgets/text_field.dart';
import '../models/user.dart';
import '../providers/internetavailabilitynotifier.dart';
import '../providers/themenotifier.dart';
import '../utils/InternetChecker.dart';
import '../utils/firebase_constants.dart';
import 'email_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  RegExp pass_valid = RegExp(r"(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*\W)");
  RegExp email_valid = RegExp(r'\S+@\S+\.\S+');
  RegExp name_valid = RegExp(r"^[a-zA-Z]+(([',. -][a-zA-Z ])?[a-zA-Z]*)*$");
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  Timer? timer;
  bool _isLoading = false;
  bool _obscureText = true;

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

  static signUp(
      {required String name,
      required String userEmail,
      required String password,
      required BuildContext context}) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: userEmail, password: password);
      Users users = Users(auth.currentUser!.uid, name, '', userEmail, password,
          '', 0, 'email', 0);
      var firebaseUser = auth.currentUser;
      firestoreInstance
          .collection("users")
          .doc(firebaseUser!.uid)
          .set(users.toMap())
          .then((value) async {
            firestoreInstance
                                      .collection("darkmode")
                                      .doc(FirebaseAuth
                                          .instance.currentUser!.uid)
                                      .set({"darkmode1": false});
          })
          .onError((error, stackTrace) async {});
      // auth.signOut();


      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('The password provided is too weak.')));
      } else if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('The account already exists for that email.')));
        return 'exist';
      }
      return null;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
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
    final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return WillPopScope(
      onWillPop: onWillPop,
      child: SafeArea(
        child: internetAvailabilityNotifier.getInternetAvailability() == false
            ? InternetChecker()
            : Scaffold(
                resizeToAvoidBottomInset: false,
                body: Column(children: [
                  const SizedBox(
                    height: 15,
                  ),
                  themeNotifier.getTheme() == ThemeData.dark(useMaterial3: true)
                      ? SvgPicture.asset('lib/assets/images/signupblue.svg',
                          semanticsLabel: 'Signup', height: 250, width: 200)
                      : SvgPicture.asset('lib/assets/images/signup.svg',
                          semanticsLabel: 'Signup', height: 250, width: 200),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          child: TextInputField(
                            hintText: 'Enter Name',
                            suffixIcon: Text(''),
                            textInputType: TextInputType.name,
                            textEditingController: _nameController,
                            isPassword: false,
                            validator: (value) {
                              if (!name_valid.hasMatch(value)) {
                                return 'Enter valid name';
                              }
                              if (value.length > 25) {
                                return 'Name should be less\n than 25 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          child: TextInputField(
                            hintText: 'Enter Email',
                            suffixIcon: Text(''),
                            textInputType: TextInputType.emailAddress,
                            textEditingController: _emailController,
                            isPassword: false,
                            validator: (value) {
                              if (!email_valid.hasMatch(value)) {
                                return 'Please enter valid email';
                              }
                              if (value.length > 40) {
                                return 'Enter email with less\n than 40 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          child: TextInputField(
                            hintText: 'Enter Password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                if (mounted) {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                }
                              },
                            ),
                            textInputType: TextInputType.text,
                            textEditingController: _passwordController,
                            isPassword: _obscureText,
                            validator: (value) {
                              String password = value.trim();
                              if (!pass_valid.hasMatch(password)) {
                                return 'password should contain capital,\nsmall,number,special characters';
                              }
                              if (value.length < 8) {
                                return 'Password should be 8 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(
                          height: 20.0,
                        ),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    if (mounted) {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                    }
                                    final u = await signUp(
                                        name: _nameController.text,
                                        userEmail: _emailController.text,
                                        password: _passwordController.text,
                                        context: context);
                                    if (u != 'exist') {
                                      
                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (ctx) =>
                                                  EmailVerificationScreen(
                                                      email:
                                                          _emailController.text,
                                                      password:
                                                          _passwordController
                                                              .text)));
                                    }
                                    if (mounted) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }
                                  }
                                },
                                child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 75.0, vertical: 12.0),
                                    child: Text('Signup')),
                              ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account?"),
                            TextButton(
                                onPressed: () {
                                  navigateWithNoBack(
                                      context, const LoginScreen());
                                },
                                child: const Text('Login'))
                          ],
                        )
                      ],
                    ),
                  ),
                ])),
      ),
    );
  }
}
