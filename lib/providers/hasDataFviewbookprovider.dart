
import 'package:flutter/material.dart';

class HasDataBookProvider extends ChangeNotifier{

  bool _hasDataf=false;


  bool get hasDataf => _hasDataf;

  set hasDataf(bool value) {
    _hasDataf = value;
    notifyListeners();
  }

}
