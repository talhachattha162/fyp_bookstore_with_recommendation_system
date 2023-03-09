import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/book.dart';

class BooksProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _hasMoreData = true;

  List<Book> _books = [];

  List<Book> get books => _books;
  bool get isLoading => _isLoading;
  bool get hasMoreData => _hasMoreData;

  Future<void> fetchBooks(String category, {int limit = 8}) async {
    if (_isLoading || !_hasMoreData) {
      return;
    }

    _isLoading = true;

    Query query = _firestore
        .collection('books')
        .orderBy('title')
        .limit(limit)
        .where('isPermitted', isEqualTo: true);

    if (_books.isNotEmpty) {
      query = query.startAfter([_books.last.title]);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      _hasMoreData = false;
    } else {
      _books.addAll(snapshot.docs.map((doc) {
        return Book(
            doc['bookid'],
            doc['title'],
            doc['description'],
            doc['author'],
            doc['tag1'],
            doc['tag2'],
            doc['tag3'],
            doc['price'],
            doc['coverPhotoFile'],
            doc['bookFile'],
            doc['copyrightPhotoFile'],
            doc['selectedcategory'],
            doc['audiobook'],
            doc['freeRentPaid'],
            doc['userliked'],
            doc['userid'],
            doc['isPermitted']);
      }).toList());
    }

    _isLoading = false;
    notifyListeners();
  }
}
