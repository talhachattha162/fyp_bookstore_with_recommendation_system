import 'package:flutter/material.dart';

  class LoginSignupProvider with ChangeNotifier {
 bool  _isLoading=false;


  bool _isGoogleLoading=false;
  bool _obscure=true;


 bool get isLoading => _isLoading;
 bool get isGoogleLoading => _isGoogleLoading;
 bool get obscure => _obscure;



 set isLoading(bool value) {
   _isLoading = value;
   notifyListeners();
 }

 set isGoogleLoading(bool value) {
    _isGoogleLoading = value;
    notifyListeners();
  }

 set obscure(bool value) {
    _obscure = value;
    notifyListeners();
  }
}
