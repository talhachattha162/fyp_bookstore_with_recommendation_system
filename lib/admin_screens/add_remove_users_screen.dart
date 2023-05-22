import 'package:bookstore_recommendation_system_fyp/user_screens/login_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/themenotifier.dart';
import '../utils/firebase_constants.dart';
import '../utils/global_variables.dart';
import 'dart:io';

class AddRemoveUser extends StatefulWidget {
  const AddRemoveUser({super.key});

  @override
  State<AddRemoveUser> createState() => _AddRemoveUserState();
}

class _AddRemoveUserState extends State<AddRemoveUser> {
  List<Users> _users = [];

  @override
  void initState() {
    super.initState();
  }
// Function to log in as a user
  Future<void> login(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // print('Logged in successfully');
    } catch (e) {
      // print('Failed to log in: $e');
    }
  }

// Function to delete the authenticated user
  Future<void> deleteCurrentUser(String email, String password) async {
    try {
      await login(email, password);
      await Future.delayed(Duration(seconds: 2)); // Add a delay to ensure login is completed
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
        // print('User deleted successfully');
      } else {
        print('No user is currently logged in');
      }
    } catch (e) {
      // print('Failed to delete user: $e');
    }
  }

  Stream<QuerySnapshot> getUsers() {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference categoriesRef = firestore.collection('users');
    return categoriesRef.snapshots();
  }

  Stream<List<Users>> get _usersStream {
    return FirebaseFirestore.instance.collection('users').snapshots().map(
        (QuerySnapshot snapshot) => snapshot.docs
            .map((DocumentSnapshot doc) => Users(
                doc['uid'],
                doc['name'],
                doc['age'],
                doc['email'],
                doc['password'],
                doc['photo'],
                doc['balance'],
                doc['authenticationmethod'],
                doc['notifications']))
            .toList());
  }

  Future<void> _deleteUser(Users users) async {
    // Check if the user has any book collection
    final bookCollectionQuery = FirebaseFirestore.instance
        .collection('books')
        .where('userid', isEqualTo: users.uid);

    final bookCollectionSnapshot = await bookCollectionQuery.get();
    if (bookCollectionSnapshot.docs.isNotEmpty) {
      // If the user has book collections, show an error message
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error'),
          content: Text(
              'You cannot delete your account as you have uploaded books.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Ok'),
            ),
          ],
        ),
      );
    } else {
      // If the user hasn't uploaded any book collections, delete their account
      // if (users.authenticationmethod == 'email') {
      //   User? user;
      //   UserCredential userCredential = await auth.signInWithEmailAndPassword(
      //     email: users.email,
      //     password: users.password,
      //   );
      //   user = userCredential.user;
      //   await user!.delete();
      //   auth.signOut();
      // }
      
        await deleteCurrentUser(users.email, users.password);
      FirebaseFirestore.instance.collection('users').doc(users.uid).delete();
    }
  }

// Define TextEditingController objects to control the text fields
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

// Show a dialog when the button is pressed
  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                ),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Create Account'),
              onPressed: () async {
                String email = _emailController.text.trim();
                String password = _passwordController.text.trim();

                try {
                  UserCredential userCredential = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                    email: email,
                    password: password,
                  );
                  Users u = Users(userCredential.user!.uid, '', '', email,
                      password, '', 0, 'email', 0);
                  // Add user to Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userCredential.user!.uid)
                      .set(u.toMap());
                  auth.signOut();
                  // Navigate to the home screen or do something else
                  // ...

                  Navigator.of(context).pop();
                } catch (e) {
                  // Handle error
                  // ...
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    double height = MediaQuery.of(context).size.height;
    return SafeArea(
        child: Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Users'),
        automaticallyImplyLeading: false,
        actions: [
          // IconButton(
          //     onPressed: () {
          //       themeNotifier.setTheme(themeNotifier.getTheme() ==
          //               ThemeData(
          //                   appBarTheme: AppBarTheme(color: Colors.green[300]),
          //                   primarySwatch: primarycolor,
          //                   fontFamily: 'RobotoMono')
          //           ? ThemeData.dark(useMaterial3: true).copyWith(
          //               colorScheme: ColorScheme.dark().copyWith(
          //                 primary: darkprimarycolor,
          //                 error: Colors.red,
          //                 onPrimary: darkprimarycolor,
          //                 outline: darkprimarycolor,
          //                 primaryVariant: darkprimarycolor,
          //                 onPrimaryContainer: darkprimarycolor,
          //               ),
          //             )
          //           : ThemeData(
          //               appBarTheme: AppBarTheme(color: Colors.green[300]),
          //               primarySwatch: primarycolor,
          //               fontFamily: 'RobotoMono'));
          //     },
          //     icon: const Icon(CupertinoIcons.moon)),
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                'Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Gmail',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              // Text(
              //   'Delete',
              //   style: TextStyle(fontWeight: FontWeight.bold),
              // ),
            ],
          ),
          Container(
              height: height * 0.65,
              padding: const EdgeInsets.all(10),
              child: StreamBuilder<List<Users>>(
                stream: _usersStream,
                builder: (BuildContext context,
                    AsyncSnapshot<List<Users>> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: const CircularProgressIndicator());
                  }
                  final users = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.only(
                        left: 10, bottom: 20, right: 6, top: 0),
                    itemCount: users.length,
                    itemBuilder: (BuildContext context, int index) {
                      Users user = users[index];
                      String email = user.email.replaceAll('@gmail.com', '');
                      if (user.uid == 'admin') {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(user.name.length <= 8
                                  ? user.name
                                  : user.name.substring(0, 8)),
                              Text(email),
                              // IconButton(
                              //   onPressed: () => _deleteUser(user),
                              //   icon: Icon(Icons.delete),
                              // ),
                            ],
                          ),
                          const Divider(
                            height: 5,
                            thickness: 1,
                          ),
                        ],
                      );
                    },
                  );
                },
              )),
          ElevatedButton.icon(
              icon: Icon(CupertinoIcons.add),
              onPressed: () {
                _showDialog(context);
              },
              label: const Text('Add'))
        ],
      ),
    ));
  }
}
