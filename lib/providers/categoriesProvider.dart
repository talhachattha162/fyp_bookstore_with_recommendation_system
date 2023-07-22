import 'package:flutter/material.dart';

class CategoryProvider with ChangeNotifier {
  List<String> categories = [];

  void addCategories(List<String> categoryList) {
    categories.addAll(categoryList);
    notifyListeners();
  }
  void clearCategories() {
    categories.clear();
    notifyListeners();
  }

}
