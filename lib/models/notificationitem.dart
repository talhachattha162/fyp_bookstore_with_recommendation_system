import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  String? notificationMsg;
  String? forUserId;
  Timestamp? notificationDateTime;

  NotificationItem(
      this.notificationMsg, this.forUserId, this.notificationDateTime);

  String? getNotificationMsg() {
    return notificationMsg;
  }

  void setNotificationMsg(String? value) {
    notificationMsg = value;
  }

  String? getForUserId() {
    return forUserId;
  }

  void setForUserId(String? value) {
    forUserId = value;
  }

  Timestamp? getNotificationDateTime() {
    return notificationDateTime;
  }

  void setNotificationDateTime(Timestamp? value) {
    notificationDateTime = value;
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationMsg': notificationMsg,
      'forUserId': forUserId,
      'notificationDateTime': notificationDateTime,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      map['notificationMsg'],
      map['forUserId'],
      map['notificationDateTime'],
    );
  }

  factory NotificationItem.fromSnapshot(DocumentSnapshot snapshot) {
    return NotificationItem(
      snapshot['notificationMsg'],
      snapshot['forUserId'],
      snapshot['notificationDateTime'],
    );
  }
}
