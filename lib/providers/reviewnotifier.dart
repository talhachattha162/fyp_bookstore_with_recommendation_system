// // import 'dart:async';

// // import 'package:bookstore_recommendation_system_fyp/models/user.dart';
// // import 'package:bookstore_recommendation_system_fyp/utils/firebase_constants.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:flutter/material.dart';

// // import '../models/review.dart';

// // class ReviewsProvider extends ChangeNotifier {
// //   final List<Review> _reviews = [];
// //   final List<Users> _users = [];
// //   List<Users> get users => _users;

// //   List<Review> get reviews => _reviews;
// //   bool _hasMoreData = true;
// //   bool _isLoading = false;
// //   DocumentSnapshot? _lastDocument;
// //   bool get hasMoreData => _hasMoreData;
// //   bool get isLoading => _isLoading;

// //   Future<void> fetchReviews(String bookid) async {
// //     if (_isLoading) {
// //       return;
// //     }
// //     _isLoading = true;

// //     Query query = FirebaseFirestore.instance.collection('reviews').limit(5);

// //     if (_lastDocument != null) {
// //       query = query.startAfterDocument(_lastDocument!);
// //     }

// //     StreamSubscription<QuerySnapshot> subscription;
// //     subscription = query.where('bookId', isEqualTo: bookid).snapshots().listen(
// //         (querySnapshot) {
// //       if (querySnapshot.docs.length < 5) {
// //         _hasMoreData = false;
// //       }

// //       _lastDocument =
// //           querySnapshot.docs.isEmpty ? null : querySnapshot.docs.last;

// //       querySnapshot.docs.forEach((doc) async {
// //         var review = Review(
// //           reviewId: doc['reviewId'],
// //           bookId: doc['bookId'],
// //           rating: doc['rating'],
// //           uploadedByUserId: doc['uploadedByUserId'],
// //           reviewtext: doc['reviewtext'],
// //         );
// //         _reviews.add(review);

// //         final snapshot = await FirebaseFirestore.instance
// //             .collection('users')
// //             .doc(doc['uploadedByUserId'])
// //             .get();
// //         if (snapshot.exists) {
// //           _users.add(Users.fromMap(snapshot.data()!));
// //         }

// //         notifyListeners();
// //       });
// //     }, onError: (error) {
// //       print('Error fetching reviews: $error');
// //     });

// //     await subscription.asFuture();
// //     _isLoading = false;
// //     notifyListeners();
// //   }
// //  @override
// //   void dispose() {
// //     _subscription?.cancel();
// //     super.dispose();
// //   }
// //   // Future<void> fetchReviews() async {
// //   //   QuerySnapshot snapshot =
// //   //       await firestoreInstance.collection('reviews').get();

// //   //   List<Review> reviews = snapshot.docs.map((doc) {
// //   //     return Review(
// //   //         reviewId: doc.get('reviewId'),
// //   //         bookId: doc.get('bookId'),
// //   //         rating: doc.get('rating'),
// //   //         uploadedByUserId: doc.get('uploadedByUserId'),
// //   //         reviewtext: doc.get('reviewtext'));
// //   //   }).toList();

// //   //   notifyListeners();
// //   // }

// //   // Future<void> fetchReviews(String bookid) async {
// //   //   if (_isLoading || !_hasMoreData) {
// //   //     return;
// //   //   }
// //   //   _isLoading = true;

// //   //   QuerySnapshot querySnapshot;
// //   //   if (_lastDocument == null) {
// //   //     querySnapshot = await FirebaseFirestore.instance
// //   //         .collection('reviews')
// //   //         .limit(5)
// //   //         .get();
// //   //   } else {
// //   //     querySnapshot = await FirebaseFirestore.instance
// //   //         .collection('reviews')
// //   //         .startAfterDocument(_lastDocument!)
// //   //         .limit(5)
// //   //         .get();
// //   //   }

// //   //   if (querySnapshot.docs.length < 5) {
// //   //     _hasMoreData = false;
// //   //   }
// //   //   if (querySnapshot.docs.length == 0) {
// //   //     _isLoading = false;
// //   //     return;
// //   //   }
// //   //   _lastDocument = querySnapshot.docs.last;

// //   //   for (var doc in querySnapshot.docs) {

// //   //       print('doc:' + doc['bookId']);
// //   //     if (bookid == doc['bookId']) {
// //   //       var review = Review(
// //   //           reviewId: doc['reviewId'],
// //   //           bookId: doc['bookId'],
// //   //           rating: doc['rating'],
// //   //           uploadedByUserId: doc['uploadedByUserId'],
// //   //           reviewtext: doc['reviewtext']);
// //   //       _reviews.add(review);
// //   //       print('length:' + _reviews.length.toString());
// //   //       final snapshot = await FirebaseFirestore.instance
// //   //           .collection('users')
// //   //           .doc(doc['uploadedByUserId'])
// //   //           .get();
// //   //       if (snapshot.exists) {
// //   //         _users.add(Users.fromMap(snapshot.data()!));
// //   //       }
// //   //       if (_users.isEmpty) {
// //   //         return;
// //   //       }
// //   //     }
// //   //   }

// //   //   _isLoading = false;
// //   //   notifyListeners();
// //   // }
// // }

// import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';

// import '../models/review.dart';
// import '../models/user.dart';

// class ReviewsProvider extends ChangeNotifier {
//   final List<Review> _reviews = [];
//   final List<Users> _users = [];
//   List<Users> get users => _users;

//   List<Review> get reviews => _reviews;
//   bool _hasMoreData = true;
//   bool _isLoading = false;
//   DocumentSnapshot? _lastDocument;

//   bool get hasMoreData => _hasMoreData;
//   bool get isLoading => _isLoading;

//   StreamSubscription<QuerySnapshot>? _subscription;

//   void fetchReviews(String bookId) {
//     if (_isLoading || !_hasMoreData) {
//       return;
//     }
//     _isLoading = true;

//     Query query;
//     if (_lastDocument == null) {
//       query = FirebaseFirestore.instance
//           .collection('reviews')
//           .limit(5);
//     } else {
//       query = FirebaseFirestore.instance
//           .collection('reviews')
//           .startAfterDocument(_lastDocument!)
//           .limit(5);
//     }

//     _subscription = query.snapshots().listen((querySnapshot) async {
//       _isLoading = false;
//       if (querySnapshot.docs.length < 5) {
//         _hasMoreData = false;
//       }
//       if (querySnapshot.docs.length == 0) {
//         return;
//       }
//       _lastDocument = querySnapshot.docs.last;

//       for (var doc in querySnapshot.docs) {
//         if (bookId == doc['bookId']) {
//           var review = Review(
//             reviewId: doc['reviewId'],
//             bookId: doc['bookId'],
//             rating: doc['rating'],
//             uploadedByUserId: doc['uploadedByUserId'],
//             reviewtext: doc['reviewtext'],
//           );
//           _reviews.add(review);
//           final snapshot = await FirebaseFirestore.instance
//               .collection('users')
//               .doc(doc['uploadedByUserId'])
//               .get();
//           if (snapshot.exists) {
//             _users.add(Users.fromMap(snapshot.data()!));
//           }
//         }
//       }

//       notifyListeners();
//     });
//   }

//   @override
//   void dispose() {
//     _subscription?.cancel();
//     super.dispose();
//   }
// }

//consider this code helpful:
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

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
      print('query' + querySnapshot.docs.toString());
      for (var doc in querySnapshot.docs) {
        if (bookid == doc['bookId']) {
          var review = Review(
            reviewId: doc['reviewId'],
            bookId: doc['bookId'],
            rating: doc['rating'],
            uploadedByUserId: doc['uploadedByUserId'],
            reviewtext: doc['reviewtext'],
          );
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
