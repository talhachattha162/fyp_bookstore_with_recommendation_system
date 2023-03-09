import 'package:flutter/material.dart';

class InternetNotifier with ChangeNotifier {
  bool _isConnected;

  InternetNotifier(this._isConnected);

  getInternetAvailability() => _isConnected;

  setInternetAvailability(bool isConnected) {
    _isConnected = isConnected;
    notifyListeners();
  }
}
