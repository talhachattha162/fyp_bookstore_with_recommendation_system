import 'dart:async';
import 'dart:io';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bookstore_recommendation_system_fyp/admin_screens/admin_main_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/user_main_screen.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  RegExp email_valid = RegExp(r'\S+@\S+\.\S+');
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool isLoading = false;
  bool isGoogleLoading = false;
  Timer? timer;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 0), (Timer t) async {

      final internetAvailabilityNotifier =
          Provider.of<InternetNotifier>(context, listen: false);
      internetAvailabilityNotifier.setInternetAvailability(true);
      try {
        final result = await InternetAddress.lookup('google.com');
        // final result3 = await InternetAddress.lookup('microsoft.com');
        if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty)
            // ||
            // (result3.isNotEmpty && result3[0].rawAddress.isNotEmpty)
        ) {
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
            'google',
            0);
        var firebaseUser = auth.currentUser;
        firestoreInstance
            .collection("users")
            .doc(firebaseUser!.uid)
            .set(user1.toMap())
            .then((value) async {})
            .onError((error, stackTrace) async {

        });
        // final data = documentSnapshot.data() as Map<String, dynamic>;
        // Users user2 = Users.fromMap(data);
      }

      return user;
    } catch (e) {
      final snackBar = SnackBar(
        /// need to set following properties for best effect of awesome_snackbar_content
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,

        content: AwesomeSnackbarContent(
          title: 'Error!',
          message:
          'Error signing in with Google: ${e}',

          /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
          contentType: ContentType.failure,
        ),
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
      // flutterToast('');
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
        final snackBar = SnackBar(
          /// need to set following properties for best effect of awesome_snackbar_content
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,

          content: AwesomeSnackbarContent(
            title: 'Error!',
            message:
            'No user found',

            /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
            contentType: ContentType.failure,
          ),
        );

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
        // flutterToast('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        final snackBar = SnackBar(
          /// need to set following properties for best effect of awesome_snackbar_content
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,

          content: AwesomeSnackbarContent(
            title: 'Error!',
            message:
            'Wrong password}',

            /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
            contentType: ContentType.failure,
          ),
        );

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
        // flutterToast('Wrong password provided.');
      }
    }

    return user;
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

  FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    // print('login');
    User? user = _auth.currentUser;
    final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    double height = MediaQuery.of(context).size.height;
    return WillPopScope(
      onWillPop: onWillPop,
      child: SafeArea(
        child: internetAvailabilityNotifier.getInternetAvailability() == true
            ?  Scaffold(
                    resizeToAvoidBottomInset: false,
                    body:SizedBox(
                      height:height ,
                      child: SingleChildScrollView(
                          child: Column(children: [
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
                                suffixIcon: Text(''),
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
                                textInputType: TextInputType.visiblePassword,
                                textEditingController: _passwordController,
                                isPassword: _obscureText,
                                validator: (value) {
                                  String password = value.trim();
                                  if (password.length < 8) {
                                    return 'Password must be at least 8 characters';
                                  }
                                  if (!RegExp(r'[A-Z]').hasMatch(password)) {
                                    return 'Include at least 1 uppercase letter';
                                  }
                                  if (!RegExp(r'[a-z]').hasMatch(password)) {
                                    return 'Include at least 1 lowercase letter';
                                  }
                                  if (!RegExp(r'\d').hasMatch(password)) {
                                    return 'Include at least 1 digit';
                                  }
                                  if (!RegExp(r'\W').hasMatch(password)) {
                                    return 'Include at least 1 special character';
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
                                        if (mounted) {
                                          setState(() {
                                            isLoading = true;
                                          });
                                        }
                                        if (_emailController.text ==
                                            'abctalhachattha162@gmail.com') {
                                          SharedPreferences prefs =
                                              await SharedPreferences.getInstance();
                                              Users users = Users("admin", "admin", "", "admin", "admin",
          "", 0, 'admin', 0);
                                          firestoreInstance
                                              .collection("users")
                                              .doc("admin")
                                              .set(users.toMap());
                                          bool isLoggedIn = true;
                                          prefs.setBool('isLoggedIn', isLoggedIn);
                                          navigateWithNoBack(context,
                                              const MainScreenAdmin()); //admin data will not be stored to firebase
                                        } else {
                                          User? user =
                                              await signInUsingEmailPassword(
                                                  context: context,
                                                  email: _emailController.text,
                                                  password:
                                                      _passwordController.text);
                                          if (user != null) {
                                            DocumentReference documentReference = firestore.collection('users').doc(user.uid);
                                            await documentReference.update({
                                              'password': _passwordController.text,
                                            });
                                            context.read<AuthState>().user = 1;
                                            navigateWithNoBack(context, MyApp());
                                            // here
                                          }
                                        }
                                        if (mounted) {
                                          setState(() {
                                            isLoading = false;
                                          });
                                        }
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
                                              .copyWith(
                                            colorScheme:
                                                ColorScheme.dark().copyWith(
                                              primary: darkprimarycolor,
                                              error: Colors.red,
                                              onPrimary: darkprimarycolor,
                                              outline: darkprimarycolor,
                                              primaryVariant: darkprimarycolor,
                                              onPrimaryContainer: darkprimarycolor,
                                            ),
                                          )
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
                                      if (mounted) {
                                        setState(() {
                                          isGoogleLoading = true;
                                        });
                                      }

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
                                      if (mounted) {
                                        setState(() {
                                          isGoogleLoading = false;
                                        });
                                      }
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
              ),
            ):InternetChecker()
      ),
    );
  }
}
