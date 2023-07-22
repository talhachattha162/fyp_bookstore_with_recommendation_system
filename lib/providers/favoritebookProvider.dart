import 'package:flutter/material.dart';

class FavoriteViewBookProvider extends ChangeNotifier {
  bool _favourite =false;


  bool get favourite => _favourite;

  set favourite(bool value) {
    _favourite = value;
    notifyListeners();
  }

}