import 'dart:async';
import 'dart:io';
import 'package:bookstore_recommendation_system_fyp/admin_screens/admin_main_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../Widgets/text_field.dart';
import '../main.dart';
import '../models/user.dart';
import '../providers/authstatenotifier.dart';
import '../providers/internetavailabilitynotifier.dart';
import '../providers/themenotifier.dart';
import '../utils/InternetChecker.dart';
import '../utils/firebase_constants.dart';
import '../utils/fluttertoast.dart';
import '../utils/global_variables.dart';
import '../utils/navigation.dart';
import '../utils/snackbar.dart';
import 'reset_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  RegExp pass_valid = RegExp(r"(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*\W)");
  RegExp email_valid = RegExp(r'\S+@\S+\.\S+');
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool isLoading = false;
  bool isGoogleLoading = false;
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

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<User?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final User? user = (await auth.signInWithCredential(credential)).user;
      final DocumentReference documentReference = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid);
      final DocumentSnapshot documentSnapshot = await documentReference.get();

      if (!documentSnapshot.exists) {
        Users user1 = Users(
            FirebaseAuth.instance.currentUser!.uid,
            user!.displayName.toString(),
            '',
            user.email.toString(),
            '',
            user.photoURL.toString(),
            0,
            'google');
        var firebaseUser = auth.currentUser;
        firestoreInstance
            .collection("users")
            .doc(firebaseUser!.uid)
            .set(user1.toMap())
            .then((value) async {})
            .onError((error, stackTrace) async {});
        // final data = documentSnapshot.data() as Map<String, dynamic>;
        // Users user2 = Users.fromMap(data);
      }

      return user;
    } catch (e) {
      flutterToast('Error signing in with Google: ${e}');
    }
  }

  static Future<User?> signInUsingEmailPassword({
    required String email,
    required String password,
    required BuildContext context,
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
        flutterToast('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        flutterToast('Wrong password provided.');
      }
    }

    return user;
  }

  @override
  Widget build(BuildContext context) {
    final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return SafeArea(
      child: internetAvailabilityNotifier.getInternetAvailability() == false
          ? InternetChecker()
          : Scaffold(
              resizeToAvoidBottomInset: false,
              body: Column(children: [
                const SizedBox(
                  height: 10,
                ),
                themeNotifier.getTheme() == ThemeData.dark(useMaterial3: true)
                    ? SvgPicture.asset('lib/assets/images/signinblue.svg',
                        semanticsLabel: 'Login', height: 250, width: 200)
                    : SvgPicture.asset('lib/assets/images/login.svg',
                        semanticsLabel: 'Login', height: 250, width: 200),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 4.0),
                        child: TextInputField(
                          hintText: 'Enter Email',
                          textInputType: TextInputType.emailAddress,
                          textEditingController: _emailController,
                          isPassword: false,
                          validator: (value) {
                            if (!email_valid.hasMatch(value)) {
                              return 'Enter valid email';
                            }
                            if (value.length > 40) {
                              return 'Enter valid email';
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
                          textInputType: TextInputType.visiblePassword,
                          textEditingController: _passwordController,
                          isPassword: false,
                          validator: (value) {
                            String password = value.trim();
                            if (!pass_valid.hasMatch(password)) {
                              return 'Enter valid password ';
                            }
                            if (value.length < 8) {
                              return 'Enter valid password ';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 20.0,
                      ),
                      isLoading == true
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    isLoading = true;
                                  });

                                  if (_emailController.text ==
                                      'talhachattha162@gmail.com') {
                                    navigateWithNoBack(context,
                                        const MainScreenAdmin()); //admin data will not be stored to firebase
                                  } else {
                                    User? user = await signInUsingEmailPassword(
                                        context: context,
                                        email: _emailController.text,
                                        password: _passwordController.text);
                                    if (user != null) {
                                      context.read<AuthState>().user = 1;
                                      navigateWithNoBack(context, MyApp());
                                      // here
                                    }
                                  }
                                  setState(() {
                                    isLoading = false;
                                  });
                                }

                                // showSnackBar(context, 'Logined');
                              },
                              child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 75.0, vertical: 12.0),
                                  child: Text('Login')),
                            ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(0, 0, 60, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                                onPressed: () {
                                  navigateWithNoBack(
                                      context, const ResetPasswordScreen());
                                },
                                child: Text(
                                  'Reset Password',
                                  style: TextStyle(fontSize: 12),
                                )),
                          ],
                        ),
                      ),
                      Text(
                        'OR',
                        style: TextStyle(
                            color: themeNotifier.getTheme() ==
                                    ThemeData.dark(useMaterial3: true)
                                ? darkprimarycolor
                                : primarycolor,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      isGoogleLoading == true
                          ? CircularProgressIndicator()
                          : SignInButton(
                              Buttons.Google,
                              text: "Sign in with Google",
                              onPressed: () async {
                                // try {
                                setState(() {
                                  isGoogleLoading = true;
                                });

                                User? user;
                                try {
                                  user = await _signInWithGoogle();
                                } on PlatformException catch (e) {
                                  flutterToast(
                                      'Error signing in with Google: ${e.message}');
                                } catch (e) {
                                  flutterToast(e);
                                }
                                if (user != null) {
                                  context.read<AuthState>().user = 1;
                                  navigateWithNoBack(context, MyApp());
                                }
                                setState(() {
                                  isGoogleLoading = false;
                                });
                              },
                            ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?"),
                          TextButton(
                              onPressed: () {
                                navigateWithNoBack(
                                    context, const SignUpScreen());
                              },
                              child: const Text('Signup'))
                        ],
                      )
                    ],
                  ),
                ),
              ])),
    );
  }
}
