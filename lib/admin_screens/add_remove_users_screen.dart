import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
// import 'package:bookstore_recommendation_system_fyp/user_screens/login_screen.dart';
// import 'package:bookstore_recommendation_system_fyp/utils/navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

import '../models/user.dart';
// import '../providers/themenotifier.dart';
import '../utils/firebase_constants.dart';
// import '../utils/global_variables.dart';
// import 'dart:io';

class AddRemoveUser extends StatefulWidget {
  const AddRemoveUser({super.key});

  @override
  State<AddRemoveUser> createState() => _AddRemoveUserState();
}

class _AddRemoveUserState extends State<AddRemoveUser> {
  // List<Users> _users = [];
bool isLoading=false;
  @override
  void initState() {
    super.initState();
  }


  deletePaymentsForUserId(String userId) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collectionGroup('payments')
        .where('userId', isEqualTo: userId)
        .get();

    querySnapshot.docs.forEach((doc) {
      doc.reference.delete();
    });
  }

  deleteFavouritesForUserId(String userId) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection('favourities')
        .where('userid', isEqualTo: userId)
        .get();

    querySnapshot.docs.forEach((doc) {
      doc.reference.delete();
    });
  }

  deleteReviewsForUserId(String userId) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection('reviews')
        .where('uploadedByUserId', isEqualTo: userId)
        .get();

    querySnapshot.docs.forEach((doc) {
      doc.reference.delete();
    });
  }
  deleteNotificationsForUserId(String userId) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection('notifications')
        .where('forUserId', isEqualTo: userId)
        .get();

    querySnapshot.docs.forEach((doc) {
      doc.reference.delete();
    });
  }

  CollectionReference books = FirebaseFirestore.instance.collection('books');
  Future<void> deleteBookForuserid(String userID) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection('books')
        .where('userid', isEqualTo: userID)
        .get();


    querySnapshot.docs.forEach((doc) {
      doc.reference.delete();
    });// Delete
  }

  Future<void> deleteBooksAndRelatedData(String userId) async {
    try {
      // Get all books uploaded by the user
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
      await FirebaseFirestore.instance
          .collection('books')
          .where('userid', isEqualTo: userId)
          .get();

      // Delete each book and its related data
      for (QueryDocumentSnapshot<Map<String, dynamic>> bookSnapshot
      in querySnapshot.docs) {
        String bookId = bookSnapshot.id;

        // Delete payments for the book
        await deletePaymentsForBookId(bookId);

        // Delete favorites for the book
        await deleteFavoritesForBookId(bookId);

        // Delete reviews for the book
        await deleteReviewsForBookId(bookId);

        // Delete the book itself
        await deleteBookData(bookId);
      }

      // print('All books and related data deleted successfully.');
    } catch (e) {
      // print('Error deleting books and related data: $e');
    }
  }

  Future<void> deletePaymentsForBookId(String bookId) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collectionGroup('payments')
        .where('bookId', isEqualTo: bookId)
        .get();

    querySnapshot.docs.forEach((doc) {
      doc.reference.delete();
    });
  }

  Future<void> deleteFavoritesForBookId(String bookId) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection('favourities')
        .where('bookid', isEqualTo: bookId)
        .get();

    querySnapshot.docs.forEach((doc) {
      doc.reference.delete();
    });
  }

  Future<void> deleteReviewsForBookId(String bookId) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection('reviews')
        .where('bookId', isEqualTo: bookId)
        .get();

    querySnapshot.docs.forEach((doc) {
      doc.reference.delete();
    });
  }

  Future<void> deleteBookData(String bookId) {
    return FirebaseFirestore.instance.collection('books').doc(bookId).delete();
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
      await Future.delayed(const Duration(seconds: 2)); // Add a delay to ensure login is completed
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
    if(mounted){
      setState(() {
        isLoading=true;
      });
    }
    // Check if the user has any book collection
    final bookCollectionQuery = FirebaseFirestore.instance
        .collection('books')
        .where('userid', isEqualTo: users.uid);

    // final bookCollectionSnapshot = await bookCollectionQuery.get();

      // If the user hasn't uploaded any book collections, delete their account
      if (users.authenticationmethod == 'email') {

        // print(users.password);

        User? user;
        UserCredential userCredential = await auth.signInWithEmailAndPassword(
          email: users.email,
          password: users.password,
        );

        user = userCredential.user;
        // print();

        deleteBookForuserid(userCredential.user!.uid);
        deleteFavouritesForUserId(userCredential.user!.uid);
        deletePaymentsForUserId(userCredential.user!.uid);
        deleteReviewsForUserId(userCredential.user!.uid);
        deleteBooksAndRelatedData(userCredential.user!.uid);
        deleteNotificationsForUserId(userCredential.user!.uid);
        // await deleteCurrentUser(users.email, users.password);
        FirebaseFirestore.instance.collection('users').doc(users.uid).delete();
        await user!.delete();
        final snackBar = SnackBar(

          /// need to set following properties for best effect of awesome_snackbar_content
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,

          content: AwesomeSnackbarContent(
            title: 'Success!',
            message: "User Deleted successfully",

            /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
            contentType: ContentType.success,
          ),
        );

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);

        auth.signOut();

      }
      else{
        deleteBookForuserid(users.uid);
        deleteFavouritesForUserId(users.uid);
        deletePaymentsForUserId(users.uid);
        deleteReviewsForUserId(users.uid);
        deleteBooksAndRelatedData(users.uid);
        deleteNotificationsForUserId(users.uid);
        // await deleteCurrentUser(users.email, users.password);
        FirebaseFirestore.instance.collection('users').doc(users.uid).delete();
        final snackBar = SnackBar(

          /// need to set following properties for best effect of awesome_snackbar_content
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,

          content: AwesomeSnackbarContent(
            title: 'Success!',
            message: "User Deleted successfully",

            /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
            contentType: ContentType.success,
          ),
        );

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);


      }

    if(mounted){
      setState(() {
        isLoading=false;
      });
    }
    }


  void showConfirmationDialog(BuildContext context,user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Are you sure you want to delete this user?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            isLoading?const CircularProgressIndicator():TextButton(
              child: const Text('Delete'),
              onPressed: ()async {
               await _deleteUser(user);
               Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

// Define TextEditingController objects to control the text fields
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
// Show a dialog when the button is pressed
  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Account'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter Name';
                    }

                    return null;
                  },
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter Email';
                    }

                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter Password';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Create Account'),
              onPressed: () async {
        if (_formKey.currentState!.validate()) {
          String email = _emailController.text.trim();
          String password = _passwordController.text.trim();

          try {
            UserCredential userCredential = await FirebaseAuth.instance
                .createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
            Users u = Users(
                userCredential.user!.uid,
                _nameController.text,
                '',
                email,
                password,
                '',
                0,
                'email',
                0);
            // Add user to Firestore
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .set(u.toMap());
            final snackBar = SnackBar(

              /// need to set following properties for best effect of awesome_snackbar_content
              elevation: 0,
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,

              content: AwesomeSnackbarContent(
                title: 'Success!',
                message: "User Added successfully",

                /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                contentType: ContentType.success,
              ),
            );

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(snackBar);
            auth.signOut();
            // Navigate to the home screen or do something else
            // ...

            Navigator.of(context).pop();
          } catch (e) {
            // Handle error
            // ...
          }
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
    // final themeNotifier = Provider.of<ThemeNotifier>(context);
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
              const Text(
                'Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Gmail',
                style: const TextStyle(fontWeight: FontWeight.bold),
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
                    return const Center(child: const CircularProgressIndicator());
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
                              isLoading?Container(height:10,width:10,child:const CircularProgressIndicator()):IconButton(
                                onPressed: () => showConfirmationDialog(context,user),
                                icon: const Icon(Icons.delete),
                              ),
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
              icon: const Icon(CupertinoIcons.add),
              onPressed: () {
                _showDialog(context);
              },
              label: const Text('Add'))
        ],
      ),
    ));
  }
}
