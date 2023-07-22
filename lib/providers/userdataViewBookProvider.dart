

import 'package:flutter/material.dart';

import '../models/user.dart';

class UserViewBookProvider extends ChangeNotifier{
  Users? _userData;

  Users? get userData => _userData;

  set userData(Users? value)  {
    _userData = value;
    notifyListeners();
  }
}
