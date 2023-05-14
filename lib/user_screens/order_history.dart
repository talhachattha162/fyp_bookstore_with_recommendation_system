import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/book.dart';
import '../providers/internetavailabilitynotifier.dart';
import '../providers/paymentprovider.dart';
import '../utils/InternetChecker.dart';
import '../utils/navigation.dart';
import 'user_main_screen.dart';

class OrderHistory extends StatefulWidget {
  const OrderHistory({super.key});

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
  List<Book> _books = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      Provider.of<PaymentProvider>(context, listen: false).clearPayments();
    });
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) async {
      final internetAvailabilityNotifier =
          Provider.of<InternetNotifier>(context, listen: false);
      try {
        final result = await InternetAddress.lookup('google.com');
        final result2 = await InternetAddress.lookup('facebook.com');
        final result3 = await InternetAddress.lookup('microsoft.com');
        if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) ||
            (result2.isNotEmpty && result2[0].rawAddress.isNotEmpty) ||
            (result3.isNotEmpty && result3[0].rawAddress.isNotEmpty)) {
          internetAvailabilityNotifier.setInternetAvailability(true);
        } else {}
      } on SocketException catch (_) {
        internetAvailabilityNotifier.setInternetAvailability(false);
      }
    });
    _loadBooks();
  }



  @override
  void dispose() {
    // print('talhaxyza2');
    timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('books').get();

    final List<Book> books =
        snapshot.docs.map((doc) => Book.fromSnapshot(doc)).toList();
    if (mounted) {
      setState(() {
        _books = books;
      });
    }
  }

  Book? searchBooksById(List<Book> books, String bookid) {
    Book? bookdata = null;
    for (Book book in books) {
      if (book.getBookid.toLowerCase().contains(bookid.toLowerCase())) {
        bookdata = book;
        break;
      }
    }
    return bookdata;
  }

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
    // final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context);
    double height = MediaQuery.of(context).size.height;
    final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context);
    return internetAvailabilityNotifier.getInternetAvailability() == false
        ? InternetChecker()
        : WillPopScope(
            onWillPop: () async {
              navigateWithNoBack(context, MainScreenUser());
              return false;
            },
            child: SafeArea(
              child: Scaffold(
                  appBar: AppBar(
                      title: const Text('Orders History'),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          navigateWithNoBack(context, const MainScreenUser());
                        },
                      )),
                  body: SizedBox(
                    width: double.infinity,
                    height: height * 0.93,
                    child: Consumer<PaymentProvider>(
                      builder: (context, provider, child) {

                        if (provider.payments.isEmpty) {
                          print(FirebaseAuth.instance.currentUser!.uid.toString()+'talhaxyz'+provider.payments.length.toString());
                          provider.fetchPayments(
                              FirebaseAuth.instance.currentUser!.uid);
                          return Center(child: Text('No orders found'));
                        } else {
                          return ListView.builder(
                              itemCount: provider.payments.length,
                              itemBuilder: (BuildContext context, int index) {
                                final payment = provider.payments[index];
                                Book? book =
                                    searchBooksById(_books, payment.bookId);
                                if (book != null) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        Wrap(
                                          children: [
                                            payment.freeRentPaid == 'rent'
                                                ? Text(
                                                    'On ${payment.formattedDate}, at ${payment.formattedTime}, a copy of the book ${book.title} was rented for \$${payment.pricePaid}.The book was rented for ${payment.durationDays} days',
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  )
                                                : Text(
                                                    'On ${payment.formattedDate}, at ${payment.formattedTime}, a copy of the book ${book.title} was purchased for \$${payment.pricePaid}.',
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  ),
                                          ],
                                        ),
                                        if (index <
                                            provider.payments.length - 1)
                                          Divider(),
                                      ],
                                    ),
                                  );
                                }
                              });
                        }
                      },
                    ),
                  )),
            ),
          );
  }
}
