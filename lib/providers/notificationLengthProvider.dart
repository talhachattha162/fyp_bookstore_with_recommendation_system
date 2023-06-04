import 'package:flutter/material.dart';

class NotificationLengthProvider with ChangeNotifier {
  int notificationLength = 0;

  void setNotificationLength(int length) {
    notificationLength = length;
    notifyListeners();
  }
}
