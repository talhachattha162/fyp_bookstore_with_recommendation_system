import 'package:flutter/material.dart';

class FreeRentPaidProvider extends ChangeNotifier {
  String freeRentPaid = 'free';
  bool isvisible = false;

  void updateFreeRentPaid(String value,bool val) {
    freeRentPaid = value;
    isvisible = val;
    notifyListeners();
  }

  // bool get isVisible => _isVisible;
}
