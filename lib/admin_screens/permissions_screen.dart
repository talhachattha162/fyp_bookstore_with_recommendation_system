import 'dart:io';

import 'package:bookstore_recommendation_system_fyp/utils/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import '../main.dart';
import '../user_screens/login_screen.dart';
import '../utils/navigation.dart';
import 'package:http/http.dart' as http;

class Permissions extends StatefulWidget {
  const Permissions({super.key});

  @override
  State<Permissions> createState() => _PermissionsState();
}

class _PermissionsState extends State<Permissions> {
  // PDFViewController? _pdfcontroller;

  static Future<File> openPDFfromNetwork(String url) async {
    final response = await http.get(Uri.parse(url));
    final bytes = response.bodyBytes;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$url');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

// Reference to the Firestore collection
  CollectionReference books = FirebaseFirestore.instance.collection('books');

// Update the name attribute of a document with a specific ID
  Future<void> updatePermission(String bookid, bool isPermitted) {
    return books
        .doc(bookid) // Reference to the document with the given ID
        .update({
          'isPermitted': isPermitted
        }) // Update the 'name' attribute with the new value
        .then((value) => print("Book permission updated successfully"))
        .catchError(
            (error) => print("Failed to update Book permission: $error"));
  }

  Future<void> deleteBook(String bookId) {
    return books
        .doc(bookId) // Reference to the document with the given ID
        .delete() // Delete the document
        .then((value) => flutterToast("Book deleted successfully"))
        .catchError((error) => print("Failed to delete book: $error"));
  }

  Stream<QuerySnapshot> bookStream =
      FirebaseFirestore.instance.collection('books').snapshots();

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text('Permissions'),
        actions: [
          IconButton(
              onPressed: () {
                navigateWithNoBack(context, MyApp());
              },
              icon: const Icon(Icons.logout)),
        ],
      ),
      body: Column(
        children: [
          Container(
              height: height * 0.7,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
              child: StreamBuilder<QuerySnapshot>(
                stream: bookStream,
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                        left: 10, bottom: 20, right: 6, top: 0),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (BuildContext context, int index) {
                      DocumentSnapshot book = snapshot.data!.docs[index];
                      return Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: width * 0.3,
                                child: Wrap(
                                  children: [
                                    Text(
                                      book['title'],
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                          child: Container(
                                              width: width * 0.9,
                                              height: height * 0.55,
                                              padding: EdgeInsets.all(8.0),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Wrap(
                                                    children: [
                                                      Text(
                                                        book['title'],
                                                      ),
                                                    ],
                                                  ),
                                                  Container(
                                                    height: height * 0.4,
                                                    width: width * 0.97,
                                                    child: CachedNetworkImage(
                                                      imageUrl: book[
                                                          'copyrightPhotoFile'],
                                                      placeholder: (context,
                                                              url) =>
                                                          Center(
                                                              child:
                                                                  new CircularProgressIndicator()),
                                                      errorWidget: (context,
                                                              url, error) =>
                                                          new Icon(Icons.error),
                                                    ),
                                                  ),
                                                  TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text('Close'))
                                                ],
                                              ))));
                                },
                                child: SizedBox(
                                    width: width * 0.15,
                                    child: Wrap(children: [
                                      Text(
                                        'Copyright Photo',
                                        style: TextStyle(fontSize: 12),
                                      )
                                    ])),
                              ),
                              TextButton(
                                  onPressed: () async {
                                    final pdf = await openPDFfromNetwork('url');
                                    showDialog(
                                        context: context,
                                        builder: (_) => Dialog(
                                            child: Container(
                                                height: height * 0.73,
                                                width: width * 0.95,
                                                padding: EdgeInsets.all(8.0),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Wrap(
                                                      children: [
                                                        Text(
                                                          book['title'],
                                                        ),
                                                      ],
                                                    ),
                                                    // Container(
                                                    //   height: height * 0.60,
                                                    //   width: width * 0.95,
                                                    //   padding:
                                                    //       EdgeInsets.symmetric(
                                                    //           horizontal:
                                                    //               width * 0.02,
                                                    //           vertical: height *
                                                    //               0.015),
                                                    //   child: PDFView(
                                                    //     // filePath: pdf,
                                                    //     // autoSpacing: false,
                                                    //     // swipeHorizontal: true,
                                                    //     // pageSnap: false,
                                                    //     // pageFling: false,
                                                    //     onRender: (pages) {},
                                                    //     onViewCreated: (controller) =>
                                                    //         setState(() =>
                                                    //             _pdfcontroller =
                                                    //                 controller),
                                                    //     onPageChanged:
                                                    //         (indexPage, _) {},
                                                    //   ),
                                                    // ),
                                                    TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child: Text('Close'))
                                                  ],
                                                ))));
                                  },
                                  child: SizedBox(
                                    width: width * 0.15,
                                    child: Wrap(children: [
                                      Text(
                                        'Check Book',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ]),
                                  )),
                              book['isPermitted'] == true
                                  ? Text('Permitted')
                                  : Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(0.0),
                                          child: IconButton(
                                              onPressed: () {
                                                updatePermission(
                                                    book['bookid'], true);
                                              },
                                              icon: Icon(Icons.check)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(0.0),
                                          child: IconButton(
                                              onPressed: () {
                                                deleteBook(book['bookid']);
                                              },
                                              icon: Icon(Icons.clear)),
                                        )
                                      ],
                                    ),
                            ],
                          ),
                          const Divider(
                            height: 5,
                            thickness: 1,
                          )
                        ],
                      );
                    },
                  );
                },
              )),
        ],
      ),
    ));
  }
}
