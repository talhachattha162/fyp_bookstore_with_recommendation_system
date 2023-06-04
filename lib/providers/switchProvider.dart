import 'package:flutter/material.dart';
class SwitchProvider extends ChangeNotifier {
  bool isSwitched = false;

  // bool get isSwitched => _isSwitched;

  void setSwitched(bool value) {
    isSwitched = value;
    notifyListeners();
  }
}
