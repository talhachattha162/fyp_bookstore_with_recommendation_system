import 'dart:async';
import 'dart:io';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bookstore_recommendation_system_fyp/models/notificationitem.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/user_main_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/internetavailabilitynotifier.dart';
import '../utils/InternetChecker.dart';
import '../utils/navigation.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationItem> notifications = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(Duration(seconds: 1), (Timer t) async {
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
    _getNotifications();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _getNotifications() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('forUserId', isEqualTo: userId)
          .orderBy('notificationDateTime', descending: true)
          .get();
      final docs = querySnapshot.docs;
      final notifications1 =
          docs.map((doc) => NotificationItem.fromSnapshot(doc)).toList();
      if (mounted) {
        setState(() {
          notifications = notifications1;
        });
      }

      updateNotificationLength(notifications.length);
    } catch (e) {
      final snackBar = SnackBar(
        /// need to set following properties for best effect of awesome_snackbar_content
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,

        content: AwesomeSnackbarContent(
          title: 'Error!',
          message:
          'Error fetching: ${e}',

          /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
          contentType: ContentType.failure,
        ),
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
      // print('Error fetching notifications: $e');
    }
  }

  updateNotificationLength(len) {
    // Get a reference to the document to update
    final DocumentReference documentReference = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid);

// Update the attribute
    documentReference
        .update({'notifications': len})
        .then((value) => print("notification updated successfully!"))
        .catchError((error) => print("Failed to update notification: $error"));
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
    return
      // internetAvailabilityNotifier.getInternetAvailability() == false
      //   ? const InternetChecker()
      //   :
      WillPopScope(
            onWillPop: () async {
              navigateWithNoBack(context, const MainScreenUser());
              return false;
            },
            child: Scaffold(
              appBar: AppBar(
                  title: const Text('Notifications'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      navigateWithNoBack(context, const MainScreenUser());
                    },
                  )),
              body: notifications.isEmpty
                  ? const Center(
                      child: Center(
                        child: Text('No Notifications'),
                      ),
                    )
                  : ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (BuildContext context, int index) {
                        final notification = notifications[index];
                        DateTime dateTime =
                            notification.notificationDateTime!.toDate();
                        String formattedDateTime =
                            '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
                        // print(formattedDateTime);
                        return Column(
                          children: [
                            ListTile(
                              title:
                                  Text(notification.notificationMsg.toString()),
                              subtitle: Text(formattedDateTime),
                            ),
                            const Divider()
                          ],
                        );
                      },
                    ),
            ),
          );
  }
}
