import 'package:flutter/material.dart';

import '../models/book.dart';

class BookListProvider with ChangeNotifier {
  List<Book> books = [];

  void addBooks(List<Book> bookList) {
    books.addAll(bookList);
    notifyListeners();
  }


}
