import 'package:flutter/material.dart';

class TrendingProvider extends ChangeNotifier {
  List<String> trendingBookIds = [];

  // List<String> get trendingBookIds => _trendingBookIds;

  void setTrendingBookIds(List<String> bookIds) {
    trendingBookIds = bookIds;
    notifyListeners();
  }
}

