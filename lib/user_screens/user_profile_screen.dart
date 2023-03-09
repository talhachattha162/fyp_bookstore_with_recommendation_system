import 'package:bookstore_recommendation_system_fyp/main.dart';
import 'package:bookstore_recommendation_system_fyp/utils/global_variables.dart';
import 'package:bookstore_recommendation_system_fyp/utils/navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/authstatenotifier.dart';
import '../utils/firebase_constants.dart';
import 'faqs_screen.dart';
import 'update_profile_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isSwitched = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final DocumentReference documentReference = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid);
  String photoUrl = '';
  String name1 = '';

  Future<void> loadData() async {
    final DocumentSnapshot documentSnapshot = await documentReference.get();

    if (documentSnapshot.exists) {
      final data = documentSnapshot.data() as Map<String, dynamic>;
      Users user1 = Users.fromMap(data);
      String name = user1.getName();
      final photo = user1.getPhoto();
      if (mounted) {
        setState(() {
          name1 = name;
          photoUrl = photo;
        });
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        body: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 40,
                ),
                CircleAvatar(
                  maxRadius: 60,
                  backgroundImage:
                      photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                ),
                const SizedBox(height: 20),
                Text(name1,
                    style: TextStyle(
                        fontSize: subheadingSize, fontWeight: FontWeight.bold)),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                    height: height * 0.59,
                    width: width * 0.93,
                    child: ListView(
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.account_circle_outlined),
                          title: const Text('My Account'),
                          trailing: const Icon(Icons.chevron_right_sharp),
                          onTap: () {
                            navigateWithNoBack(
                                context, const UpdateProfileScreen());
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.question_mark_outlined),
                          title: const Text('FAQS'),
                          trailing: const Icon(Icons.chevron_right_sharp),
                          onTap: () {
                            navigateWithNoBack(context, const FaqScreen());
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.mode_night_outlined),
                          title: const Text('Dark Mode'),
                          trailing: Switch(
                              value: _isSwitched,
                              onChanged: (value) {
                                setState(() {
                                  _isSwitched = value;
                                });
                              }),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.privacy_tip_outlined),
                          title: const Text('Privacy Policy'),
                          trailing: const Icon(Icons.chevron_right_sharp),
                          onTap: () {
                            // navigateWithNoBack(context, PrivacyPolicyScreen());
                          },
                        ),
                        const Divider(),
                        ListTile(
                            leading: const Icon(Icons.logout_outlined),
                            title: const Text('Log out'),
                            trailing: const Icon(Icons.chevron_right_sharp),
                            onTap: () {
                              auth.signOut();
                              _googleSignIn.signOut();
                              User? user;
                              context.read<AuthState>().user = null;
                              // navigateWithNoBackplus(context, LoginScreen());
                              print('chattha' +
                                  Provider.of<AuthState>(context, listen: false)
                                      .user
                                      .toString());
                              if (user == null) {
                                navigateWithNoBack(context, MyApp());
                              }
                            }),
                      ],
                    ))
              ],
            ),
          ],
        ),
      ),
    );
  }
}
