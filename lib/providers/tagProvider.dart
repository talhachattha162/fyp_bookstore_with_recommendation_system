import 'package:flutter/material.dart';

class TagProvider with ChangeNotifier {
  int tag = 0;

  void setTag(int newTag) {
    tag = newTag;
    notifyListeners();
  }
}
