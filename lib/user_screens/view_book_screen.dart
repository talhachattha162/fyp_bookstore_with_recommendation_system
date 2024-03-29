import 'dart:async';
import 'dart:io';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bookstore_recommendation_system_fyp/models/user.dart';
import 'package:bookstore_recommendation_system_fyp/providers/favoritebookProvider.dart';
import 'package:bookstore_recommendation_system_fyp/providers/recommendationViewBookProvider.dart';
import 'package:bookstore_recommendation_system_fyp/providers/userdataViewBookProvider.dart';
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
import '../providers/TimeLeftProvider.dart';
import '../providers/bookprovider.dart';
// import '../providers/internetavailabilitynotifier.dart';
import '../providers/hasDataFviewbookprovider.dart';
import '../providers/isDownloadingViewbookprovider.dart';
import '../providers/linkprovider.dart';
import '../providers/reviewnotifier.dart';
import '../providers/subscribeViewBookProvider.dart';
import '../providers/themenotifier.dart';
// import '../utils/InternetChecker.dart';
import '../utils/firebase_constants.dart';
import '../utils/fluttertoast.dart';
import '../utils/global_variables.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
// import '../models/razorpay_response.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// import '../utils/snackbar.dart';
import 'edit_screen.dart';

class ViewBookScreen extends StatefulWidget {
  final Book book;
  ViewBookScreen({super.key, required this.book});

  @override
  State<ViewBookScreen> createState() => _ViewBookScreenState();
}

class _ViewBookScreenState extends State<ViewBookScreen> {
//used from here
//https://www.simplifiedcoding.net/razorpay-integration-flutter/
//UPI->success@razorpay
//   bool favourite = false;
  Razorpay? _razorpay;
  Timer? timer;
  var bookpath;
  String nobooksmsg = '';
  // Duration _timeLeft = Duration.zero;
  int _durationDays = 0;
  DateTime currentBackPressTime = DateTime.now();

  // bool isDownloading = false;

  // String downloadString = '';

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

      final snackBar = SnackBar(
        /// need to set following properties for best effect of awesome_snackbar_content
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,

        content: AwesomeSnackbarContent(
          title: 'Error!',
          message: 'Permission denied.',

          /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
          contentType: ContentType.failure,
        ),
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
      // ScaffoldMessenger.of(context)
      //     .showSnackBar(SnackBar(content: Text('Permission denied.')));
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
            title: const Text('Download Successful', style:  TextStyle(fontSize: 20)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Column(
                    children: [
                      const Icon(Icons.check_circle_outline),
                      Text('Downloaded at ${downloadsDirectory.path} folder',
                          style: const TextStyle(fontSize: 12))
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
                child: const Text('Close'),
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
            title: const Text('Download Failed', style:  TextStyle(fontSize: 20)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Column(
                    children: [
                      const Icon(Icons.error),
                      Text('$e', style:const  TextStyle(fontSize: 12))
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
                child: const Text('Close'),
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
      Directory appDocDir = await getTemporaryDirectory();
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
    if (querySnapshot.docs.isNotEmpty)
    {
      Provider.of<FavoriteViewBookProvider>(context,listen: false).favourite=true;
      // if (mounted) {
      //   setState(() {
      //     favourite = true;
      //   });
      // }
    }
    else {}
  }

  deleteFavouritesForBookId(String bookId) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection('favourities')
        .where('bookid', isEqualTo: bookId)
        .get();

    querySnapshot.docs.forEach((doc) {
      doc.reference.delete();
    });
  }

  deleteReviewsForBookId(String bookId) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection('reviews')
        .where('bookId', isEqualTo: bookId)
        .get();

    querySnapshot.docs.forEach((doc) {
      doc.reference.delete();
    });
  }



  // bool hasDataf = false;
  @override
  void initState() {
    // LinkProvider linkProvider = Provider.of<LinkProvider>(context, listen: false);
    // print(linkProvider.link);
    checkPaymentsExistForBookId(widget.book.bookid);
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
        Provider.of<HasDataBookProvider>(context, listen: false).hasDataf=true;
        // if (mounted) {
        //   setState(() {
        //     hasDataf = true;
        //   });
        // }
      }
    });
    // timer = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
    //   final internetAvailabilityNotifier =
    //       Provider.of<InternetNotifier>(context, listen: false);
    //   try {
    //     final result = await InternetAddress.lookup('google.com');
    //     if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty)
    //         ) {
    //       internetAvailabilityNotifier.setInternetAvailability(true);
    //     } else {}
    //   } on SocketException catch (_) {
    //     internetAvailabilityNotifier.setInternetAvailability(false);
    //   }
    // });
    checkFavourities();
    bookpath = storeFile();
    // _checkIfBookIsFavorited();
  }

  CollectionReference books = FirebaseFirestore.instance.collection('books');
  Future<void> deleteBook(String bookId) {
    return books
        .doc(bookId) // Reference to the document with the given ID
        .delete() // Delete the document
        .then((value) {
      final snackBar = SnackBar(
        /// need to set following properties for best effect of awesome_snackbar_content
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,

        content: AwesomeSnackbarContent(
          title: 'Success!',
          message: "Book deleted successfully",

          /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
          contentType: ContentType.success,
        ),
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }).catchError((error) => print("Failed to delete book: $error"));
  }

  // Future<void> _checkIfBookIsFavorited() async {
  //   final isFavorited = await isBookFavorited();
  //   if (mounted) {
  //     setState(() {
  //       favourite = isFavorited;
  //     });
  //   }
  // }

  StreamSubscription<bool>? _paymentsStreamSubscription;

  // List<dynamic> _recommendations = [];

  Future<void> _getRecommendations(String bookname) async {
    LinkProvider linkProvider = Provider.of<LinkProvider>(context, listen: false);
    String link=linkProvider.link;
    final response = await http.get(Uri.parse(
        '$link $bookname'));
    if (response.statusCode == 200) {
      if (response.body is List) {
      } else if (response.body is String) {
        nobooksmsg = response.body;
        print('nobooksmsg'+nobooksmsg.toString());
      }
      Provider.of<RecViewBookProvider>(context,listen: false).recommendations=jsonDecode(response.body);
      // if (mounted) {
      //   setState(() {
      //     _recommendations =jsonDecode(response.body) ;
      //   });
      // }
    } else {
      nobooksmsg='error';
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
      Fluttertoast.showToast(msg: 'Error: Reload' );
    }).then((value) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          // set up the button
          Widget okButton = TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          );

          // set up the AlertDialog
          AlertDialog alert = AlertDialog(
            title: const Text("Payment Successful"),
            content: const Text("Thank you for your payment!"),
            actions: [
              okButton,
            ],
          );

          // return the alert dialog
          return alert;
        },
      );

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
        if(_durationdaysController.text!=''){
          data['balance'] = data['balance'] + widget.book.price*int.parse((_durationdaysController.text));
        }
        else{
          data['balance'] = data['balance'] + widget.book.price;
        }

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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // set up the button
        Widget okButton = TextButton(
          child:const  Text("OK"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        );

        // set up the AlertDialog
        AlertDialog alert = AlertDialog(
          title:const  Text("Payment Failed"),
          content:const  Text("Try next time"),
          actions: [
            okButton,
          ],
        );

        // return the alert dialog
        return alert;
      },
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // set up the button
        Widget okButton = ElevatedButton(
          child:const  Text("OK"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        );

        // set up the AlertDialog
        AlertDialog alert = AlertDialog(
          title:const  Text("Payment Successful"),
          content:const  Text("Thank you for your payment!"),
          actions: [
            okButton,
          ],
        );

        // return the alert dialog
        return alert;
      },
    );
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
      // widget.book.price.toInt() * 100
      'key': 'rzp_test_tlNELsTTfVj6JA',
      'amount': _durationdaysController.text==''?widget.book.price.toInt()* 100:widget.book.price.toInt()*int.parse((_durationdaysController.text)) * 100, //* 82
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
                              const Text('Enter Duration in days to rent',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 40,
                                width: 210,
                                child: TextInputField(
                                  hintText: 'Enter Duration',
                                  suffixIcon: const Text(''),
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
                              const SizedBox(height: 10),
                              Text(_durationdaysController.text!=''?'Price: \$${widget.book.price * int.parse(_durationdaysController.text)}':'Price: \$${widget.book.price}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),

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
                          // if (mounted) {
                          //   setState(() {
                              _durationDays =
                                  int.parse(_durationdaysController.text);
                          //   });
                          // }
                        }

                        createOrder();
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 95.0, vertical: 9.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const  Text('Pay'),
                            const Icon(Icons.arrow_forward),
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
  // bool _isSubscribed = false;

  subscriptionChecker() {
    _subscriptionsRef = FirebaseFirestore.instance.collection('Subscriptions');
    _subscriptionsStream = _subscriptionsRef
        .where('FromUserId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('ToUserId', isEqualTo: widget.book.userid)
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
      if (snapshot.docs.isNotEmpty) {
        Provider.of<SubscribeViewBookProvider>(context,listen: false).isSubscribed=true;
        // if (mounted) {
        //   setState(() {
        //     _isSubscribed = true;
        //   });
        // }
      } else {
        Provider.of<SubscribeViewBookProvider>(context,listen: false).isSubscribed=false;
        // if (mounted) {
        //   setState(() {
        //     _isSubscribed = false;
        //   });
        // }
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
          const Duration(seconds: 1)); // Wait for 1 second before checking again
    }
  }

  void _startDownload() async {
    Provider.of<isDownloadingViewBookProvider>(context,listen: false).isDownloading=true;

    // if (mounted) {
    //   setState(() {
    //     isDownloading = true;
    //   });
    // }

    try {
      await downloadFile(context, widget.book.bookFile, widget.book.title);
      // if (mounted) {
      //   setState(() {
      //     downloadString = 'Download Successful';
      //   });
      // }
    } catch (e) {
      // if (mounted) {
      //   setState(() {
      //     downloadString = 'Download failed';
      //   });
      // }
    } finally {
      Provider.of<isDownloadingViewBookProvider>(context,listen: false).isDownloading=false;
      // if (mounted) {
      //   setState(() {
      //     isDownloading = false;
      //   });
      // }
    }
  }

  // Users? _userData;

  getUserData() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.book.userid)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        if (mounted) {
          Provider.of<UserViewBookProvider>(context,listen: false).userData=Users.fromMap(
                    (documentSnapshot.data() as Map<String, dynamic>?)!);
          // setState(() {
          //   _userData = Users.fromMap(
          //           //       (documentSnapshot.data() as Map<String, dynamic>?)!);
          // });
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
      Provider.of<SubscribeViewBookProvider>(context,listen: false).isSubscribed=true;
      // if (mounted) {
      //   setState(() {
      //     _isSubscribed = true;
      //   });
      // }
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
      Provider.of<SubscribeViewBookProvider>(context,listen: false).isSubscribed=false;
      // if (mounted) {
      //   setState(() {
      //     _isSubscribed = false;
      //   });
      // }
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

  void deleteBookAndNavigate(BuildContext context) {

    deleteFavouritesForBookId(widget.book.bookid);
    deleteReviewsForBookId(widget.book.bookid);
    deleteBook(widget.book.bookid);
    Navigator.of(context).pop();
    navigateWithNoBack(context, const MainScreenUser());
  }

  bool paymentsExist = false;
  checkPaymentsExistForBookId(String bookId) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection('payments')
        .where('bookId', isEqualTo: bookId)
        .get();
    // print('fcghello1');
    if (querySnapshot.docs.isNotEmpty) {
      print(querySnapshot.docs.isNotEmpty);
      // print('fcghello');
      // setState(() {
        paymentsExist = true;
      // });
    }
  }

  void showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content:const  Text('Are you sure you want to delete this book?'),
          actions: <Widget>[
            TextButton(
              child:const  Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child:const  Text('Delete'),
              onPressed: () {
                deleteBookAndNavigate(context);
              },
            ),
          ],
        );
      },
    );
  }

  void showDeletionErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:const  Text('Cant delete'),
          content:const  Text('Someone once purchased your book'),
          actions: <Widget>[
            TextButton(
              child:const  Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  checkDelete(context) {
    // print('fcg:'+paymentsExist.toString());
    if (paymentsExist) {
      showDeletionErrorDialog(context);
    } else {
      showConfirmationDialog(context);
    }
  }

  void handleMenuItemSelected(String menuItem) {
    switch (menuItem) {
      case 'Delete':
        checkDelete(context);
        break;
      case 'Edit':
        navigateWithNoBack(context, EditBookScreen(book: widget.book));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
// print(_userData!.name);
    // print(hasDataf);
    return WillPopScope(
      onWillPop: () async {
        navigateWithNoBack(context, const MainScreenUser());
        return false;
      },
      child: SafeArea(
        child:
        // internetAvailabilityNotifier.getInternetAvailability() == false
        //     ? const InternetChecker()
        //     :
        MultiProvider(
                providers: [
                  ChangeNotifierProvider(
                    create: (_) =>
                        ReviewProvider()..getReviews(widget.book.bookid),
                  ),
                  ChangeNotifierProvider(
                    create: (_) => BookProvider()..getBook(widget.book.bookid),
                  ),
                ],
                child: Scaffold(
                    appBar: AppBar(
                        title: const Text('Book Details'),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            navigateWithNoBack(context, const MainScreenUser());
                          },
                        ),
                        actions: [
                          FirebaseAuth.instance.currentUser!.uid ==
                                  widget.book.userid
                              ? PopupMenuButton<String>(
                                  onSelected: handleMenuItemSelected,
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                   const  PopupMenuItem<String>(
                                      value: 'Edit',
                                      child: Text('Edit'),
                                    ),
                                   const PopupMenuItem<String>(
                                      value: 'Delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                )
                              : Container()
                        ]),
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
                                child: CachedNetworkImage(filterQuality:FilterQuality.low ,
                                  imageUrl: widget.book.coverPhotoFile,
                                  placeholder: (context, url) =>
                                      LoadingAnimationWidget.fourRotatingDots(
                                    color: themeNotifier.getTheme() ==
                                            ThemeData.dark(useMaterial3: true)
                                                .copyWith(
                                              colorScheme:
                                              const ColorScheme.dark().copyWith(
                                                primary: darkprimarycolor,
                                                error: Colors.red,
                                                onPrimary: darkprimarycolor,
                                                outline: darkprimarycolor,
                                                primaryVariant:
                                                    darkprimarycolor,
                                                onPrimaryContainer:
                                                    darkprimarycolor,
                                              ),
                                            )
                                        ? darkprimarycolor
                                        : primarycolor,
                                    size: 50,
                                  ),
                                  errorWidget: (context, url, error) =>
                                     const Icon(Icons.error),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Consumer<HasDataBookProvider>(builder: (context, provider, child) {
    return Consumer<isDownloadingViewBookProvider>(builder: (context, downprovider, child) {
    return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                    onPressed: (provider.hasDataf == true &&
                                                widget.book.freeRentPaid ==
                                                    'paid') ||
                                            widget.book.freeRentPaid == 'free'
                                        ? _startDownload
                                        : null,
                                    icon: downprovider.isDownloading
                                        ? const Center(
                                            child:  SizedBox(
                                              height: 10,
                                              width: 10,
                                              child: CircularProgressIndicator(),
                                            ),
                                          )
                                        : const Icon(Icons.download)),
                                IconButton(
                                    onPressed: provider.hasDataf == true ||
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

                                      // setState(() {

                                        if (Provider.of<FavoriteViewBookProvider>(context,listen: false).favourite == false) {
                                          favouritiesRef.add({
                                            'bookid': widget.book.bookid,
                                            'userid': FirebaseAuth
                                                .instance.currentUser!.uid,
                                          }).then((value) {
                                            print('favourities added');
                                            if (mounted) {
                                              // setState(() {
                                                Provider.of<FavoriteViewBookProvider>(context,listen: false).favourite = true;
                                              // });
                                            }
                                          }).catchError((error) => print(
                                              'Failed to add favourities: $error'));
                                        } else {
                                          querySnapshot.docs.forEach((doc) {
                                            doc.reference.delete().then((value) {
                                              print('favourities deleted');
                                              if (mounted) {
                                                // setState(() {
                                                  Provider.of<FavoriteViewBookProvider>(context,listen: false).favourite = false;
                                                  // favourite = false;
                                                // });
                                              }
                                            }).catchError((error) => print(
                                                'Failed to delete favourities: $error'));
                                          });
                                        }
                                      // });
                                    },
                                    icon: Consumer<FavoriteViewBookProvider>(builder: (context, favprovider, child) {
                                      return Icon(
                                        favprovider.favourite == true
                                            ? Icons.favorite_sharp
                                            : Icons.favorite_border,
                                        color: favprovider.favourite == true
                                            ? Colors.amber
                                            : Colors.grey,
                                      );
                                    },

                                    )),

                                //  IconButton(
                                //     onPressed: null, icon: Icon(Icons.download))
                              ],
                            );}
    );}),
                          const SizedBox(
                            height: 10,
                          ),
                          const Divider(),
                          const SizedBox(
                            height: 10,
                          ),
                          Consumer<BookProvider>(
                              builder: (context, bookprovider, child) {
                            Book? book = bookprovider.book;
                            print('book:'+book.toString());
                            if (book == null) {
                              return  Container(
                                child:const  Text('Loading...'),
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
                                              icon:const Icon(Icons.lock),
                                              label:const Text('Buy'),
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
                                          icon: const Icon(Icons.headphones),
                                          label:const Text('Listen'),
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
                                          icon:const Icon(Icons.book),
                                          label:const Text('Read'),
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
                                    var pass = false;
                                    if (snapshot.data != null) {
                                      if (snapshot.data!.docs.length != 0) {
                                        // print(snapshot.data!
                                        //     .docs.length);
                                        List<DateTime> expirationDates = [];
                                        for (var document
                                            in snapshot.data!.docs) {
                                          Timestamp? paymentCreationTime =
                                              document['dateTimeCreated'];
                                          int duration =
                                              document['durationDays'];
                                          DateTime expirationDate =
                                              paymentCreationTime!.toDate().add(
                                                  Duration(days: duration));
                                          expirationDates.add(expirationDate);
                                        }
// print(expirationDates);
                                        DateTime maxExpirationDate =
                                            expirationDates.reduce(
                                                (a, b) => a.isAfter(b) ? a : b);

                                        Duration timeLeft = maxExpirationDate
                                            .difference(DateTime.now());
                                        // print(maxExpirationDate);
                                        if (!timeLeft.isNegative) {
                                          pass = true;
                                        }
                                        WidgetsBinding.instance
                                            .addPostFrameCallback(
                                                (_) => Provider.of<TimeLeftViewBookProvider>(
                                                    context,
                                                    listen: false).timeleft=timeLeft
                                        );

                                        if (pass == true) {
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
                                                    const Icon(Icons.headphones),
                                                    label:const  Text('Listen'),
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
                                                    icon:const Icon(Icons.book),
                                                    label:const Text('Read'),
                                                  ),
                                                ],
                                              ),
    Consumer<TimeLeftViewBookProvider>(
    builder: (context, timeprovider, child) {return Text(
                                                    'Timeleft ${timeprovider.timeleft.inDays}d:'
                                                    '${timeprovider.timeleft.inHours.remainder(24)}h:'
                                                    '${timeprovider.timeleft.inMinutes.remainder(60)}m:'
                                                    '${timeprovider.timeleft.inSeconds.remainder(60)}s');}
                                              )
                                            ],
                                          );
                                        }
                                      }
                                    }

                                    // print('snaptalha:');
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
                                          icon:const Icon(Icons.lock),
                                          label:const Text('Rent'),
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
                                        icon:const  Icon(Icons.headphones),
                                        label: const Text('Listen')),
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
                                        icon:const Icon(Icons.book),
                                        label:const Text('Read')),
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
                                    const Text(
                                      'Title',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                   const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        widget.book.title,
                                        // overflow: TextOverflow.ellipsis,
                                        style:const TextStyle(fontSize: 16),
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
                                   const Text(
                                      'Price',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                    Text(
                                      "\$" + widget.book.price.toString(),
                                      style:const TextStyle(fontSize: 16),
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
                                        const Text(
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
                                            style:const TextStyle(fontSize: 16),
                                          ),
                                          Text(
                                            widget.book.tag2.length < 6
                                                ? widget.book.tag2 + ','
                                                : widget.book.tag2
                                                        .substring(0, 6) +
                                                    '..' +
                                                    ' ,',
                                            style:const TextStyle(fontSize: 16),
                                          ),
                                          Text(
                                            widget.book.tag3.length < 6
                                                ? widget.book.tag3 + ','
                                                : widget.book.tag3
                                                        .substring(0, 6) +
                                                    '..' +
                                                    '',
                                            style:const TextStyle(fontSize: 16),
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
                                   const Text(
                                      'Author',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                    Text(
                                      widget.book.author,
                                      style: const TextStyle(fontSize: 16),
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
                                   const Text(
                                      'Published Year',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                        style:const TextStyle(
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
                                   const Text(
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
                                                      const ColorScheme.dark()
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
                               const SizedBox(
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
                                                        const ColorScheme.dark()
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
                                                                return const Icon(
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
                                                          style:const TextStyle(
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
                                                            Text((provider.reviews[0]
                                                                            .rating +
                                                                        1)
                                                                    .toString() +
                                                                '/5'),
                                                          ],
                                                        )
                                                      ],
                                                    ),
                                                 const   SizedBox(
                                                      height: 10,
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets
                                                              .fromLTRB(
                                                          10.0, 0, 0, 0),
                                                      child: Wrap(children: [
                                                        Text(
                                                            style:const TextStyle(
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
                                                        const ColorScheme.dark()
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
                                                                return const Icon(
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
                                                        const ColorScheme.dark()
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
                                                                return const Icon(
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
                          const Text(
                            'Recommended Books',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Consumer<RecViewBookProvider>(
                            builder:(context, recprovider, child) {
                              return recprovider.recommendations.length == 0
                                ? nobooksmsg == ''
                                    ? Column(
                                      children: [
                                        const Text('Loading...'),
                                        const Text('Wait fo 2-3 minutes',style: TextStyle(fontSize: 10,color: Colors.grey),),
                                      ],
                                    )
                                    : const Text('No Books Found')
                                : Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      height: 40,
                                      width: width * 0.9,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        scrollDirection: Axis.horizontal,
                                        itemCount: recprovider.recommendations.length,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          return InkWell(
                                              onTap: () {
                                                // flutterToast(_recommendations[index][0]);
                                                RegExp regExp =
                                                    RegExp(r'[^\w\s]+');
                                                String search = recprovider.recommendations[
                                                            index][0]
                                                        .replaceAll(regExp, '') +
                                                    ' by ' +
                                                    recprovider.recommendations[index][1]
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
                                                        recprovider.recommendations[index]
                                                            [0],
                                                        style: const TextStyle(
                                                            fontSize: 14.0),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ));
                                        },
                                      ),
                                    ),
                                  );}
                          ),
                          FirebaseAuth.instance.currentUser!.uid ==
                                  widget.book.userid
                              ? Container()
                              : Consumer<UserViewBookProvider>(
                              builder: (context, userprovider, child) { return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                      Text(userprovider.userData != null && userprovider.userData!.name != 'admin'
                                          ? userprovider.userData!.name.length > 10
                                              ? 'Uploaded by ' +
                                          userprovider.userData!.name
                                                      .substring(0, 10)
                                              : 'Uploaded by ' + userprovider.userData!.name
                                          : 'Uploaded by Admin'),
                                    Consumer<SubscribeViewBookProvider>(
                                      builder: (context, subsprovider, child) { return
                                      ElevatedButton(
                                          onPressed: userprovider.userData != null &&  userprovider.userData!.name=='admin'?null:subsprovider.isSubscribed
                                              ? _unsubscribe
                                              : _subscribe,
                                          child: Text(subsprovider.isSubscribed
                                              ? 'Unsubscribe'
                                              : 'Subscribe'),
                                        );
                                      },
                                    )
                                    ]);}),
                        ],
                      ),
                    )),
              ),
      ),
    );
  }
}
