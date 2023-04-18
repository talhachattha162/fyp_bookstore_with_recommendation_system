import 'dart:io';
import 'package:bookstore_recommendation_system_fyp/utils/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../main.dart';
import '../user_screens/login_screen.dart';
import '../utils/navigation.dart';
import 'package:http/http.dart' as http;

import 'package:encrypt/encrypt.dart' as encrypt;

class Permissions extends StatefulWidget {
  const Permissions({super.key});

  @override
  State<Permissions> createState() => _PermissionsState();
}

class _PermissionsState extends State<Permissions> {
  Uint8List? _documentBytes;
  @override
  void initState() {
    super.initState();
  }

  String error = '';
  void getPdfBytes(String path) async {
    try {
      HttpClient client = HttpClient();
      final Uri url = Uri.base.resolve(path);
      final HttpClientRequest request = await client.getUrl(url);
      final HttpClientResponse response = await request.close();
      _documentBytes = await consolidateHttpClientResponseBytes(response);
      setState(() {});
    } catch (e) {
      error = 'Error fetching PDF bytes: $e';
      // handle the error here, such as showing an error message to the user
    }
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

  viewPdf(bookid) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String encryptedPath = '${appDocDir.path}/encrypted';
    String path = '$encryptedPath/' + bookid + '.pdf';
    final encryptedFile = File(path);
    final encryptedPdfData = await encryptedFile.readAsBytes();
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
    return tempPdfFile.path;
  }

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
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(book['title']),
                                        content: Builder(
                                          builder: (BuildContext context) {
                                            return Container(
                                                width: width * 1,
                                                height: height * 0.5,
                                                padding: EdgeInsets.all(4.0),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      height: height * 0.4,
                                                      width: width * 1,
                                                      child: InteractiveViewer(
                                                        child:
                                                            CachedNetworkImage(
                                                          fit: BoxFit.contain,
                                                          imageUrl: book[
                                                              'copyrightPhotoFile'],
                                                          placeholder: (context,
                                                                  url) =>
                                                              Center(
                                                                  child:
                                                                      new CircularProgressIndicator()),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              new Icon(
                                                                  Icons.error),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ));
                                          },
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(
                                                  context); // close the dialog
                                            },
                                            child: Text('Close'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Text('Copyright'),
                              ),
                              TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(book['title']),
                                        content: Builder(
                                          builder: (BuildContext context) {
                                            getPdfBytes(book['bookFile']);
                                            Widget child1 = error == ''
                                                ? Center(
                                                    child: Text(error),
                                                  )
                                                : Center(
                                                    child:
                                                        CircularProgressIndicator());
                                            if (_documentBytes != null) {
                                              child1 = Container(
                                                  height: height * 0.73,
                                                  width: width * 0.95,
                                                  padding: EdgeInsets.all(8.0),
                                                  child: SfPdfViewer.memory(
                                                    _documentBytes!,
                                                  ));
                                            }
                                            return child1;
                                          },
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(
                                                  context); // close the dialog
                                            },
                                            child: Text('Close'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Text('check book'),
                              ),
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
