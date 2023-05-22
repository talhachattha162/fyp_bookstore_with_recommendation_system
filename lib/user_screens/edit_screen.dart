import 'dart:math';
import 'dart:ui';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bookstore_recommendation_system_fyp/Widgets/text_field.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/user_main_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/view_book_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/global_variables.dart';
import 'package:bookstore_recommendation_system_fyp/utils/pick_file.dart';
import 'package:bookstore_recommendation_system_fyp/utils/snackbar.dart';
import 'package:confetti/confetti.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
// import 'package:text_to_speech/text_to_speech.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';

import '../models/book.dart';
import '../providers/themenotifier.dart';
import '../utils/firebase_constants.dart';
import '../utils/fluttertoast.dart';
import '../utils/navigation.dart';

//audio Edit book option should be implemented
class EditBookScreen extends StatefulWidget {
  Book book;
   EditBookScreen({super.key, required this.book});

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final ConfettiController _controller = ConfettiController();
  bool _isConverting = false;
  String _errorMessage = '';
  RegExp year_valid = RegExp(r"\b(1\d{3}|2[0-8]\d{2}|29[0-9][0-9])\b");
  RegExp price_valid = RegExp(r"^\d+$");
  RegExp name_valid = RegExp(r"^[a-zA-Z]+(([',. -][a-zA-Z ])?[a-zA-Z]*)*$");
  RegExp tags_valid = RegExp(r"^(\d|\w)+$");
  bool isLoading = false;
  bool errortextexist = false;
  String errortext = '';
  final _formKey = GlobalKey<FormState>();
  String _filename1 = "<5 mb image allowed";
  String freeRentPaid = "free";
  bool _isvisible = false;
  Uint8List? _file1;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tag1Controller = TextEditingController();
  final TextEditingController _tag2Controller = TextEditingController();
  final TextEditingController _tag3Controller = TextEditingController();
  final TextEditingController _publishyearController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  FlutterTts flutterTts = FlutterTts();

  List<String> categories = [];

  String selectedCategory = '';
  @override
  void initState() {
    super.initState();
    getCategories();
    _titleController.text=widget.book.title;
    _tag1Controller.text=widget.book.tag1;
        _tag2Controller.text=widget.book.tag2;
        _tag3Controller.text=widget.book.tag3;
        _publishyearController.text=widget.book.publishyear;
    _priceController.text = widget.book.price.toString();
    _authorController.text=widget.book.author;
    selectedCategory=widget.book.selectedcategory;
    freeRentPaid=widget.book.freeRentPaid;
    if(freeRentPaid!="free"){
      _isvisible=true;
    }
  }

  void getCategories() {
    FirebaseFirestore.instance.collection('categories').get().then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            categories = List.castFrom<dynamic, String>(
                snapshot.docs.map((doc) => doc.get('name')).toList());
            // if (categories.isNotEmpty) {
            //   selectedCategory = categories[0];
            // }
          });
        }
      }
    });
  }

  /// saving converted audio file to firebase
  Future<String> saveToFirebase(String path, String name,
      {required String firebasPath}) async {
    final firebaseStorage = FirebaseStorage.instance;

    var snapshot =
    await firebaseStorage.ref().child(firebasPath).putFile(File(path));
    var downloadUrl = await snapshot.ref.getDownloadURL();
    print(downloadUrl + " saved url");
    return downloadUrl;
  }

  Future<String> EditFileToFirebaseStorage(
      Uint8List uint8list, String foldername) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    String filePath = '$foldername/${DateTime.now()}';
    Reference ref = storage.ref(filePath);
    try {
      String downloadURL;
      UploadTask EditTask = ref.putData(uint8list);
      await EditTask;
      downloadURL = await ref.getDownloadURL();
      return downloadURL;
    } on FirebaseException catch (e) {
      print(e);
    }
    return '';
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
    Size screenSize = MediaQuery.of(context).size;

    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return WillPopScope(
        onWillPop:  () async {
          navigateWithNoBack(context, ViewBookScreen(book: widget.book));
          return false;
        },
      child: SafeArea(
        child:  Scaffold(
          appBar: AppBar(
            title:  Text('Edit Book Details', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold)),
            automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              navigateWithNoBack(context,  ViewBookScreen(book: widget.book));
            },
          )
          ),
          resizeToAvoidBottomInset: false,
          body:AbsorbPointer(
            absorbing: isLoading,
            child: Stack(
              children: [

                SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextInputField(
                            hintText: 'Enter title',
                            suffixIcon: Text(''),
                            isPassword: false,
                            textInputType: TextInputType.text,
                            textEditingController: _titleController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter book title';
                              }
                              return null;
                            },
                          ),
                          TextInputField(
                            hintText: 'Enter Author Name',
                            suffixIcon: Text(''),
                            isPassword: false,
                            textInputType: TextInputType.name,
                            textEditingController: _authorController,
                            validator: (value) {
                              if (!name_valid.hasMatch(value)) {
                                return 'Enter valid author name';
                              }
                              if (value.length > 30) {
                                return 'The author name should be less than 30 characters';
                              }
                              return null;
                            },
                          ),
                          TextInputField(
                            hintText: 'Enter Published Year',
                            suffixIcon: Text(''),
                            isPassword: false,
                            textInputType: TextInputType.text,
                            textEditingController: _publishyearController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter publised year';
                              }
                              if (!year_valid.hasMatch(value)) {
                                return 'Enter valid year in digits';
                              }
                              return null;
                            },
                          ),
                          ButtonTheme(
                            alignedDropdown: true,
                            height: 20,
                            child: DropdownButton(
                              elevation: 50,
                              isExpanded: true,
                              iconEnabledColor: themeNotifier.getTheme() ==
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
                              value: selectedCategory == ''
                                  ? 'Select Category'
                                  : selectedCategory,
                              items: categories.isEmpty
                                  ? null
                                  : categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (mounted) {
                                  setState(() {
                                    selectedCategory = value.toString();
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: width * 0.305,
                                  child: TextInputField(
                                    hintText: 'Tag1',
                                    suffixIcon: Text(''),
                                    isPassword: false,
                                    textInputType: TextInputType.text,
                                    textEditingController: _tag1Controller,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter tag 1';
                                      }
                                      if (!tags_valid.hasMatch(value)) {
                                        return 'spaces/special \nnot allowed';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: width * 0.305,
                                  child: TextInputField(
                                    hintText: 'Tag2',
                                    suffixIcon: Text(''),
                                    isPassword: false,
                                    textInputType: TextInputType.text,
                                    textEditingController: _tag2Controller,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter tag 2';
                                      }
                                      if (!tags_valid.hasMatch(value)) {
                                        return 'spaces/special \nnot allowed';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: width * 0.305,
                                  child: TextInputField(
                                    hintText: 'Tag3',
                                    suffixIcon: Text(''),
                                    isPassword: false,
                                    textInputType: TextInputType.text,
                                    textEditingController: _tag3Controller,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter tag 3';
                                      }
                                      if (!tags_valid.hasMatch(value)) {
                                        return 'spaces/special\n not allowed';
                                      }
                                      return null;
                                    },
                                  ),
                                )
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: width * 0.305,
                                child: RadioListTile(
                                  contentPadding: const EdgeInsets.all(0.0),
                                  title: Text(
                                    "Free",
                                  ),
                                  activeColor: themeNotifier.getTheme() ==
                                      ThemeData.dark(useMaterial3: true)
                                          .copyWith(
                                        colorScheme:
                                        ColorScheme.dark().copyWith(
                                          primary: darkprimarycolor,
                                          error: Colors.red,
                                          onPrimary: darkprimarycolor,
                                          outline: darkprimarycolor,
                                          primaryVariant: darkprimarycolor,
                                          onPrimaryContainer:
                                          darkprimarycolor,
                                        ),
                                      )
                                      ? darkprimarycolor
                                      : primarycolor,
                                  selected:
                                  freeRentPaid == 'free' ? true : false,
                                  value: "free",
                                  groupValue: freeRentPaid,
                                  onChanged: (value) {
                                    if (mounted) {
                                      setState(() {
                                        freeRentPaid = value.toString();
                                        _isvisible = false;
                                      });
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                width: width * 0.305,
                                child: RadioListTile(
                                  contentPadding: const EdgeInsets.all(0.0),
                                  title: const Text(
                                    "Rent",
                                  ),
                                  activeColor: themeNotifier.getTheme() ==
                                      ThemeData.dark(useMaterial3: true)
                                          .copyWith(
                                        colorScheme:
                                        ColorScheme.dark().copyWith(
                                          primary: darkprimarycolor,
                                          error: Colors.red,
                                          onPrimary: darkprimarycolor,
                                          outline: darkprimarycolor,
                                          primaryVariant: darkprimarycolor,
                                          onPrimaryContainer:
                                          darkprimarycolor,
                                        ),
                                      )
                                      ? darkprimarycolor
                                      : primarycolor,
                                  selected:
                                  freeRentPaid == 'rent' ? true : false,
                                  value: "rent",
                                  groupValue: freeRentPaid,
                                  onChanged: (value) {
                                    if (mounted) {
                                      setState(() {
                                        freeRentPaid = value.toString();
                                        _isvisible = true;
                                      });
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                width: width * 0.305,
                                child: RadioListTile(
                                  contentPadding: const EdgeInsets.all(0.0),
                                  title: const Text(
                                    "Paid",
                                  ),
                                  activeColor: themeNotifier.getTheme() ==
                                      ThemeData.dark(useMaterial3: true)
                                          .copyWith(
                                        colorScheme:
                                        ColorScheme.dark().copyWith(
                                          primary: darkprimarycolor,
                                          error: Colors.red,
                                          onPrimary: darkprimarycolor,
                                          outline: darkprimarycolor,
                                          primaryVariant: darkprimarycolor,
                                          onPrimaryContainer:
                                          darkprimarycolor,
                                        ),
                                      )
                                      ? darkprimarycolor
                                      : primarycolor,
                                  selected:
                                  freeRentPaid == 'paid' ? true : false,
                                  value: "paid",
                                  groupValue: freeRentPaid,
                                  onChanged: (value) {
                                    if (mounted) {
                                      setState(() {
                                        freeRentPaid = value.toString();
                                        _isvisible = true;
                                      });
                                    }
                                  },
                                ),
                              )
                            ],
                          ),
                          Visibility(
                              visible: _isvisible,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: TextInputField(
                                  hintText: 'Enter Price',
                                  suffixIcon: Text(''),
                                  isPassword: false,
                                  textEditingController: _priceController,
                                  validator: (value) {
                                    if (_isvisible == true) {
                                      if (value.isEmpty) {
                                        return 'Enter valid price';
                                      }
                                      if (!price_valid.hasMatch(value)) {
                                        return 'only digits allowed';
                                      }
                                    }
                                  },
                                  textInputType: TextInputType.number,
                                ),
                              )),
                          const Text(
                            'Update Cover photo',
                            style: TextStyle(
                                fontSize: subheadingSize,
                                fontWeight: FontWeight.bold),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  PlatformFile file = await pickFile(
                                      [], FileType.image, 5000000, context);
                                  if (mounted) {
                                    setState(() {
                                      _filename1 = file.name;
                                    });
                                  }
                                  _file1 = file.bytes!;
                                } catch (err) {
                                  if (_filename1 == "<5 mb image allowed") {
                                    final snackBar = SnackBar(
                                      /// need to set following properties for best effect of awesome_snackbar_content
                                      elevation: 0,
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.transparent,

                                      content: AwesomeSnackbarContent(
                                        title: 'Error!',
                                        message:
                                        'Please reselect file',

                                        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                                        contentType: ContentType.failure,
                                      ),
                                    );

                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(snackBar);
                                  }
                                }
                              },
                              label: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.0, vertical: 12.0),
                                  child: Text('Update')),
                              icon: const Icon(Icons.upload_file),
                            ),
                          ),
                          Text(_filename1),
                          const SizedBox(
                            height: 20,
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              isLoading
                                  ? Container(
                                  child: CircularProgressIndicator())
                                  : ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate() &&
                                      selectedCategory.isNotEmpty) {
                                    setState(() {
                                      isLoading = true;
                                    });
                                    if (_filename1 ==
                                        "<5 mb image allowed") {

                                      if (categories.isNotEmpty) {
                                        CollectionReference
                                        bookCollection =
                                        firestoreInstance
                                            .collection("books");
                                        Book books;

                                        DateTime now = DateTime.now();
                                        int timestamp = now.millisecondsSinceEpoch;
                                        books = await Book(
                                            widget.book.bookid,
                                            _titleController.text,
                                            _publishyearController.text,
                                            _authorController.text,
                                            _tag1Controller.text,
                                            _tag2Controller.text,
                                            _tag3Controller.text,
                                            _priceController.text == ''
                                                ? 0
                                                : int.parse(
                                                _priceController
                                                    .text),
                                            widget.book.coverPhotoFile,
                                            widget.book.bookFile,
                                            widget.book.copyrightPhotoFile,
                                            selectedCategory,
                                            'audiobook',
                                            freeRentPaid,
                                            [],
                                            FirebaseAuth.instance
                                                .currentUser!.uid,
                                            false,Timestamp.now());

                                        try {
                                          await bookCollection
                                              .doc(widget.book.bookid)
                                              .update(books.toMap())
                                              .then((value) async {})
                                              .onError((error,
                                              stackTrace) async {
                                            final snackBar = SnackBar(
                                              /// need to set following properties for best effect of awesome_snackbar_content
                                              elevation: 0,
                                              behavior: SnackBarBehavior.floating,
                                              backgroundColor: Colors.transparent,

                                              content: AwesomeSnackbarContent(
                                                title: 'Error!',
                                                message:
                                                e.toString(),

                                                /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                                                contentType: ContentType.failure,
                                              ),
                                            );

                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(snackBar);
                                          }).then((_) {
                                            final snackBar = SnackBar(
                                              /// need to set following properties for best effect of awesome_snackbar_content
                                              elevation: 0,
                                              behavior: SnackBarBehavior.floating,
                                              backgroundColor: Colors.transparent,

                                              content: AwesomeSnackbarContent(
                                                title: 'Success!',
                                                message:
                                                'Book Updated',

                                                /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                                                contentType: ContentType.success,
                                              ),
                                            );

                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(snackBar);
                                          });
                                        } catch (e) {
    final snackBar = SnackBar(
    /// need to set following properties for best effect of awesome_snackbar_content
    elevation: 0,
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,

    content: AwesomeSnackbarContent(
    title: 'Error!',
    message:
    e.toString(),

    /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
    contentType: ContentType.failure,
    ),
    );

    ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
                                        }
                                      } else {
                                        flutterToast('No categories');
                                      }
                                    } else {

                                      if (categories.isNotEmpty) {
                                        String coverpic =
                                        await EditFileToFirebaseStorage(
                                            _file1!, 'coverpic');

                                        CollectionReference
                                        bookCollection =
                                        firestoreInstance
                                            .collection("books");
                                        String bookid =
                                            bookCollection.doc().id;
                                        Book books;

                                        DateTime now = DateTime.now();
                                        int timestamp = now.millisecondsSinceEpoch;
                                        books = await Book(
                                            widget.book.bookid,
                                            _titleController.text,
                                            _publishyearController.text,
                                            _authorController.text,
                                            _tag1Controller.text,
                                            _tag2Controller.text,
                                            _tag3Controller.text,
                                            _priceController.text == ''
                                                ? 0
                                                : int.parse(
                                                _priceController
                                                    .text),
                                            coverpic,
                                            widget.book.bookFile,
                                            widget.book.copyrightPhotoFile,
                                            selectedCategory,
                                            'audiobook',
                                            freeRentPaid,
                                            [],
                                            FirebaseAuth.instance
                                                .currentUser!.uid,
                                            false,Timestamp.now());

                                        try {
                                          await bookCollection
                                              .doc(widget.book.bookid)
                                              .update(books.toMap())
                                              .then((value) async {})
                                              .onError((error,
                                              stackTrace) async {
                                            final snackBar = SnackBar(
                                              /// need to set following properties for best effect of awesome_snackbar_content
                                              elevation: 0,
                                              behavior: SnackBarBehavior.floating,
                                              backgroundColor: Colors.transparent,

                                              content: AwesomeSnackbarContent(
                                                title: 'Error!',
                                                message:
                                                e.toString(),

                                                /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                                                contentType: ContentType.failure,
                                              ),
                                            );

                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(snackBar);
                                          }).then((_) {
    final snackBar = SnackBar(
    /// need to set following properties for best effect of awesome_snackbar_content
    elevation: 0,
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,

    content: AwesomeSnackbarContent(
    title: 'Success!',
    message:
    'Book Updated',

    /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
    contentType: ContentType.success,
    ),
    );

    ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
                                          });
                                        } catch (e) {
                                          flutterToast(e.toString());
                                        }
                                      } else {
                                        flutterToast('No categories');
                                      }
                                    }
                                    if (mounted) {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                    navigateWithNoBack(context, MainScreenUser());
                                  }
                                },
                                child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 75, vertical: 12.0),
                                    child: Text('Update Book')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if(isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ConfettiWidget(
                  confettiController: _controller,
                  blastDirection: 0.7 / 2,
                  maxBlastForce: 10,
                  minBlastForce: 1,
                  emissionFrequency: 0.08,
                  numberOfParticles: 20,
                  gravity: 0.2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
