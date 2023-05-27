import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/view_book_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/global_variables.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/book.dart';
import '../providers/internetavailabilitynotifier.dart';
import '../providers/themenotifier.dart';
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
  int chunckincrement = 0;
  int endOffSet = 0;
  String dropdownValue = '1x';
  DateTime currentBackPressTime = DateTime.now();
int count=0;
  String textabc = '';

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

  Future<void> speak(String text) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1);
    await flutterTts.setSpeechRate(0.4);
    await flutterTts.speak(text);
  }

   _speak(String text) async {
    int chunkSize = 3000;
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
    flutterTts.setProgressHandler(
        (String text, int startOffset, int endOffset, String word) {
      print(
          'text: $text, startOffset: $startOffset, endOffset: $endOffset, word: $word');
      endOffSet = endOffset;
      textabc = text;
    });
    int i = 0;
    for (String chunk in chunks) {
      await flutterTts.speak(chunk);
      if (_ttsState == TtsState.paused) {
        chunckincrement = i;
        break;
      }
      if (_ttsState == TtsState.stopped) break;
      i++;
    }
  }

  Future<void> resume(text, increment, endOffSet, findtext) async {
    // int sindex = (increment * 3000) + endOffSet;
    int sindex2 = text.indexOf(findtext) + endOffSet;
    _speak(text.substring(sindex2));
    if (mounted) {
      setState(() {
        _ttsState = TtsState.playing;
      });
    }
  }

  Future<void> pause() async {
    await flutterTts.pause();
    if (mounted) {
      setState(() {
        _ttsState = TtsState.paused;
      });
    }
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

  extractTextFromPDF(Uint8List data) {
    final PdfDocument document = PdfDocument(inputBytes: data);
    // print(document.documentInformation.toString());
    String extractedText = '';
    final PdfTextExtractor extractor = PdfTextExtractor(document);
    extractedText = extractor.extractText();
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
    // document.dispose();
    return extractedText;
  }

  decryptAndConvertToText() async {
    Uint8List decryptedData = await _decryptFile();
    var texttoConvert = await extractTextFromPDF(decryptedData);
    if (mounted) {
      setState(() {
        textToConvert = texttoConvert;
      });
    }
  }

  initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.setSpeechRate(0.4);

    flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          print("Playing");
          guidemsg = "Playing...";
          _ttsState = TtsState.playing;
        });
      }
    });

    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          print("Complete");
          guidemsg = "Completed.";
          _ttsState = TtsState.stopped;
        });
      }
    });

    flutterTts.setCancelHandler(() {
      if (mounted) {
        setState(() {
          print("Cancel");
          guidemsg = "Stopped";
          _ttsState = TtsState.stopped;
        });
      }
    });

    flutterTts.setErrorHandler((message) {
      final snackBar = SnackBar(
        /// need to set following properties for best effect of awesome_snackbar_content
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,

        content: AwesomeSnackbarContent(
          title: 'Error!',
          message:
          message.toString(),

          /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
          contentType: ContentType.failure,
        ),
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
      if (mounted) {
        setState(() {
          guidemsg = "Error: $message";
          print("Error: $message");
          _ttsState = TtsState.stopped;
        });
      }
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
        if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty) ) {
          internetAvailabilityNotifier.setInternetAvailability(true);
        } else {}
      } on SocketException catch (_) {
        internetAvailabilityNotifier.setInternetAvailability(false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a delay of 100 milliseconds before executing heavy operations

      // Future.delayed(Duration(milliseconds: 100), () {
        initTts();
      // });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
    stop();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final internetAvailabilityNotifier = Provider.of<InternetNotifier>(context);
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: () async {
        navigateWithNoBack(context, ViewBookScreen(book: widget.book));
        return false;
      },
      child: SafeArea(
        child: internetAvailabilityNotifier.getInternetAvailability() == false
            ? InternetChecker()
            :  Scaffold(
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
                          children: [
                            button(),
                            DropdownButton<String>(
                              value: dropdownValue,
                              onChanged: _ttsState == TtsState.playing
                                  ? null
                                  : (String? newValue) async {
                                      if (mounted) {
                                        setState(() {
                                          dropdownValue = newValue!;
                                        });
                                      }
                                      if (newValue == '0.25x') {
                                        await flutterTts.setSpeechRate(0.105);
                                      } else if (newValue == '0.5x') {
                                        await flutterTts.setSpeechRate(0.22);
                                      } else if (newValue == '0.75x') {
                                        await flutterTts.setSpeechRate(0.315);
                                      } else if (newValue == '1x') {
                                        await flutterTts.setSpeechRate(0.4);
                                      } else if (newValue == '1.25x') {
                                        await flutterTts.setSpeechRate(0.555);
                                      } else if (newValue == '1.5x') {
                                        await flutterTts.setSpeechRate(0.71);
                                      } else if (newValue == '1.75x') {
                                        await flutterTts.setSpeechRate(0.845);
                                      } else if (newValue == '2x') {
                                        await flutterTts.setSpeechRate(1.0);
                                      }
                                    },
                              items: <String>[
                                '0.25x',
                                '0.5x',
                                '0.75x',
                                '1x',
                                '1.25x',
                                '1.5x',
                                '1.75x',
                                '2x'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            )
                          ],
                        ),
                        isLoading==true?Text('It will take some time',style:TextStyle(fontSize: 10,color: Colors.grey)):Container()
                        // Text(guidemsg)
                      ],
                    )),
                  ),
      ),
    );
  }

  Widget button() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    if (_ttsState == TtsState.stopped) {
      return isLoading==true?Text('Loading...'):ElevatedButton(
        onPressed: () async {

          if(count==0){
            if (mounted) {
              setState(() {
                isLoading = true;
              });
            }
           await decryptAndConvertToText();
            count++;
          }
          await _speak(textToConvert);
        },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(
              width: 2,
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
                  : primarycolor),
        ),
        child: Text('Play'),
      );
    } else if (_ttsState == TtsState.paused) {
      return ElevatedButton(
        onPressed: () async {
          resume(textToConvert, chunckincrement, endOffSet, textabc);
        },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(
              width: 2,
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
                  : primarycolor),
        ),
        child: Text('Resume'),
      );
    } else {
      return Column(children: [
        ElevatedButton(
          onPressed: pause,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide(
                width: 2,
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
                    : primarycolor),
          ),
          child: Text('Pause'),
        ),
        ElevatedButton(
          onPressed: stop,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide(
                width: 2,
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
                    : primarycolor),
          ),
          child: Text('Stop'),
        )
      ]);
    }
  }
}
