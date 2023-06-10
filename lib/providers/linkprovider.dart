import 'package:flutter/material.dart';

class LinkProvider extends ChangeNotifier {
  String _link = '';
  String get link => _link;
  set link(String value) {
    _link = value;
    notifyListeners();
  }

}
