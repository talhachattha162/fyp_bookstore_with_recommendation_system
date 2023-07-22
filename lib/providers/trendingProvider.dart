import 'package:flutter/material.dart';

class TrendingProvider extends ChangeNotifier {
  List<String> trendingBookIds = [];

  // List<String> get trendingBookIds => _trendingBookIds;
bool _isLoading=false;

  set isLoading(bool value) {
    _isLoading = value;
  }

  bool get isLoading => _isLoading;

  void setTrendingBookIds(List<String> bookIds) {
    trendingBookIds = bookIds;
    notifyListeners();
  }
}

