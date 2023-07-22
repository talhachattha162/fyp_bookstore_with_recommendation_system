import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthState with ChangeNotifier {
  int? _user;
  int? get user => _user;
  set user(int? newUser) {
    _user = newUser;
    notifyListeners();
  }
}