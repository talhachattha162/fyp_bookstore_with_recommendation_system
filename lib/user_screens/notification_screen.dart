import 'package:bookstore_recommendation_system_fyp/models/notificationitem.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/user_main_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/navigation.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationItem> notifications = [];

  @override
  void initState() {
    super.initState();
    _getNotifications();
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
      setState(() {
        notifications = notifications1;
      });

      updateNotificationLength(notifications.length);
    } catch (e) {
      print('Error fetching notifications: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Notifications'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              navigateWithNoBack(context, const MainScreenUser());
            },
          )),
      body: notifications.isEmpty
          ? Center(
              child: Center(
                child: Text('No Notifications'),
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (BuildContext context, int index) {
                final notification = notifications[index];
                DateTime dateTime = notification.notificationDateTime!.toDate();
                String formattedDateTime =
                    '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
                print(formattedDateTime);
                return Column(
                  children: [
                    ListTile(
                      title: Text(notification.notificationMsg.toString()),
                      subtitle: Text(formattedDateTime),
                    ),
                    Divider()
                  ],
                );
              },
            ),
    );
  }
}
