import 'package:bookstore_recommendation_system_fyp/models/book.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BookProvider with ChangeNotifier {
  Book? _book;
  Book? get book => _book;

  Future<void> getBook(String bookid) async {
    Stream<QuerySnapshot> stream =
        FirebaseFirestore.instance.collection('books').snapshots();

    await stream.listen((QuerySnapshot querySnapshot) async {
      print('query' + querySnapshot.docs.toString());
      if (querySnapshot.docs.isEmpty) {
        return;
      }
      for (var doc in querySnapshot.docs) {
        print('bookid' + doc['bookid']);
        if (bookid == doc['bookid']) {
          print('bookid1' + doc['bookid']);
          var book = Book(
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
          print('bookid2' + book.bookid);
          _book = book;

          print('bookid3' + _book!.bookid);
        }
      }
    }).asFuture();

    notifyListeners();
  }
}
