import 'package:flutter/material.dart';

class SelectedCategoryProvider extends ChangeNotifier {
  String selectedCategory='';

  // Category get selectedCategory => _selectedCategory;

   setSelectedCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }
}