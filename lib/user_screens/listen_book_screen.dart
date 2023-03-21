import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bookstore_recommendation_system_fyp/user_screens/view_book_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/global_variables.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/book.dart';
import '../providers/internetavailabilitynotifier.dart';
import '../utils/InternetChecker.dart';
import '../utils/navigation.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class ListenBookScreen extends StatefulWidget {
  var bookpath;
  Book book;
  ListenBookScreen({
    super.key,
    required this.book,
    required this.bookpath,
  });

  @override
  State<ListenBookScreen> createState() => _ListenBookScreenState();
}

enum TtsState { playing, stopped, paused, continued }

class _ListenBookScreenState extends State<ListenBookScreen> {
  TtsState _ttsState = TtsState.stopped;
  int textInc = 0;
  var textToConvert;
  double currentduration = 0;
  Duration? duration = Duration(hours: 0);
  Timer? timer;
  bool isLoading = false;
  FlutterTts flutterTts = FlutterTts();
  var guidemsg = '';
  bool _isSpeaking = false;

  bool _isPaused = false;


 DateTime currentBackPressTime = DateTime.now();


   Future<bool> onWillPop() async {
    final now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Press back again to exit')));
      return Future.value(false);
    }
    return Future.value(true);
  }


  Future<void> speak(String text) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1);
    await flutterTts.setSpeechRate(0.4);
    await flutterTts.speak(text);
    if (mounted) {
      setState(() {
        _isSpeaking = true;
        _isPaused = false;
      });
    }
  }



  void _speak(String text) async {
    int chunkSize = 1000;
    List<String> chunks = [];
    while (text.isNotEmpty) {
      if (text.length > chunkSize) {
        chunks.add(text.substring(0, chunkSize));
        text = text.substring(chunkSize);
      } else {
        chunks.add(text);
        text = "";
      }
    }

    for (String chunk in chunks) {
      await flutterTts.speak(chunk);
      if (_ttsState == TtsState.stopped) break;
    }
  }

  Future<void> pause() async {
    await flutterTts.pause();
    setState(() {
      _isPaused = true;
    });
  }

  Future stop() async {
    await flutterTts.stop();
    if (mounted) {
      setState(() {
        _ttsState = TtsState.stopped;
      });
    }
  }

  double parseDurationFromDouble(Duration hours) {
    return hours.inSeconds.toDouble();
  }

  Future<Uint8List> _decryptFile() async {
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

    // Return decrypted PDF data as Uint8List
    return Uint8List.fromList(decryptedPdfData);
  }

  extractTextFromPDF(Uint8List data) async {
    final PdfDocument document = await PdfDocument(inputBytes: data);
    // print(document.documentInformation.toString());
    String extractedText = '';
    final PdfTextExtractor extractor = await PdfTextExtractor(document);
    extractedText = await extractor.extractText();
    // document.dispose();
    return extractedText;
  }

  decryptAndConvertToText() async {
    setState(() {
      isLoading = true;
    });
    Uint8List decryptedData = await _decryptFile();
    var texttoConvert = await extractTextFromPDF(decryptedData);
    setState(() {
      textToConvert = texttoConvert;
      isLoading = false;
    });
  }

  initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.awaitSpeakCompletion(true);

    flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        guidemsg = "Playing...";
        _ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        guidemsg = "Completed.";
        _ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        guidemsg = "Stopped";
        _ttsState = TtsState.stopped;
      });
    });

    flutterTts.setErrorHandler((message) {
      setState(() {
        guidemsg = "Error: $message";
        print("Error: $message");
        _ttsState = TtsState.stopped;
      });
    });
  }

  @override
  void initState() {
    super.initState();
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
    initTts();
    decryptAndConvertToText();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
    stop();
  }

  @override
  Widget build(BuildContext context) {
    final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context);
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop:onWillPop,
      child: SafeArea(
        child: internetAvailabilityNotifier.getInternetAvailability() == false
            ? InternetChecker()
            : isLoading == true
                ? Scaffold(
                    body: Center(
                        child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Text('Please wait'),
                      // Text('Loading...'),
                      CircularProgressIndicator.adaptive()
                    ],
                  )))
                : Scaffold(
                    appBar: AppBar(
                        title: const Text('Listen Book'),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            stop();
                            navigateWithNoBack(
                                context,
                                ViewBookScreen(
                                  book: widget.book,
                                ));
                          },
                        )),
                    body: SingleChildScrollView(
                        child: Column(
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
                              // widthFactor: 0.9,
                              // heightFactor: 0.55,
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
                        Text(widget.book.author),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          widget.book.title,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [button()],
                        ),
                        Text(guidemsg)
                      ],
                    )),
                  ),
      ),
    );
  }

  Widget button() {
    if (_ttsState == TtsState.stopped) {
      return ElevatedButton(
        onPressed: () async {
          _speak(textToConvert);
        },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(width: 2, color: primarycolor),
        ),
        child: Text('Play'),
      );
    } else {
      return ElevatedButton(
        onPressed: stop,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(width: 2, color: primarycolor),
        ),
        child: Text('Stop'),
      );
    }
  }
}
