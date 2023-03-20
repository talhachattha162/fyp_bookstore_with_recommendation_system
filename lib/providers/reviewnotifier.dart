import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/review.dart';
import '../models/user.dart';

class ReviewProvider with ChangeNotifier {
  List<Review> _reviews = [];
  final List<Users> _users = [];
  List<Users> get users => _users;
  List<Review> get reviews => _reviews;

  Future<void> getReviews(String bookid) async {
    Stream<QuerySnapshot> stream =
        FirebaseFirestore.instance.collection('reviews').snapshots();

    stream.listen((QuerySnapshot querySnapshot) async {
      if (querySnapshot.docs.isEmpty) {
        return;
      }
      for (var doc in querySnapshot.docs) {
        if (bookid == doc['bookId']) {
          var review = Review(
              reviewId: doc['reviewId'],
              bookId: doc['bookId'],
              rating: doc['rating'],
              uploadedByUserId: doc['uploadedByUserId'],
              reviewtext: doc['reviewtext'],
              created_at: doc['created_at']);
          _reviews.add(review);
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(doc['uploadedByUserId'])
              .get();

          if (snapshot.exists) {
            _users.add(Users.fromMap(snapshot.data()!));
          }
        }
      }
      notifyListeners();
    });
  }

  void dispose() {
    _reviews.clear();
  }
}
