import 'package:flutter/material.dart';

class LinkProvider extends ChangeNotifier {
  String _link = 'http://talha1623.pythonanywhere.com/recommend?book_name=';
  String get link => _link;
  set link(String value) {
    _link = value;
    notifyListeners();
  }

}
