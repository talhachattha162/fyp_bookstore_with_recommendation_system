import 'package:bookstore_recommendation_system_fyp/user_screens/user_main_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/view_book_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/internetavailabilitynotifier.dart';
import '../utils/navigation.dart';

class RentedBooks extends StatefulWidget {
  const RentedBooks({Key? key});

  @override
  State<RentedBooks> createState() => _RentedBooksState();
}

class _RentedBooksState extends State<RentedBooks> {
  late Query booksQuery;

  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Initialize the query to only show rented books
    booksQuery = FirebaseFirestore.instance
        .collection('books')
        .where('freeRentPaid', isEqualTo: 'rent');

    // Enable offline persistence and set cache size
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  DateTime currentBackPressTime = DateTime.now();

  Future<bool> onWillPop() async {
    final now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Press back again to exit')));
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context);
    double height = MediaQuery.of(context).size.height;
    return WillPopScope(
      onWillPop: onWillPop,
      child: SafeArea(
        child: Scaffold(
            appBar: AppBar(
                title: const Text('Rented Books'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    navigateWithNoBack(context, const MainScreenUser());
                  },
                )),
            body: SizedBox(
  width: double.infinity,
  height: height * 0.93,
  child: FutureBuilder<QuerySnapshot>(
    future: firestore
        .collection('payments')
        .where('freeRentPaid', isEqualTo: 'rent')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get(),
    builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Visibility(
          visible: true,
          child: Center(child: Text('No Rented books found')),
        );
      }
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            mainAxisExtent: 230),
        padding: const EdgeInsets.all(8.0),
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (BuildContext context, int index) {
          QueryDocumentSnapshot payments = snapshot.data!.docs[index];
          DateTime paymentCreationTime =
              payments.get('dateTimeCreated').toDate();
          int duration = payments.get('durationDays');
          DateTime expirationDate =
              paymentCreationTime.add(Duration(days: duration));
          Duration timeLeft = expirationDate.difference(DateTime.now());
          if (timeLeft.isNegative) {
            return Container();
          }
         return FutureBuilder<DocumentSnapshot>(
  future: firestore
      .collection('books')
      .doc(payments.get('bookId'))
      .get(),
  builder:
      (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    if (snapshot.hasData) {
      Map<String, dynamic>? bookData =
          snapshot.data!.data() as Map<String, dynamic>?;
      if (bookData != null) {
        return InkWell(
          onTap: () {
            navigateWithNoBack(
                context,
                ViewBookScreen(
                  book: Book.fromMap(bookData),
                ));
          },
          child: Card(
            elevation: 10,
            borderOnForeground: true,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                children: [
                  CachedNetworkImage(
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.fill,
                    imageUrl: bookData['coverPhotoFile'],
                    placeholder: (context, url) =>
                        Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        new Icon(Icons.error),
                  ),
                  SizedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              bookData['title'].length > 20
                                  ? bookData['title']
                                          .substring(0, 20) +
                                      '...'
                                  : bookData['title'],
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            "\$" + bookData['price'].toString(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }
    }
    return Container(); // default return value
  },
);

        },
      );
    },
  ),
)
),
      ),
    );
  }
}
