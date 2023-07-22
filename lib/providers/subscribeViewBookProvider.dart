import 'package:flutter/material.dart';

class SubscribeViewBookProvider extends ChangeNotifier{
  bool _isSubscribed=false;


  bool get isSubscribed => _isSubscribed;

  set isSubscribed(bool value) {
    _isSubscribed = value;
    notifyListeners();
  }
}
