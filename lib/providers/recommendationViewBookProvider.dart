import 'package:flutter/material.dart';

class RecViewBookProvider extends ChangeNotifier{

List<dynamic> _recommendations = [];

List<dynamic> get recommendations => _recommendations;

set recommendations(List<dynamic> value) {
  _recommendations = value;
  notifyListeners();
}

}
