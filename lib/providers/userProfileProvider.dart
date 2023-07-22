import 'package:flutter/material.dart';
class UserProfileProvider extends ChangeNotifier {
  String name = '';
  String photoUrl = '';
  String balance = '';


  void updateUserProfile(String name1, String photoUrl1, String balance1) {
    name = name1;
    photoUrl = photoUrl1;
    balance = balance1;
    notifyListeners();
  }
}
