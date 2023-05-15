import 'dart:async';
import 'dart:io';

import 'package:bookstore_recommendation_system_fyp/utils/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Widgets/text_field.dart';
import '../models/user.dart';
import '../providers/internetavailabilitynotifier.dart';
import '../utils/InternetChecker.dart';
import '../utils/navigation.dart';
import '../utils/snackbar.dart';
import 'user_main_screen.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  RegExp name_valid = RegExp(r'^[a-zA-Z ]+$');
  RegExp pass_valid = RegExp(r"(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*\W)");
  RegExp age_valid = RegExp(r'^\d+$');
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  File? file;
  bool _isLoading = false;
  Timer? timer;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final DocumentReference documentReference = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid);

  Future<void> loadData() async {
    final DocumentSnapshot documentSnapshot = await documentReference.get();

    if (documentSnapshot.exists) {
      final data = documentSnapshot.data() as Map<String, dynamic>;
      Users user1 = Users.fromMap(data);
      final String name = user1.getName();
      final String age = user1.getAge();
      final photo = user1.getPhoto();
      if (mounted) {
        setState(() {
          photoURL = photo;
          _nameController.text = name;
          _ageController.text = age;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
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
    // getImage();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String photoURL = '';
  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
    );
    if (pickedFile != null) {
      // var compressedFile = await FlutterImageCompress.compressWithFile(pickedFile.path,quality: 50, );
      final file = File(pickedFile.path);
      return file;
    } else {
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

    return WillPopScope(
      onWillPop:  () async {
        navigateWithNoBack(context, MainScreenUser());
        return false;
      },
      child: SafeArea(
        child: internetAvailabilityNotifier.getInternetAvailability() == false
            ? InternetChecker()
            : Scaffold(
                appBar: AppBar(
                    title: const Text('Update Profile'),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        navigateWithNoBack(context, const MainScreenUser());
                      },
                    )),
                resizeToAvoidBottomInset: false,
                body: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Stack(
                      children: [
                        CircleAvatar(
                          maxRadius: 60,
                          backgroundImage:
                              photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
                          backgroundColor: Colors.green,
                        ),
                        Positioned(
                          bottom: -10,
                          left: 80,
                          child: IconButton(
                            onPressed: () async {
                              File? fileans = await pickImage();
                              if (fileans == null) {
                                flutterToast('plz pick image again');
                              } else {
                                file = fileans;
                              }
                            },
                            icon: Icon(Icons.add_a_photo),
                          ),
                        )
                      ],
                    ),
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
                          const SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 4.0),
                            child: TextInputField(
                              hintText: 'Enter Age',
                              suffixIcon: Text(''),
                              textInputType: TextInputType.number,
                              textEditingController: _ageController,
                              isPassword: false,
                              validator: (value) {
                                if (!age_valid.hasMatch(value)) {
                                  return 'Enter valid age';
                                }
                                if (value.length >= 3) {
                                  return 'Enter valid age';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(
                            height: 20.0,
                          ),
                          _isLoading == true
                              ? CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      if (mounted) {
                                        setState(() {
                                          _isLoading = true;
                                        });
                                      }
                                      final userId =
                                          FirebaseAuth.instance.currentUser!.uid;
                                      if (file != null) {
                                        Reference storageRef = FirebaseStorage
                                            .instance
                                            .ref()
                                            .child('users/$userId');
                                        final TaskSnapshot snapshot =
                                            await storageRef.putFile(file!);
                                        final downloadUrl =
                                            await snapshot.ref.getDownloadURL();
                                        FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(userId)
                                            .update({
                                          'name': _nameController.text,
                                          'age': _ageController.text,
                                          'photo': downloadUrl,
                                        }).then((value) {
                                          showSnackBar(context,'Updated');
                                        });
                                      } else {
                                        if (photoURL.isEmpty) {
                                          flutterToast('plz upload image');
                                        } else {
                                          FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(userId)
                                              .update({
                                            'name': _nameController.text,
                                            'age': _ageController.text,
                                            'photo': photoURL,
                                          }).then((value) {
                                            flutterToast('Updated');
                                          });
                                        }
                                      }

                                      loadData();
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
                                      child: Text('Update Profile')),
                                ),
                        ],
                      ),
                    ),
                  ]),
                )),
      ),
    );
  }
}
