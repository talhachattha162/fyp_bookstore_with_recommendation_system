import 'package:flutter/material.dart';

class FileNamesProvider extends ChangeNotifier {
  String _filename1 = "<2 mb image allowed";
  String _filename2 = "<2 mb pdf allowed";
  String _filename3 = "<2 mb image allowed";

  String get filename1 => _filename1;

  set filename1(String value) {
    _filename1 = value;
    notifyListeners();
  }

  String get filename2 => _filename2;

  set filename2(String value) {
    _filename2 = value;
    notifyListeners();
  }

  String get filename3 => _filename3;

  set filename3(String value) {
    _filename3 = value;
    notifyListeners();
  }
}
