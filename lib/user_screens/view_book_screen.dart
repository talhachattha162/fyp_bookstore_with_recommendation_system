import 'dart:async';
import 'dart:io';
import 'package:bookstore_recommendation_system_fyp/models/user.dart';
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
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../Widgets/text_field.dart';
import '../models/book.dart';
import '../models/notificationitem.dart';
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
// import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/snackbar.dart';

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
  int _durationDays = 0;
  DateTime currentBackPressTime = DateTime.now();

  bool isDownloading = false;

  String downloadString = '';

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

  Future<String> getName(String userId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference documentReference =
        firestore.collection('users').doc(userId);
    final DocumentSnapshot snapshot = await documentReference.get();
    final String name = snapshot.get('name');
    return name;
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

  Future<void> downloadFile(
      BuildContext context, String url, String fileName) async {
    // Request permission to access storage if not already granted.
    final status = await Permission.storage.request();
    if (status.isDenied) {
      // Permission denied, show an error message and return.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Permission denied.')));
      return;
    }

    try {
      // Get the downloads directory on Android.
      // On iOS, use getApplicationDocumentsDirectory instead.
      // final dir = await DownloadsPathProvider.downloadsDirectory;
      // final file = File('${dir.path}/$fileName.pdf');
      final downloadsDirectory = await getExternalStorageDirectory();
      final file = File('${downloadsDirectory!.path}/$fileName.pdf');
      HttpClient httpClient = HttpClient();
      HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
      HttpClientResponse response = await request.close();
      await response.pipe(file.openWrite());
      httpClient.close();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Download Successful', style: TextStyle(fontSize: 20)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Column(
                    children: [
                      Icon(Icons.check_circle_outline),
                      Text('Downloaded at ${downloadsDirectory.path} folder',
                          style: TextStyle(fontSize: 12))
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );

      // Show a SnackBar with a message if the download was successful.
      // showSnackBar(context,'Downloaded at Downloads folder');
    } catch (e) {
      // Show an error message if the download failed.
      // showSnackBar(context,'Download failed: $e');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Download Failed', style: TextStyle(fontSize: 20)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Column(
                    children: [
                      Icon(Icons.error),
                      Text('$e', style: TextStyle(fontSize: 12))
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    }
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
    getUserData();
    subscriptionChecker();
    _razorpay = Razorpay();
    _razorpay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay?.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay?.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    super.initState();
    _paymentsStreamSubscription = paymentsStream().listen((hasData) {
      if (hasData) {
        if (mounted) {
          setState(() {
            hasDataf = true;
          });
        }
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
    if (mounted) {
      setState(() {
        favourite = isFavorited;
      });
    }
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
    _subscriptionsStream.cancel();
    // _razorpay!.clear();
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
        DateTime.now(),
        _durationDays);
    await bookCollection
        .doc(paymentid)
        .set(payment.toMap())
        .then((value) async {})
        .onError((error, stackTrace) async {
      Fluttertoast.showToast(msg: 'Error:' + error.toString());
    }).then((value) {
      Fluttertoast.showToast(msg: " Payment Successful");
      purchaseNotification(widget.book.title,
          FirebaseAuth.instance.currentUser!.uid, widget.book.userid);
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
    // var mapHeader = <String, String>{};

    // String apiKey = "rzp_test_tlNELsTTfVj6JA";
    // String apiSecret = "BZCGXLmKoYMRXwE2rplvQZGO";

    // String credentials = base64.encode(utf8.encode('$apiKey:$apiSecret'));
    // mapHeader['Authorization'] = "Basic $credentials";
    // mapHeader['Accept'] = "application/json";
    // mapHeader['Content-Type'] = "application/x-www-form-urlencoded";
    // var map = <String, String>{};
    // setState(() {
    //   map['amount'] = '${widget.book.price}';
    // });
    // map['currency'] = "USD";
    // var response = await http.post(Uri.https("api.razorpay.com", "/v1/orders"),
    //     headers: mapHeader, body: map);
    // if (response.statusCode == 200) {
    //   RazorpayOrderResponse data =
    //       RazorpayOrderResponse.fromJson(json.decode(response.body));
    //   // print('repo2:' + response.body.toString());
    //   // print('repo2:' + data.toString());
    openCheckout();
    // } else {
    //   Fluttertoast.showToast(msg: 'error:${response.reasonPhrase}');
    // }
  }

  void openCheckout() async {
    // print('hello');
// Card Number: 4111 1111 1111 1111
// Expiry Date: Any future date
// CVV: Any 3-digit number
// Name on Card: Any name
    final name = await getName(FirebaseAuth.instance.currentUser!.uid);
    var options = {
      'key': 'rzp_test_tlNELsTTfVj6JA',
      'amount': widget.book.price.toInt() * 100, //* 82
      'currency': 'USD', //'INR'
      'name': name,
      'description': widget.book.title,
      'prefill': {
        'name': name,
        'email': FirebaseAuth.instance.currentUser!.email,
        'contact': FirebaseAuth.instance.currentUser!.phoneNumber,
        'card[number]': '4111111111111111',
        'card[expiry]': '12/24',
        'card[cvv]': '123',
        'notes': {
          'address': '123 Main Street, Anytown USA',
          'shipping_method': 'Express'
        }
      },
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

  final TextEditingController _durationdaysController = TextEditingController();
  final RegExp _durationdays_valid = RegExp(r"^\d+$");

  void _settingModalBottomSheetForpayment(
      context, freeRentPaid, themeNotifier) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SizedBox(
            height: 260,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    freeRentPaid == "rent"
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Text(
                              //   'Use: \nCard Number: 4111 1111 1111 1111\nExpiry Date: 12/23\nCVV: 123\nName on Card: John Doe',
                              //   style: TextStyle(
                              //       fontSize: 10, color: Colors.redAccent),
                              // ),
                              Text('Enter Duration in days to rent',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              SizedBox(
                                height: 40,
                                width: 210,
                                child: TextInputField(
                                  hintText: 'Enter Duration',
                                  suffixIcon: Text(''),
                                  isPassword: false,
                                  textEditingController:
                                      _durationdaysController,
                                  validator: (value) {
                                    if (value.isEmpty || value == "0") {
                                      return 'Enter valid Duration';
                                    }
                                    if (!_durationdays_valid.hasMatch(value)) {
                                      return 'only digits allowed';
                                    }
                                  },
                                  textInputType: TextInputType.number,
                                ),
                              ),
                              SizedBox(height: 10),
                            ],
                          )
                        : Container(
                            height: 0,
                            width: 0,
                          ),
                    const Text(
                      'Pay with Razor Payment',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Divider(thickness: 30),
                    ElevatedButton(
                      onPressed: () {
                        if (_durationdaysController.text != '') {
                          if (mounted) {
                            setState(() {
                              _durationDays =
                                  int.parse(_durationdaysController.text);
                            });
                          }
                        }

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
                    ),
                    // ElevatedButton(
                    //     onPressed: () {
                    //       navigateWithNoBack(context, GooglePayInit());
                    //     },
                    //     child: Text('Pay with Google'))
                  ],
                ),
              ],
            ),
          );
        });
  }

  late CollectionReference<Map<String, dynamic>> _subscriptionsRef;
  late StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      _subscriptionsStream;
  bool _isSubscribed = false;

  subscriptionChecker() {
    _subscriptionsRef = FirebaseFirestore.instance.collection('Subscriptions');
    _subscriptionsStream = _subscriptionsRef
        .where('FromUserId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('ToUserId', isEqualTo: widget.book.userid)
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
      if (snapshot.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _isSubscribed = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isSubscribed = false;
          });
        }
      }
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

  void _startDownload() async {
    if (mounted) {
      setState(() {
        isDownloading = true;
      });
    }

    try {
      await downloadFile(context, widget.book.bookFile, widget.book.title);
      if (mounted) {
        setState(() {
          downloadString = 'Download Successful';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          downloadString = 'Download failed';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
  }

  Users? _userData;

  getUserData() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.book.userid)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        if (mounted) {
          setState(() {
            _userData = Users.fromMap(
                (documentSnapshot.data() as Map<String, dynamic>?)!);
          });
        }
      }
    });
  }

  Future<void> _subscribe() async {
    _subscriptionsRef
        .doc(widget.book.userid + FirebaseAuth.instance.currentUser!.uid)
        .set({
      'FromUserId': FirebaseAuth.instance.currentUser!.uid,
      'ToUserId': widget.book.userid,
    }).then((value) {
      if (mounted) {
        setState(() {
          _isSubscribed = true;
        });
      }
    });
    final name = await getName(FirebaseAuth.instance.currentUser!.uid);
    NotificationItem item = NotificationItem(
        '$name subscribed you', widget.book.userid, Timestamp.now());
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference collectionReference =
        firestore.collection('notifications');
    final Map<String, dynamic> data = item.toMap();
    await collectionReference.add(data);
  }

  void _unsubscribe() async {
    _subscriptionsRef
        .doc(widget.book.userid + FirebaseAuth.instance.currentUser!.uid)
        .delete()
        .then((_) {
      if (mounted) {
        setState(() {
          _isSubscribed = false;
        });
      }
    }).catchError((error) => print('Error unsubscribing: $error'));

    final name = await getName(FirebaseAuth.instance.currentUser!.uid);
    NotificationItem item = NotificationItem(
        '$name unsubscribed you ', widget.book.userid, Timestamp.now());
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference collectionReference =
        firestore.collection('notifications');
    final Map<String, dynamic> data = item.toMap();
    await collectionReference.add(data);
  }

  purchaseNotification(title, purchasedby, userid) async {
    final name = await getName(purchasedby);
    NotificationItem item = NotificationItem(
        title + ' book is purchased by $name', userid, Timestamp.now());
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference collectionReference =
        firestore.collection('notifications');
    await collectionReference.add(item.toMap());
    print('notification2:' + item.toMap().toString());
  }

  @override
  Widget build(BuildContext context) {
    final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    // print(hasDataf);
    return WillPopScope(
      onWillPop:  () async {
        navigateWithNoBack(context, MainScreenUser());
        return false;
      },
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
                                      LoadingAnimationWidget.fourRotatingDots(
                                    color: themeNotifier.getTheme() ==
                                    ThemeData.dark(useMaterial3: true).copyWith(
                                      colorScheme: ColorScheme.dark().copyWith(
                                        primary: darkprimarycolor,
                                        error: Colors.red,
                                        onPrimary: darkprimarycolor,
                                        outline: darkprimarycolor,
                                        primaryVariant: darkprimarycolor,
                                        onPrimaryContainer: darkprimarycolor,
                                      ),
                                    )
                                ? darkprimarycolor
                                : primarycolor,
                                    size: 50,
                                  ),
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
                              IconButton(
                                  onPressed: (hasDataf == true &&
                                              widget.book.freeRentPaid ==
                                                  'paid') ||
                                          widget.book.freeRentPaid == 'free'
                                      ? _startDownload
                                      : null,
                                  icon: isDownloading
                                      ? Center(
                                          child: SizedBox(
                                            height: 10,
                                            width: 10,
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : Icon(Icons.download)),
                              IconButton(
                                  onPressed: hasDataf == true ||
                                          widget.book.freeRentPaid == 'free' ||
                                          widget.book.userid ==
                                              FirebaseAuth
                                                  .instance.currentUser!.uid
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
                                          if (mounted) {
                                            setState(() {
                                              favourite = true;
                                            });
                                          }
                                        }).catchError((error) => print(
                                            'Failed to add favourities: $error'));
                                      } else {
                                        querySnapshot.docs.forEach((doc) {
                                          doc.reference.delete().then((value) {
                                            print('favourities deleted');
                                            if (mounted) {
                                              setState(() {
                                                favourite = false;
                                              });
                                            }
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
                                child: Text('Loading...'),
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
                                                _settingModalBottomSheetForpayment(
                                                    context,
                                                    book.freeRentPaid,
                                                    Provider.of<ThemeNotifier>(
                                                        context,
                                                        listen: false));
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
                                            // flutterToast('Loading...');
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
                                      int duration = 0;

                                      Duration? difference = Duration.zero;
                                      if (snapshot.data!.docs.isNotEmpty) {
                                        duration = snapshot
                                            .data!.docs.first['durationDays'];
                                        paymentCreationTime = snapshot.data!
                                            .docs.first['dateTimeCreated'];

                                        DateTime expirationDate =
                                            paymentCreationTime!
                                                .toDate()
                                                .add(Duration(days: duration));
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          if (mounted) {
                                            setState(() {
                                              _timeLeft = expirationDate
                                                  .difference(DateTime.now());
                                            });
                                          }
                                        });
                                      }

                                      if (snapshot.data!.docs.length != 0) {
                                        if (!_timeLeft.isNegative) {
                                          return Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  ElevatedButton.icon(
                                                    onPressed: () {
                                                      // flutterToast(
                                                      //     'Loading...');
                                                      navigateWithNoBack(
                                                          context,
                                                          ListenBookScreen(
                                                            book: widget.book,
                                                            bookpath: bookpath,
                                                          ));
                                                    },
                                                    icon:
                                                        Icon(Icons.headphones),
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
                                    }

                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            _settingModalBottomSheetForpayment(
                                                context,
                                                book.freeRentPaid,
                                                Provider.of<ThemeNotifier>(
                                                    context,
                                                    listen: false));
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
                                          // flutterToast('Loading...');
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
                                                        SizedBox(
                                                          height: 30,
                                                          width: 30,
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                            child:
                                                                Image.network(
                                                              provider.users[0]
                                                                  .photo,
                                                              errorBuilder:
                                                                  (context,
                                                                      error,
                                                                      stackTrace) {
                                                                return Icon(
                                                                    Icons.error,
                                                                    size: 20);
                                                              },
                                                            ),
                                                          ),
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
                                                        SizedBox(
                                                          height: 30,
                                                          width: 30,
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                            child:
                                                                Image.network(
                                                              provider.users[1]
                                                                  .photo,
                                                              errorBuilder:
                                                                  (context,
                                                                      error,
                                                                      stackTrace) {
                                                                return Icon(
                                                                    Icons.error,
                                                                    size: 20);
                                                              },
                                                            ),
                                                          ),
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
                                                        SizedBox(
                                                          height: 30,
                                                          width: 30,
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                            child:
                                                                Image.network(
                                                              provider.users[2]
                                                                  .photo,
                                                              errorBuilder:
                                                                  (context,
                                                                      error,
                                                                      stackTrace) {
                                                                return Icon(
                                                                    Icons.error,
                                                                    size: 20);
                                                              },
                                                            ),
                                                          ),
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
                                ),
                          FirebaseAuth.instance.currentUser!.uid ==
                                  widget.book.userid
                              ? Container()
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                      Text(_userData != null
                                          ? _userData!.name.length > 10
                                              ? 'Uploaded by ' +
                                                  _userData!.name
                                                      .substring(0, 10)
                                              : 'Uploaded by ' + _userData!.name
                                          : 'Uploaded by Admin'),
                                      ElevatedButton(
                                        onPressed: _isSubscribed
                                            ? _unsubscribe
                                            : _subscribe,
                                        child: Text(_isSubscribed
                                            ? 'Unsubscribe'
                                            : 'Subscribe'),
                                      )
                                    ]),
                        ],
                      ),
                    )),
              ),
      ),
    );
  }
}
