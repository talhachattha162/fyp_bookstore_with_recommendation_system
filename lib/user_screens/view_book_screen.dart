import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:bookstore_recommendation_system_fyp/user_screens/book_pdf_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/listen_book_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/user_main_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/view_all_reviews_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/write_a_review_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/navigation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/payment.dart';
import '../providers/bookprovider.dart';
import '../providers/internetavailabilitynotifier.dart';
import '../providers/reviewnotifier.dart';
import '../providers/themenotifier.dart';
import '../utils/InternetChecker.dart';
import '../utils/firebase_constants.dart';
import '../utils/fluttertoast.dart';
import '../utils/global_variables.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/razorpay_response.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewBookScreen extends StatefulWidget {
  Book book;
  ViewBookScreen({super.key, required this.book});

  @override
  State<ViewBookScreen> createState() => _ViewBookScreenState();
}

class _ViewBookScreenState extends State<ViewBookScreen> {
//used from here
//https://www.simplifiedcoding.net/razorpay-integration-flutter/
//UPI->success@razorpay
  bool favourite = false;
  Razorpay? _razorpay;
  Timer? timer;
  var bookpath;
  String nobooksmsg = '';
  Duration _timeLeft = Duration.zero;

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

  Future<bool> isBookFavorited() async {
    final userid = FirebaseAuth.instance.currentUser!.uid;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('favourities')
        .where('bookid', isEqualTo: widget.book.bookid)
        .where('userid', isEqualTo: userid)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  storeFile() async {
    try {
      // Download PDF file from URL
      Dio dio = Dio();
      Response response = await dio.get(widget.book.bookFile,
          options: Options(responseType: ResponseType.bytes));
      List<int> pdfData = List<int>.from(response.data);

      // Encrypt PDF file
      final key = encrypt.Key.fromLength(32);
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      encrypt.Encrypted encryptedPdf = encrypter.encryptBytes(pdfData, iv: iv);

      // Store encrypted PDF file in folder
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String encryptedPath = '${appDocDir.path}/encrypted';
      Directory(encryptedPath).createSync(recursive: true);
      File encryptedFile =
          File('$encryptedPath/' + widget.book.bookid + '.pdf');
      await encryptedFile.writeAsBytes(encryptedPdf.bytes);
      // flutterToast(encryptedFile.path);
      return encryptedFile.path;
    } catch (e) {
      flutterToast(e.toString());
    }
  }

  checkFavourities() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    final userid = FirebaseAuth.instance.currentUser!.uid;
    Query query = firestore
        .collection('favourities')
        .where('bookid', isEqualTo: widget.book.bookid)
        .where('userid', isEqualTo: userid);
    QuerySnapshot querySnapshot = await query.get();
    if (querySnapshot.docs.isNotEmpty) {
      if (mounted) {
        setState(() {
          favourite = true;
        });
      }
    } else {}
  }

  bool hasDataf = false;
  @override
  void initState() {
    _getRecommendations(widget.book.title);
    _razorpay = Razorpay();
    _razorpay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay?.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay?.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    super.initState();
    _paymentsStreamSubscription = paymentsStream().listen((hasData) {
      if (hasData) {
        setState(() {
          hasDataf = true;
        });
      }
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
    checkFavourities();
    bookpath = storeFile();
    // _checkIfBookIsFavorited();
  }

  Future<void> _checkIfBookIsFavorited() async {
    final isFavorited = await isBookFavorited();
    setState(() {
      favourite = isFavorited;
    });
  }

  StreamSubscription<bool>? _paymentsStreamSubscription;

  List<dynamic> _recommendations = [];

  Future<void> _getRecommendations(String bookname) async {
    final response = await http.get(Uri.parse(
        'http://talha1623.pythonanywhere.com/recommend?book_name=$bookname'));
    if (response.statusCode == 200) {
      if (response.body is List) {
      } else if (response.body is String) {
        nobooksmsg = response.body;
      }
      if (mounted) {
        setState(() {
          _recommendations = jsonDecode(response.body);
        });
      }
    } else {
      flutterToast('Request failed with status: ${response.statusCode}.');
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _paymentsStreamSubscription!.cancel();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    CollectionReference bookCollection =
        firestoreInstance.collection("payments");
    String paymentid = bookCollection.doc().id;
    Payment payment = Payment(
        FirebaseAuth.instance.currentUser!.uid,
        widget.book.bookid,
        widget.book.freeRentPaid,
        widget.book.price,
        DateTime.now());
    await bookCollection
        .doc(paymentid)
        .set(payment.toMap())
        .then((value) async {})
        .onError((error, stackTrace) async {
      Fluttertoast.showToast(msg: 'Error:' + error.toString());
    }).then((value) {
      Fluttertoast.showToast(msg: " Payment Successful");
    });

    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(widget.book.userid);

// Retrieve the user's data from Firestore
    userRef.get().then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        // Get the user's current data
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;

        // Update the user's attribute
        data['balance'] = data['balance'] + widget.book.price;

        // Update the user's data in Firestore
        userRef.update(data).then((value) {
          print('User attribute updated successfully!');
        }).catchError((error) {
          print('Failed to update user attribute: $error');
        });
      } else {
        print('User does not exist in Firestore');
      }
    }).catchError((error) {
      print('Failed to retrieve user data from Firestore: $error');
    });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(msg: "Payment failed");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(msg: "Payment Successful ");
  }

  Future<dynamic> createOrder() async {
    var mapHeader = <String, String>{};
    mapHeader['Authorization'] =
        "Basic cnpwX3Rlc3RfU2RHQmFoV3RsS1dNd2I6Mlh2WElOSDlMcG9xTHdyU3F5cDFzam5y";
    mapHeader['Accept'] = "application/json";
    mapHeader['Content-Type'] = "application/x-www-form-urlencoded";
    var map = <String, String>{};
    setState(() {
      map['amount'] = '2000';
    });
    map['currency'] = "USD";
    map['receipt'] = "receipt1";
    var response = await http.post(Uri.https("api.razorpay.com", "/v1/orders"),
        headers: mapHeader, body: map);
    if (response.statusCode == 200) {
      RazorpayOrderResponse data =
          RazorpayOrderResponse.fromJson(json.decode(response.body));
      openCheckout(data);
    } else {
      Fluttertoast.showToast(msg: 'error:${response.reasonPhrase}');
    }
  }

  void openCheckout(RazorpayOrderResponse data) async {
    var options = {
      'key': 'rzp_test_NNbwJ9tmM0fbxj',
      'amount': 20000,
      'name': 'Shaiq',
      'description': 'Payment',
      'prefill': {'contact': '8888888888', 'email': 'test@razorpay.com'},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay?.open(options);
    } catch (e) {
      flutterToast('Error: $e');
    }
  }

  void _settingModalBottomSheet(context, freeRentPaid) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    freeRentPaid == "rent"
                        ? Text(
                            'Book Will be Rented for 30 days',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: themeNotifier.getTheme() ==
                                        ThemeData.dark(useMaterial3: true)
                                            .copyWith(
                                          colorScheme: ColorScheme.dark()
                                              .copyWith(
                                                  primary: darkprimarycolor),
                                        )
                                    ? darkprimarycolor
                                    : primarycolor),
                          )
                        : Container(),
                    const Text(
                      'Pay with Razor Payment',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Divider(thickness: 30),
                    ElevatedButton(
                      onPressed: () {
                        createOrder();
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 95.0, vertical: 9.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text('Pay'),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          );
        });
  }

  // static Future<File> _storeFile(String url, List<int> bytes) async {
  //   final filename = basename(url);
  //   final dir = await getApplicationDocumentsDirectory();

  //   final file = File('${dir.path}/$filename');
  //   await file.writeAsBytes(bytes, flush: true);
  //   return file;
  // }

  // static Future<File> loadFirebase(String url) async {
  //   try {
  //     final refPDF = FirebaseStorage.instance.ref().child(url);
  //     final bytes = await refPDF.getData();

  //     return _storeFile(url, bytes);
  //   } catch (e) {
  //     return null;
  //   }
  // }

  Stream<bool> paymentsStream() async* {
    while (true) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('bookId', isEqualTo: widget.book.bookid)
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();
      bool hasData = snapshot.docs.isNotEmpty;
      // print('hasData' + hasData.toString());
      yield hasData;
      await Future.delayed(
          Duration(seconds: 1)); // Wait for 1 second before checking again
    }
  }

  @override
  Widget build(BuildContext context) {
    final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    print('recommendation2' + _recommendations.toString());
    // print(hasDataf);
    return WillPopScope(
      onWillPop: onWillPop,
      child: SafeArea(
        child: internetAvailabilityNotifier.getInternetAvailability() == false
            ? InternetChecker()
            : MultiProvider(
                providers: [
                  ChangeNotifierProvider(
                    create: (_) =>
                        ReviewProvider()..getReviews(widget.book.bookid),
                  ),
                  ChangeNotifierProvider(
                    create: (_) => BookProvider()..getBook(widget.book.bookid),
                  )
                ],
                child: Scaffold(
                    appBar: AppBar(
                        title: const Text('Book Details'),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            navigateWithNoBack(context, MainScreenUser());
                          },
                        )),
                    body: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                          ),
                          SizedBox(
                            height: height * 0.56,
                            width: width * 0.8,
                            child: ClipRect(
                              child: Align(
                                alignment: Alignment.center,
                                // widthFactor: 0.7,
                                // heightFactor: 0.6,
                                child: CachedNetworkImage(
                                  imageUrl: widget.book.coverPhotoFile,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              //  IconButton(
                              //     onPressed: null, icon: Icon(Icons.share)),
                              IconButton(
                                  onPressed: hasDataf == true ||
                                          widget.book.freeRentPaid == 'free' || widget.book.userid ==
                                      FirebaseAuth.instance.currentUser!.uid
                                      ? () {
                                          navigateWithNoBack(
                                              context,
                                              WriteReviewScreen(
                                                book: widget.book,
                                              ));
                                        }
                                      : null,
                                  icon: const Icon(Icons.comment)),
                              IconButton(
                                  onPressed: () async {
                                    final CollectionReference favouritiesRef =
                                        FirebaseFirestore.instance
                                            .collection('favourities');
                                    final QuerySnapshot querySnapshot =
                                        await favouritiesRef
                                            .where('bookid',
                                                isEqualTo: widget.book.bookid)
                                            .get();
                                    setState(() {
                                      if (favourite == false) {
                                        favouritiesRef.add({
                                          'bookid': widget.book.bookid,
                                          'userid': FirebaseAuth
                                              .instance.currentUser!.uid,
                                        }).then((value) {
                                          print('favourities added');
                                          setState(() {
                                            favourite = true;
                                          });
                                        }).catchError((error) => print(
                                            'Failed to add favourities: $error'));
                                      } else {
                                        querySnapshot.docs.forEach((doc) {
                                          doc.reference.delete().then((value) {
                                            print('favourities deleted');
                                            setState(() {
                                              favourite = false;
                                            });
                                          }).catchError((error) => print(
                                              'Failed to delete favourities: $error'));
                                        });
                                      }
                                    });
                                  },
                                  icon: Icon(
                                    favourite == true
                                        ? Icons.favorite_sharp
                                        : Icons.favorite_border,
                                    color: favourite == true
                                        ? Colors.amber
                                        : Colors.grey,
                                  )),
                              //  IconButton(
                              //     onPressed: null, icon: Icon(Icons.download))
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          const Divider(),
                          const SizedBox(
                            height: 10,
                          ),
                          Consumer<BookProvider>(
                              builder: (context, provider, child) {
                            Book? book = provider.book;
                            if (book == null) {
                              return Container(
                                child: (Text('Loading...')),
                              );
                            } else {
                              if (book.freeRentPaid == "paid" &&
                                  book.userid !=
                                      FirebaseAuth.instance.currentUser!.uid) {
                                return StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('payments')
                                      .where('bookId',
                                          isEqualTo: widget.book.bookid)
                                      .where('userId',
                                          isEqualTo: FirebaseAuth
                                              .instance.currentUser!.uid)
                                      .snapshots(),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<QuerySnapshot> snapshot) {
                                    if (snapshot.data != null) {
                                      if (snapshot.data!.docs.isEmpty) {
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                _settingModalBottomSheet(
                                                    context, book.freeRentPaid);
                                              },
                                              icon: Icon(Icons.lock),
                                              label: Text('Buy'),
                                            ),
                                          ],
                                        );
                                      }
                                    }
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            flutterToast('Loading...');
                                            navigateWithNoBack(
                                                context,
                                                ListenBookScreen(
                                                  book: widget.book,
                                                  bookpath: bookpath,
                                                ));
                                          },
                                          icon: Icon(Icons.headphones),
                                          label: Text('Listen'),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            navigateWithNoBack(
                                                context,
                                                BookPdfScreen(
                                                  book: widget.book,
                                                  bookpath: bookpath,
                                                ));
                                          },
                                          icon: Icon(Icons.book),
                                          label: Text('Read'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }

                              if (book.freeRentPaid == "rent" &&
                                  book.userid !=
                                      FirebaseAuth.instance.currentUser!.uid) {
                                return StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('payments')
                                      .where('bookId',
                                          isEqualTo: widget.book.bookid)
                                      .where('userId',
                                          isEqualTo: FirebaseAuth
                                              .instance.currentUser!.uid)
                                      .snapshots(),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<QuerySnapshot> snapshot) {
                                    if (snapshot.data != null) {
                                      Timestamp? paymentCreationTime;
                                      Duration? difference = null;
                                      if (snapshot.data!.docs.isNotEmpty) {
                                        paymentCreationTime = snapshot.data!
                                            .docs.first['dateTimeCreated'];
                                        DateTime expirationDate =
                                            paymentCreationTime!
                                                .toDate()
                                                .add(Duration(days: 30));
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          setState(() {
                                            _timeLeft = expirationDate
                                                .difference(DateTime.now());
                                          });
                                        });
                                      }

                                      if (snapshot.data!.docs.length != 0) {
                                        if (difference != null) {
                                          if (difference.inDays >= 30) {
                                            final docsToDelete =
                                                snapshot.data!.docs;
                                            for (final doc in docsToDelete) {
                                              doc.reference.delete();
                                            }
                                          }
                                        }
                                        return Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    flutterToast('Loading...');
                                                    navigateWithNoBack(
                                                        context,
                                                        ListenBookScreen(
                                                          book: widget.book,
                                                          bookpath: bookpath,
                                                        ));
                                                  },
                                                  icon: Icon(Icons.headphones),
                                                  label: Text('Listen'),
                                                ),
                                                ElevatedButton.icon(
                                                  onPressed: () async {
                                                    navigateWithNoBack(
                                                        context,
                                                        BookPdfScreen(
                                                          book: widget.book,
                                                          bookpath: bookpath,
                                                        ));
                                                  },
                                                  icon: Icon(Icons.book),
                                                  label: Text('Read'),
                                                ),
                                              ],
                                            ),
                                            Text(
                                                'Timeleft ${_timeLeft.inDays}d:'
                                                '${_timeLeft.inHours.remainder(24)}h:'
                                                '${_timeLeft.inMinutes.remainder(60)}m:'
                                                '${_timeLeft.inSeconds.remainder(60)}s')
                                          ],
                                        );
                                      }
                                    }

                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            _settingModalBottomSheet(
                                                context, book.freeRentPaid);
                                          },
                                          icon: Icon(Icons.lock),
                                          label: Text('Rent'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                              if (book.freeRentPaid == "free" ||
                                  book.userid ==
                                      FirebaseAuth.instance.currentUser!.uid) {
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                        onPressed: () {
                                          flutterToast('Loading...');
                                          navigateWithNoBack(
                                              context,
                                              ListenBookScreen(
                                                book: widget.book,
                                                bookpath: bookpath,
                                              ));
                                        },
                                        icon: Icon(Icons.headphones),
                                        label: Text('Listen')),
                                    ElevatedButton.icon(
                                        onPressed: () async {
                                          // _settingModalBottomSheet(context);

                                          navigateWithNoBack(
                                              context,
                                              BookPdfScreen(
                                                book: widget.book,
                                                bookpath: bookpath,
                                              ));
                                        },
                                        icon: Icon(Icons.book),
                                        label: Text('Read')),
                                  ],
                                );
                              }
                            }
                            return Container();
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 54.0, vertical: 10),
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Title',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                    SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        widget.book.title,
                                        // overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Price',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                    Text(
                                      "\$" + widget.book.price.toString(),
                                      style: TextStyle(fontSize: 16),
                                    )
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Tags',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                        Row(children: [
                                          Text(
                                            widget.book.tag1.length < 6
                                                ? widget.book.tag1 + ','
                                                : widget.book.tag1
                                                        .substring(0, 6) +
                                                    '..' +
                                                    ' ,',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          Text(
                                            widget.book.tag2.length < 6
                                                ? widget.book.tag2 + ','
                                                : widget.book.tag2
                                                        .substring(0, 6) +
                                                    '..' +
                                                    ' ,',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          Text(
                                            widget.book.tag3.length < 6
                                                ? widget.book.tag3 + ','
                                                : widget.book.tag3
                                                        .substring(0, 6) +
                                                    '..' +
                                                    '',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ])
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Author',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                    Text(
                                      widget.book.author,
                                      style: TextStyle(fontSize: 16),
                                    )
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Published Year',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
                                        widget.book.publishyear),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Reviews',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    TextButton(
                                        onPressed: () {
                                          navigateWithNoBack(
                                              context,
                                              ViewAllReviewsScreen(
                                                  book: widget.book));
                                        },
                                        child: Text(
                                          'see all',
                                          style: TextStyle(
                                            color: themeNotifier.getTheme() ==
                                                    ThemeData.dark(
                                                            useMaterial3: true)
                                                        .copyWith(
                                                      colorScheme:
                                                          ColorScheme.dark()
                                                              .copyWith(
                                                        primary:
                                                            darkprimarycolor,
                                                        error: Colors.red,
                                                        onPrimary:
                                                            darkprimarycolor,
                                                        outline:
                                                            darkprimarycolor,
                                                        primaryVariant:
                                                            darkprimarycolor,
                                                        onPrimaryContainer:
                                                            darkprimarycolor,
                                                      ),
                                                    )
                                                ? darkprimarycolor
                                                : primarycolor,
                                            // fontWeight: FontWeight.bold,
                                          ),
                                        ))
                                  ],
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Consumer<ReviewProvider>(
                                  builder: (context, provider, child) {
                                    return Column(children: [
                                      // provider.reviews.length
                                      provider.reviews.length > 0 &&
                                              provider.users.length > 0
                                          ? Card(
                                              shadowColor: themeNotifier
                                                          .getTheme() ==
                                                      ThemeData.dark(
                                                              useMaterial3:
                                                                  true)
                                                          .copyWith(
                                                        colorScheme:
                                                            ColorScheme.dark()
                                                                .copyWith(
                                                          primary:
                                                              darkprimarycolor,
                                                          error: Colors.red,
                                                          onPrimary:
                                                              darkprimarycolor,
                                                          outline:
                                                              darkprimarycolor,
                                                          primaryVariant:
                                                              darkprimarycolor,
                                                          onPrimaryContainer:
                                                              darkprimarycolor,
                                                        ),
                                                      )
                                                  ? darkprimarycolor
                                                  : primarycolor,
                                              elevation: 6,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(12.0),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceAround,
                                                      children: [
                                                        CircleAvatar(
                                                          maxRadius: 20,
                                                          backgroundImage:
                                                              NetworkImage(
                                                                  provider
                                                                      .users[0]
                                                                      .photo),
                                                        ),
                                                        Text(
                                                          provider.users[0].name
                                                                      .length >
                                                                  10
                                                              ? provider
                                                                      .users[0]
                                                                      .name
                                                                      .substring(
                                                                          0,
                                                                          10) +
                                                                  '...'
                                                              : provider
                                                                  .users[0]
                                                                  .name,
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16),
                                                        ),
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.star,
                                                              color:
                                                                  Colors.amber,
                                                            ),
                                                            Text((provider.reviews[0]
                                                                            .rating +
                                                                        1)
                                                                    .toString() +
                                                                '/5'),
                                                          ],
                                                        )
                                                      ],
                                                    ),
                                                    SizedBox(
                                                      height: 10,
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets
                                                              .fromLTRB(
                                                          10.0, 0, 0, 0),
                                                      child: Wrap(children: [
                                                        Text(
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                            ),
                                                            provider.reviews[0]
                                                                .reviewtext)
                                                      ]),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            )
                                          : const Center(
                                              child: Text('No Reviews found')),
                                      const SizedBox(height: 5),
                                      provider.reviews.length > 1 &&
                                              provider.users.length > 1
                                          ? Card(
                                              shadowColor: themeNotifier
                                                          .getTheme() ==
                                                      ThemeData.dark(
                                                              useMaterial3:
                                                                  true)
                                                          .copyWith(
                                                        colorScheme:
                                                            ColorScheme.dark()
                                                                .copyWith(
                                                          primary:
                                                              darkprimarycolor,
                                                          error: Colors.red,
                                                          onPrimary:
                                                              darkprimarycolor,
                                                          outline:
                                                              darkprimarycolor,
                                                          primaryVariant:
                                                              darkprimarycolor,
                                                          onPrimaryContainer:
                                                              darkprimarycolor,
                                                        ),
                                                      )
                                                  ? darkprimarycolor
                                                  : primarycolor,
                                              elevation: 6,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(12.0),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceAround,
                                                      children: [
                                                        CircleAvatar(
                                                          maxRadius: 20,
                                                          backgroundImage:
                                                              NetworkImage(
                                                                  provider
                                                                      .users[1]
                                                                      .photo),
                                                        ),
                                                        Text(
                                                          provider.users[1].name
                                                                      .length >
                                                                  10
                                                              ? provider
                                                                      .users[1]
                                                                      .name
                                                                      .substring(
                                                                          0,
                                                                          10) +
                                                                  '...'
                                                              : provider
                                                                  .users[1]
                                                                  .name,
                                                          style:
                                                              const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16),
                                                        ),
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                              Icons.star,
                                                              color:
                                                                  Colors.amber,
                                                            ),
                                                            Text(
                                                                '${provider.reviews[1].rating + 1}/5'),
                                                          ],
                                                        )
                                                      ],
                                                    ),
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets
                                                              .fromLTRB(
                                                          10.0, 0, 0, 0),
                                                      child: Wrap(children: [
                                                        Text(
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                            ),
                                                            provider.reviews[1]
                                                                .reviewtext)
                                                      ]),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            )
                                          : Container(),
                                      const SizedBox(height: 5),
                                      provider.reviews.length > 2 &&
                                              provider.users.length > 2
                                          ? Card(
                                              shadowColor: themeNotifier
                                                          .getTheme() ==
                                                      ThemeData.dark(
                                                              useMaterial3:
                                                                  true)
                                                          .copyWith(
                                                        colorScheme:
                                                            ColorScheme.dark()
                                                                .copyWith(
                                                          primary:
                                                              darkprimarycolor,
                                                          error: Colors.red,
                                                          onPrimary:
                                                              darkprimarycolor,
                                                          outline:
                                                              darkprimarycolor,
                                                          primaryVariant:
                                                              darkprimarycolor,
                                                          onPrimaryContainer:
                                                              darkprimarycolor,
                                                        ),
                                                      )
                                                  ? darkprimarycolor
                                                  : primarycolor,
                                              elevation: 6,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(12.0),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceAround,
                                                      children: [
                                                        CircleAvatar(
                                                          maxRadius: 20,
                                                          backgroundImage:
                                                              NetworkImage(
                                                                  provider
                                                                      .users[2]
                                                                      .photo),
                                                        ),
                                                        Text(
                                                          provider.users[2].name
                                                                      .length >
                                                                  10
                                                              ? provider
                                                                      .users[2]
                                                                      .name
                                                                      .substring(
                                                                          0,
                                                                          10) +
                                                                  '...'
                                                              : provider
                                                                  .users[2]
                                                                  .name,
                                                          style:
                                                              const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16),
                                                        ),
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                              Icons.star,
                                                              color:
                                                                  Colors.amber,
                                                            ),
                                                            Text(
                                                                '${provider.reviews[2].rating + 1}/5'),
                                                          ],
                                                        )
                                                      ],
                                                    ),
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets
                                                              .fromLTRB(
                                                          10.0, 0, 0, 0),
                                                      child: Wrap(children: [
                                                        Text(
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                            ),
                                                            provider.reviews[2]
                                                                .reviewtext)
                                                      ]),
                                                    )
                                                  ],
                                                ),
                                              ))
                                          : Container()
                                    ]);
                                  },
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Recommended Books',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          _recommendations.length == 0
                              ? nobooksmsg == ''
                                  ? Text('Loading...')
                                  : Text('No Similar Books Found')
                              : Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    height: 40,
                                    width: width * 0.9,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _recommendations.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return InkWell(
                                            onTap: () {
                                              // flutterToast(_recommendations[index][0]);
                                              RegExp regExp =
                                                  RegExp(r'[^\w\s]+');
                                              String search = _recommendations[
                                                          index][0]
                                                      .replaceAll(regExp, '') +
                                                  ' by ' +
                                                  _recommendations[index][1]
                                                      .replaceAll(regExp, '');
                                              var url =
                                                  'https://www.google.com/search?tbm=bks&q=' +
                                                      search;
                                              launchUrl(Uri.parse(url));
                                            },
                                            child: SizedBox(
                                              height: 40,
                                              child: Card(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          18.0),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          18.0),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            6.0),
                                                    child: Text(
                                                      _recommendations[index]
                                                          [0],
                                                      style: TextStyle(
                                                          fontSize: 14.0),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ));
                                      },
                                    ),
                                  ),
                                )
                        ],
                      ),
                    )),
              ),
      ),
    );
  }
}
