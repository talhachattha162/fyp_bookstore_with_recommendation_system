import 'dart:async';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:bookstore_recommendation_system_fyp/utils/global_variables.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/book.dart';
import '../providers/internetavailabilitynotifier.dart';
import '../providers/themenotifier.dart';
import '../utils/InternetChecker.dart';
import '../utils/navigation.dart';
import 'view_book_screen.dart';

class BookPdfScreen extends StatefulWidget {
  Book book;
  var bookpath;
  BookPdfScreen({
    super.key,
    required this.book,
    required this.bookpath,
  });

  @override
  State<BookPdfScreen> createState() => _BookPdfScreenState();
}

class _BookPdfScreenState extends State<BookPdfScreen> {
  Timer? timer;

  String _pdfPath = '';

  Future<void> _decryptFile() async {
    // Read encrypted PDF file from storage
    String path = await widget.bookpath;
    final encryptedFile = File(path);
    final encryptedPdfData = await encryptedFile.readAsBytes();

    // Decrypt PDF file
    final key = encrypt.Key.fromLength(32);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decryptedPdfData = encrypter.decryptBytes(
      encrypt.Encrypted(encryptedPdfData),
      iv: iv,
    );

    // Store decrypted PDF file in cache directory
    final tempDir = await getTemporaryDirectory();
    final tempPdfFile = File('${tempDir.path}/decrypted.pdf');
    await tempPdfFile.writeAsBytes(decryptedPdfData);
    if (mounted) {
      setState(() {
        _pdfPath = tempPdfFile.path;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _decryptFile();

    timer = Timer.periodic(Duration(seconds: 1), (Timer t) async {
      final internetAvailabilityNotifier =
          Provider.of<InternetNotifier>(context, listen: false);
      try {
        final result = await InternetAddress.lookup('google.com');
        if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty)) {
          internetAvailabilityNotifier.setInternetAvailability(true);
        } else {}
      } on SocketException catch (_) {
        internetAvailabilityNotifier.setInternetAvailability(false);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context);
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;
    return WillPopScope(
      onWillPop:  () async {
        navigateWithNoBack(context, ViewBookScreen(book: widget.book));
        return false;
      },
      child: SafeArea(
          child: internetAvailabilityNotifier.getInternetAvailability() == true
              ? Scaffold(
                  // appBar: AppBar(
                  //     title: const Text('Read Book'),
                  //     leading: IconButton(
                  //       icon: const Icon(Icons.arrow_back),
                  //       onPressed: () {
                  //         navigateWithNoBack(
                  //             context,
                  //             ViewBookScreen(
                  //               book: widget.book,
                  //             ));
                  //       },
                  //     )
            //     ),
                  body: Center(
                    child: Stack(
                      children: [
                        Container(
                          width:orientation == Orientation.portrait?double.infinity:600,
                          height: double.infinity,
                          // padding: EdgeInsets.symmetric(
                          //     horizontal: width * 0.05, vertical: height * 0.015),
                          child: _pdfPath.isNotEmpty
                              ? SfPdfViewer.file(File(_pdfPath),)
                              : Center(
                                  child: LoadingAnimationWidget.fourRotatingDots(
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
                                )
                                  // Text('Loading...')
                                  ),
                        ),
                        // SizedBox(height:orientation == Orientation.portrait?5:0),
                        // orientation == Orientation.portrait?Text(
                        //   '${widget.book.title}',
                        //   style: TextStyle(
                        //     fontSize: 18,
                        //   ),
                        // ):Container(),
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            navigateWithNoBack(
                                context,
                                ViewBookScreen(
                                  book: widget.book,
                                ));
                          },
                        ),
                      ],
                    ),
                  ),
                )
              : InternetChecker()),
    );
  }
}
