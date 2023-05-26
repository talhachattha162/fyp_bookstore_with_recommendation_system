import 'dart:io';
import 'package:bookstore_recommendation_system_fyp/utils/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../main.dart';
import '../user_screens/login_screen.dart';
import '../utils/navigation.dart';
import 'package:http/http.dart' as http;
import '../models/notificationitem.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

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
  Future<Uint8List?> getPdfBytes(String path) async {
    try {
      HttpClient client = HttpClient();
      final Uri url = Uri.base.resolve(path);
      final HttpClientRequest request = await client.getUrl(url);
      final HttpClientResponse response = await request.close();

      return consolidateHttpClientResponseBytes(response);
    } catch (e) {
      error = 'Error fetching PDF bytes: $e';
      // handle the error here, such as showing an error message to the user
      return null;
    }
  }

// Reference to the Firestore collection
  CollectionReference books = FirebaseFirestore.instance.collection('books');
  CollectionReference payments =
      FirebaseFirestore.instance.collection('payments');
  CollectionReference reviews =
      FirebaseFirestore.instance.collection('reviews');
  CollectionReference favourities =
      FirebaseFirestore.instance.collection('favourities');
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

  deletePaymentsForBookId(String bookId) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collectionGroup('payments')
        .where('bookId', isEqualTo: bookId)
        .get();

    querySnapshot.docs.forEach((doc) {
      doc.reference.delete();
    });
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

  Future<void> deleteBook(String bookId) {
    return books
        .doc(bookId) // Reference to the document with the given ID
        .delete(); // Delete
  }

  Future<String> getName(String userId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference documentReference =
        firestore.collection('users').doc(userId);
    final DocumentSnapshot snapshot = await documentReference.get();
    final String name = snapshot.get('name');
    return name;
  }

  void subscriptionNotification(
    String booktitle,
    String bookUserId,
  ) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference subscriptionsReference =
        firestore.collection('Subscriptions');
    final QuerySnapshot subscriptionsSnapshot =
        await subscriptionsReference.get();

    for (final QueryDocumentSnapshot subscription
        in subscriptionsSnapshot.docs) {
      final String toUserId = subscription.get('ToUserId');

      if (toUserId == bookUserId) {
        final String fromUserId = subscription.get('FromUserId');
        final name = await getName(toUserId);
        final notificationMsg = '$booktitle book is uploaded by $name.';
        final notificationItem =
            NotificationItem(notificationMsg, fromUserId, Timestamp.now());

        final CollectionReference notificationsReference =
            firestore.collection('notifications');
        final Map<String, dynamic> notificationData = notificationItem.toMap();
        await notificationsReference.add(notificationData);

        print('notification:' + notificationItem.toMap().toString());
      }
    }
  }

  admitNotification(title, userid) async {
    NotificationItem item =
        NotificationItem(title + ' book is admitted', userid, Timestamp.now());
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference collectionReference =
        firestore.collection('notifications');
    await collectionReference.add(item.toMap());
    print('notification2:' + item.toMap().toString());
  }

  deleteNotification(title, userid) async {
    NotificationItem item =
        NotificationItem(title + ' book is Deleted', userid, Timestamp.now());
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference collectionReference =
        firestore.collection('notifications');
    await collectionReference.add(item.toMap());
    print('notification:' + item.toMap().toString());
  }

  Stream<QuerySnapshot> bookStream = FirebaseFirestore.instance
      .collection('books')
      .orderBy('uploadDate', descending: true)
      .snapshots();

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
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                bool isLoggedIn = false;
                prefs.setBool('isLoggedIn', isLoggedIn);
                navigateWithNoBack(context, MyApp());
              },
              icon: const Icon(Icons.logout)),
        ],
      ),
      body: Column(
        children: [
          Container(
              height: height * 0.77,
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
                                      style: TextStyle(fontSize: 11),
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
                                child: Text(
                                  'Copyright',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Column(
                                          children: [
                                            Text(book['title'],
                                                style: TextStyle(fontSize: 14)),
                                            Text(
                                                'Category:' +
                                                    book['selectedcategory'],
                                                style: TextStyle(fontSize: 12)),
                                            Text(
                                                book['freeRentPaid'] +
                                                    ' \$' +
                                                    book['price'].toString(),
                                                style: TextStyle(fontSize: 12)),
                                            Text(
                                                'Author:' +
                                                    book['author'].toString(),
                                                style: TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                        content: FutureBuilder<Uint8List?>(
                                          future: getPdfBytes(book['bookFile']),
                                          builder: (BuildContext context,
                                              AsyncSnapshot<Uint8List?>
                                                  snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            } else if (snapshot.hasError) {
                                              return Center(
                                                child: Text(
                                                    'Error fetching PDF bytes: ${snapshot.error}'),
                                              );
                                            } else if (snapshot.hasData) {
                                              return Container(
                                                height: height * 0.73,
                                                width: width * 0.95,
                                                padding: EdgeInsets.all(8.0),
                                                child: SfPdfViewer.memory(
                                                  snapshot.data!,
                                                ),
                                              );
                                            } else {
                                              return Center(
                                                child:
                                                    Text('No PDF bytes found'),
                                              );
                                            }
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
                                child: Text(
                                  'check book',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                              book['isPermitted'] == true
                                  ? IconButton(
                                      onPressed: null, icon: Icon(Icons.check))
                                  : IconButton(
                                      onPressed: () async {
                                        updatePermission(book['bookid'], true);
                                        admitNotification(
                                            book['title'], book['userid']);
                                        subscriptionNotification(
                                            book['title'], book['userid']);
                                      },
                                      icon: Icon(Icons.check)),
                              Padding(
                                padding: const EdgeInsets.all(0.0),
                                child: IconButton(
                                    onPressed: () async {
                                      deleteNotification(
                                          book['title'], book['userid']);
                                      deleteBook(book['bookid']);
                                      deleteFavouritesForBookId(book['bookid']);
                                      deletePaymentsForBookId(book['bookid']);
                                      deleteReviewsForBookId(book['bookid']);
                                    },
                                    icon: Icon(Icons.clear)),
                              )
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
