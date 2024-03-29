// import 'dart:math';
import 'dart:ui';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bookstore_recommendation_system_fyp/Widgets/text_field.dart';
import 'package:bookstore_recommendation_system_fyp/utils/global_variables.dart';
import 'package:bookstore_recommendation_system_fyp/utils/pick_file.dart';
// import 'package:bookstore_recommendation_system_fyp/utils/snackbar.dart';
import 'package:confetti/confetti.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_tts/flutter_tts.dart';
// import 'package:text_to_speech/text_to_speech.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';

import '../models/book.dart';
import '../providers/bottomnavbarnotifier.dart';
import '../providers/categoriesProvider.dart';
import '../providers/fileNamesProvider.dart';
import '../providers/freeRentPaidProvider.dart';
import '../providers/selectedCategoryProvider.dart';
import '../providers/themenotifier.dart';
import '../utils/firebase_constants.dart';
import '../utils/fluttertoast.dart';

//audio upload book option should be implemented
class UploadBookScreen extends StatefulWidget {
  const UploadBookScreen({super.key});

  @override
  State<UploadBookScreen> createState() => _UploadBookScreenState();
}

class _UploadBookScreenState extends State<UploadBookScreen> {
  final ConfettiController _controller = ConfettiController();
  // bool _isConverting = false;
  // String _errorMessage = '';
  RegExp year_valid = RegExp(r"\b(1\d{3}|2[0-8]\d{2}|29[0-9][0-9])\b");
  RegExp price_valid = RegExp(r"^\d+$");
  RegExp name_valid = RegExp(r"^[a-zA-Z]+(([',. -][a-zA-Z ])?[a-zA-Z]*)*$");
  RegExp tags_valid = RegExp(r"^(\d|\w)+$");
  RegExp endspace = RegExp(r"\s+$");

  bool isLoading = false;
  bool errortextexist = false;
  String errortext = '';
  final _formKey = GlobalKey<FormState>();

  // String freeRentPaid = "free";
  // bool _isvisible = false;
  Uint8List? _file1, _file2, _file3;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tag1Controller = TextEditingController();
  final TextEditingController _tag2Controller = TextEditingController();
  final TextEditingController _tag3Controller = TextEditingController();
  final TextEditingController _publishyearController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  FlutterTts flutterTts = FlutterTts();

  // List<String> categories = [];

  // String selectedCategory = '';
  @override
  void initState() {
    super.initState();
    Provider.of<SelectedCategoryProvider>(context,listen: false).setSelectedCategory(Provider.of<CategoryProvider>(context,listen: false).categories[0]);

    // getCategories();

  }

  // void getCategories() {
  //   FirebaseFirestore.instance.collection('categories').get().then((snapshot) {
  //     if (snapshot.docs.isNotEmpty) {
  //       if (mounted) {
  //         setState(() {
  //           categories = List.castFrom<dynamic, String>(
  //               snapshot.docs.map((doc) => doc.get('name')).toList());
  //           if (categories.isNotEmpty) {
  //             selectedCategory = categories[0];
  //           }
  //         });
  //       }
  //     }
  //   });
  // }

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

  // Future<String> uploadFileToFirebaseStorage(
  //     Uint8List uint8list, String foldername) async {
  //   FirebaseStorage storage = FirebaseStorage.instance;
  //   String filePath = '$foldername/${DateTime.now()}';
  //   Reference ref = storage.ref(filePath);
  //   try {
  //     String downloadURL;
  //     UploadTask uploadTask = ref.putData(uint8list);
  //     await uploadTask;
  //     downloadURL = await ref.getDownloadURL();
  //     return downloadURL;
  //   } on FirebaseException catch (e) {
  //     print(e);
  //   }
  //   return '';
  // }

  Future<String> uploadFileToFirebaseStorage(
    Uint8List uint8list,
    String foldername,
      int image
  ) async {
    // Compress the image using the flutter_image_compress package
    if(image==1){
      List<int> compressedData = await FlutterImageCompress.compressWithList(
        uint8list,
        quality: 4, // Set the desired quality percentage (0-100)
        format: CompressFormat.webp, // Set the desired format (jpeg, png)
      );

      FirebaseStorage storage = FirebaseStorage.instance;
      String filePath = '$foldername/${DateTime.now()}';
      Reference ref = storage.ref(filePath);
      try {
        String downloadURL;
        UploadTask uploadTask = ref.putData(Uint8List.fromList(compressedData));
        await uploadTask;
        downloadURL = await ref.getDownloadURL();
        return downloadURL;
      } on FirebaseException catch (e) {
        print(e);
      }
    }

      if(image==2){
        List<int> compressedData = await FlutterImageCompress.compressWithList(
          uint8list,
          quality: 10, // Set the desired quality percentage (0-100)
          format: CompressFormat.webp, // Set the desired format (jpeg, png)
        );

        FirebaseStorage storage = FirebaseStorage.instance;
        String filePath = '$foldername/${DateTime.now()}';
        Reference ref = storage.ref(filePath);
        try {
          String downloadURL;
          UploadTask uploadTask = ref.putData(Uint8List.fromList(compressedData));
          await uploadTask;
          downloadURL = await ref.getDownloadURL();
          return downloadURL;
        } on FirebaseException catch (e) {
          print(e);
        }
      }

    else{
      FirebaseStorage storage = FirebaseStorage.instance;
      String filePath = '$foldername/${DateTime.now()}';
      Reference ref = storage.ref(filePath);
      try {
        String downloadURL;
        UploadTask uploadTask = ref.putData(uint8list);
        await uploadTask;
        downloadURL = await ref.getDownloadURL();
        return downloadURL;
      } on FirebaseException catch (e) {
        print(e);
      }
    }



    return '';
  }

  DateTime currentBackPressTime = DateTime.now();

  Future<bool> onWillPop() async {
    final now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Press back again to exit')));
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    final rentProvider = Provider.of<FreeRentPaidProvider>(context);
    final fileNamesProvider = Provider.of<FileNamesProvider>(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    // Size screenSize = MediaQuery.of(context).size;
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final selectedCategoryProvider=Provider.of<SelectedCategoryProvider>(context);

    // double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: onWillPop,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Upload Book'),
            automaticallyImplyLeading: false,
          ),
          resizeToAvoidBottomInset: false,
          body: AbsorbPointer(
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
                            suffixIcon: const Text(''),
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
                            suffixIcon: const Text(''),
                            isPassword: false,
                            textInputType: TextInputType.name,
                            textEditingController: _authorController,
                            validator: (value) {
                              if (endspace.hasMatch(value)) {
                                return 'Dont use extra space at end';
                              }
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
                            textInputType: TextInputType.number,
                            hintText: 'Enter Published Year',
                            suffixIcon: const Text(''),
                            isPassword: false,
                            textEditingController: _publishyearController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter published year';
                              }
                              if (!year_valid.hasMatch(value)) {
                                return 'Enter valid year';
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
                                      ThemeData.dark(useMaterial3: true)
                                          .copyWith(
                                        colorScheme:
                                            const ColorScheme.dark().copyWith(
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
                              value: selectedCategoryProvider.selectedCategory == ''
                                  ? 'Select Category'
                                  : selectedCategoryProvider.selectedCategory,
                              items: categoryProvider.categories.isEmpty
                                  ? null
                                  : categoryProvider.categories.map((category) {
                                      return DropdownMenuItem(
                                        value: category,
                                        child: Text(category),

                                      );
                                    }).toList(),
                              onChanged: (value) {
                                final selectedCategoryProvider=Provider.of<SelectedCategoryProvider>(context,listen: false);

                                    selectedCategoryProvider.setSelectedCategory(value.toString()) ;

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
                                    suffixIcon: const Text(''),
                                    isPassword: false,
                                    textInputType: TextInputType.text,
                                    textEditingController: _tag1Controller,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter tag 1';
                                      }
                                      if (endspace.hasMatch(value)) {
                                        return 'space at end';
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
                                    suffixIcon: const Text(''),
                                    isPassword: false,
                                    textInputType: TextInputType.text,
                                    textEditingController: _tag2Controller,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter tag 2';
                                      }
                                      if (endspace.hasMatch(value)) {
                                        return 'space at end';
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
                                    suffixIcon: const Text(''),
                                    isPassword: false,
                                    textInputType: TextInputType.text,
                                    textEditingController: _tag3Controller,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter tag 3';
                                      }
                                      if (endspace.hasMatch(value)) {
                                        return 'space at end';
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
                                  title: const Text(
                                    "Free",
                                  ),
                                  activeColor: themeNotifier.getTheme() ==
                                          ThemeData.dark(useMaterial3: true)
                                              .copyWith(
                                            colorScheme:
                                                const ColorScheme.dark()
                                                    .copyWith(
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
                                  rentProvider.freeRentPaid == 'free' ? true : false,
                                  value: "free",
                                  groupValue: rentProvider.freeRentPaid,
                                  onChanged: (value) {
                                    final rentProvider = Provider.of<FreeRentPaidProvider>(context,listen: false);
                                        rentProvider.updateFreeRentPaid(value.toString(),false);
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
                                                const ColorScheme.dark()
                                                    .copyWith(
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
                                  rentProvider.freeRentPaid == 'rent' ? true : false,
                                  value: "rent",
                                  groupValue: rentProvider.freeRentPaid,
                                  onChanged: (value) {
                                        final rentProvider = Provider.of<FreeRentPaidProvider>(context,listen: false);
                                        rentProvider.updateFreeRentPaid(value.toString(), true);


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
                                                const ColorScheme.dark()
                                                    .copyWith(
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
                                  rentProvider.freeRentPaid == 'paid' ? true : false,
                                  value: "paid",
                                  groupValue: rentProvider.freeRentPaid,
                                  onChanged: (value) {
                                    final rentProvider = Provider.of<FreeRentPaidProvider>(context,listen: false);
                                    rentProvider.updateFreeRentPaid(value.toString(), true);

                                  },
                                ),
                              )
                            ],
                          ),
                          Visibility(
                              visible: rentProvider.isvisible,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: TextInputField(
                                  hintText: rentProvider.freeRentPaid == 'rent'
                                      ? 'Enter Price for 1 day'
                                      : 'Enter Price',
                                  suffixIcon: const Text(''),
                                  isPassword: false,
                                  textEditingController: _priceController,
                                  validator: (value) {
                                    if (rentProvider.isvisible == true) {
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
                            'Upload Cover photo',
                            style: TextStyle(
                                fontSize: subheadingSize,
                                fontWeight: FontWeight.bold),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final fileNamesProvider = Provider.of<FileNamesProvider>(context,listen: false);

                              try {
                                  PlatformFile file = await pickFile(
                                      [], FileType.image, 2000000, context);


                                      fileNamesProvider.
                                      filename1 = file.name;

                                  _file1 = file.bytes!;
                                } catch (err) {
                                  if (fileNamesProvider.filename1 == "<2 mb image allowed") {
                                    final snackBar = SnackBar(
                                      /// need to set following properties for best effect of awesome_snackbar_content
                                      elevation: 0,
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.transparent,

                                      content: AwesomeSnackbarContent(
                                        title: 'File Error!',
                                        message:
                                            '<2 mb image allowed Reselect file.',

                                        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                                        contentType: ContentType.failure,
                                      ),
                                    );

                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(snackBar);
                                    // showSnackBar(
                                    //     context, 'Please reselect file');
                                  }
                                }
                              },
                              label: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.0, vertical: 12.0),
                                  child: Text('Upload')),
                              icon: const Icon(Icons.upload_file),
                            ),
                          ),
                          Text(fileNamesProvider.filename1),
                          const SizedBox(
                            height: 10,
                          ),
                          const Text(
                            'Upload Book',
                            style: TextStyle(
                                fontSize: subheadingSize,
                                fontWeight: FontWeight.bold),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final fileNamesProvider = Provider.of<FileNamesProvider>(context,listen: false);
                                try {
                                  PlatformFile file = await pickFile(['pdf'],
                                      FileType.custom, 2000000, context);

                                      fileNamesProvider.filename2 = file.name;
                                  _file2 = file.bytes!;
                                } catch (err) {
                                  if (fileNamesProvider.filename2 == "<2 mb pdf allowed") {
                                    final snackBar = SnackBar(
                                      /// need to set following properties for best effect of awesome_snackbar_content
                                      elevation: 0,
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.transparent,

                                      content: AwesomeSnackbarContent(
                                        title: 'File Error!',
                                        message:
                                            '<2 mb image allowed Reselect file',

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
                                  child: Text('Upload')),
                              icon: const Icon(Icons.upload_file),
                            ),
                          ),
                          Text(fileNamesProvider.filename2),
                          const SizedBox(
                            height: 10,
                          ),
                          const Text(
                            'Upload Copyright photo',
                            style: TextStyle(
                                fontSize: subheadingSize,
                                fontWeight: FontWeight.bold),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final fileNamesProvider = Provider.of<FileNamesProvider>(context,listen: false);
                                try {
                                  PlatformFile file = await pickFile(
                                      [], FileType.image, 2000000, context);
                                      fileNamesProvider.filename3 = file.name;

                                  _file3 = file.bytes!;
                                } catch (err) {
                                  if (fileNamesProvider.filename3 == "<2 mb image allowed") {
                                    final snackBar = SnackBar(
                                      /// need to set following properties for best effect of awesome_snackbar_content
                                      elevation: 0,
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.transparent,

                                      content: AwesomeSnackbarContent(
                                        title: 'File Error!',
                                        message:
                                            '<2 mb image allowed Reselect file',

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
                                  child: Text('Upload')),
                              icon: const Icon(Icons.upload_file),
                            ),
                          ),
                          Text(fileNamesProvider.filename3),
                          const SizedBox(
                            height: 20,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              isLoading
                                  ? Container(
                                      child: const CircularProgressIndicator())
                                  : ElevatedButton(
                                      onPressed: () async {
                                        final selectedCategoryProvider=Provider.of<SelectedCategoryProvider>(context,listen: false);
                                        final fileNamesProvider = Provider.of<FileNamesProvider>(context,listen: false);

                                        if (_formKey.currentState!.validate() &&
                                            selectedCategoryProvider.selectedCategory.isNotEmpty) {
                                          if (fileNamesProvider.filename1 ==
                                                  "<2 mb image allowed" ||
                                              fileNamesProvider.filename2 ==
                                                  "<2 mb pdf allowed" ||
                                              fileNamesProvider.filename3 ==
                                                  "<2 mb image allowed") {
                                            final snackBar = SnackBar(
                                              /// need to set following properties for best effect of awesome_snackbar_content
                                              elevation: 0,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor:
                                                  Colors.transparent,

                                              content: AwesomeSnackbarContent(
                                                title: 'Error!',
                                                message: 'Please upload file.',

                                                /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                                                contentType:
                                                    ContentType.failure,
                                              ),
                                            );

                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(snackBar);
                                          } else {
                                            // _convertTextToSpeech();
                                            // createAudioScript(); if (mounted) {

                                            setState(() {
                                              isLoading = true;
                                            });
                                            if (categoryProvider.categories.isNotEmpty) {
                                              final state = context.read<
                                                  BottomNavigationBarState>();
                                              final rentProvider = Provider.of<FreeRentPaidProvider>(context,listen: false);
                                              state.setEnabled(false);
                                              String coverpic =
                                                  await uploadFileToFirebaseStorage(
                                                      _file1!, 'coverpic',1);
                                              String book =
                                                  await uploadFileToFirebaseStorage(
                                                      _file2!, 'book',0);
                                              String copyrightpic =
                                                  await uploadFileToFirebaseStorage(
                                                      _file3!, 'copyrightpic',2);
                                              // textToSpeech();
                                              // createAudioScript();
                                              // _showResult(text);
                                              // await createAudioScript(text);

                                              CollectionReference
                                                  bookCollection =
                                                  firestoreInstance
                                                      .collection("books");
                                              String bookid =
                                                  bookCollection.doc().id;
                                              Book books;
                                              if (FirebaseAuth
                                                      .instance.currentUser ==
                                                  null) {
                                                // DateTime now = DateTime.now();
                                                // int timestamp = now
                                                //     .millisecondsSinceEpoch;
                                                books = await Book(
                                                    bookid,
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
                                                    book,
                                                    copyrightpic,
                                                    selectedCategoryProvider.selectedCategory,
                                                    'audiobook',
                                                    rentProvider.freeRentPaid,
                                                    [],
                                                    'admin',
                                                    false,
                                                    Timestamp.now());
                                              } else {
                                                // DateTime now = DateTime.now();
                                                // int timestamp = now
                                                //     .millisecondsSinceEpoch;
                                                books = await Book(
                                                    bookid,
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
                                                    book,
                                                    copyrightpic,
                                                    selectedCategoryProvider.selectedCategory,
                                                    'audiobook',
                                                    rentProvider.freeRentPaid,
                                                    [],
                                                    FirebaseAuth.instance
                                                        .currentUser!.uid,
                                                    false,
                                                    Timestamp.now());
                                              }
                                              try {
                                                await bookCollection
                                                    .doc(bookid)
                                                    .set(books.toMap())
                                                    .then((value) async {})
                                                    .onError((error,
                                                        stackTrace) async {
                                                  flutterToast('Error: Retry');
                                                }).then((_) {
                                                  _controller.play();
                                                  Timer(
                                                      const Duration(
                                                          seconds: 2), () {
                                                    _controller.stop();
                                                  });

                                                  // flutterToast('Book Added');
                                                });
                                              } catch (e) {
                                                flutterToast(e.toString());
                                              }
                                            } else {
                                              flutterToast('No categories');
                                            }
                                            // fileNamesProvider.filename1 == "<2 mb image allowed";
                                            // fileNamesProvider.filename2 == "<2 mb image allowed";
                                            // fileNamesProvider.filename3 == "<2 mb image allowed";
                                            _titleController.clear();
                                            _tag1Controller.clear();
                                            _tag2Controller.clear();
                                            _tag3Controller.clear();
                                            _publishyearController.clear();
                                            _priceController.clear();
                                            _authorController.clear();
                                            _categoryController.clear();
                                            fileNamesProvider.filename1 = "<2 mb image allowed";
                                            fileNamesProvider.filename2 = "<2 mb pdf allowed";
                                            fileNamesProvider.filename3 = "<2 mb image allowed";
                                            rentProvider.updateFreeRentPaid('free', false);
                                            _file1 = null;
                                            _file2 = null;
                                            _file3 = null;
                                            if (mounted) {
                                              final state = context.read<
                                                  BottomNavigationBarState>();
                                              state.setEnabled(true);
                                              setState(() {
                                                isLoading = false;
                                              });
                                            }
                                          }
                                        }
                                      },
                                      child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 75, vertical: 12.0),
                                          child: Text('Upload Book')),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: const Center(
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
                  numberOfParticles: 30,
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
