import 'package:flutter/material.dart';

class LoadingProvider with ChangeNotifier {
  bool isLoading = false;

  void setLoading(bool newValue) {
    isLoading = newValue;
    notifyListeners();
  }
}
