import 'package:flutter/material.dart';

class BottomNavigationBarState with ChangeNotifier {
  int _selectedIndex = 0;
  bool _isEnabled = true;

  int getSelectedIndex() => _selectedIndex;
  bool isEnabled() => _isEnabled;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    notifyListeners();
  }
}

