import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  final List<NotificationItem> notifications = [
    NotificationItem(
      avatarUrl: 'https://picsum.photos/50/50',
      username: 'John Doe',
      message: 'liked your photo',
      time: DateTime.now().subtract(Duration(minutes: 15)),
    ),
    NotificationItem(
      avatarUrl: 'https://picsum.photos/50/50',
      username: 'Jane Doe',
      message: 'started following you',
      time: DateTime.now().subtract(Duration(hours: 2)),
    ),
    NotificationItem(
      avatarUrl: 'https://picsum.photos/50/50',
      username: 'Jack Smith',
      message: 'commented on your post',
      time: DateTime.now().subtract(Duration(days: 1)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            onTap: () {
              // Navigate to post or profile based on the notification type
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage:
                            NetworkImage(notifications[index].avatarUrl),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notifications[index].username,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              notifications[index].message,
                            ),
                            SizedBox(height: 4),
                            Text(
                              notifications[index].timeAgo,
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class NotificationItem {
  final String avatarUrl;
  final String username;
  final String message;
  final DateTime time;

  NotificationItem({
    required this.avatarUrl,
    required this.username,
    required this.message,
    required this.time,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
