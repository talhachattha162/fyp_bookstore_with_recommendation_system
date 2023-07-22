import 'package:flutter/material.dart';

class TimeLeftViewBookProvider extends ChangeNotifier{
  Duration _timeleft=Duration.zero;

  Duration get timeleft => _timeleft;

  set timeleft(Duration value) {
    _timeleft = value;
    notifyListeners();
  }
}
