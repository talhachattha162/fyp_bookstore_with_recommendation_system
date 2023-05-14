import 'package:flutter/material.dart';

class BottomNavigationBarState extends ChangeNotifier {
  bool isEnabled = true;

  void setEnabled(bool value) {
    isEnabled = value;
    notifyListeners();
  }
}
