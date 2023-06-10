// import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/notification_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/view_book_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/global_variables.dart';
import 'package:bookstore_recommendation_system_fyp/utils/navigation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../providers/bookListProvider.dart';
import '../providers/categoriesProvider.dart';
import '../providers/notificationLengthProvider.dart';
import '../providers/tagProvider.dart';
import '../providers/themenotifier.dart';
// import 'booksearchscreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // int tag = 0;
  // List<String> categories = [];
  List<String> options = ['loading'];

  // List<Book> books = [];

  List<String> titles = [];
  List<String> searchData = [];

  // int notificationLength = 0;

  intialize() {
    final bookListProvider = Provider.of<BookListProvider>(context,listen: false);


    titles = bookListProvider.books.map((book) {
      return book.title;
    }).toList();
    searchData.addAll(titles);
    searchData=searchData.toSet().toList();
  }

  void getBooks() {
    FirebaseFirestore.instance
        .collection('books')
        .where('isPermitted', isEqualTo: true)
        .get()
        .then((snapshot) {
      List<Book> bookList = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return Book.fromMap(data);
      }).toList();
      final bookListProvider = Provider.of<BookListProvider>(context,listen: false);
        bookListProvider.addBooks(bookList);
        // books.addAll(bookListProvider.books);
          intialize();
    });
  }

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a delay of 100 milliseconds before executing heavy operations
// print(FirebaseAuth.instance.currentUser);
      // Future.delayed(Duration(milliseconds: 100), () {
      getCategories();
      getBooks();
      _fetchNotifications();

      // });
    // });

    // print('homeinit');
  }

  Stream<List<Book>> getBooksByCategory(String category) {
    return FirebaseFirestore.instance
        .collection('books')
        .where('category', isEqualTo: category)
        .where('isPermitted', isEqualTo: true)
        .snapshots()
        .map((snapshot) => List<Book>.from(
            snapshot.docs.map((doc) => Book.fromMap(doc.data()))));
  }

  Stream<QuerySnapshot> _queryBooksByCategory(String category) {
    return FirebaseFirestore.instance
        .collection('books')
        .where('selectedcategory', isEqualTo: category)
        .where('isPermitted', isEqualTo: true)
        .snapshots();
  }

  void getCategories() {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    FirebaseFirestore.instance.collection('categories').get().then((snapshot) {
      final newCategories = List<String>.from(
          snapshot.docs.map((doc) => doc.get('name')).toList());

      categoryProvider.clearCategories(); // Clear existing categories
      categoryProvider.addCategories(newCategories);
    });
  }


  DateTime currentBackPressTime = DateTime.now();

  Future<bool> onWillPop() async {
    final now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Press back again to exit')));
      return Future.value(false);
    }
    return Future.value(true);
  }

  void _fetchNotifications() async {
    final usersCollection = FirebaseFirestore.instance.collection('users');
    final notificationsCollection =
        FirebaseFirestore.instance.collection('notifications');

    notificationsCollection
        .where('forUserId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .listen((snapshots) {
      usersCollection
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get()
          .then((doc) {
        final notificationAttribute = doc['notifications'] ?? 0;

            final notificationProvider = Provider.of<NotificationLengthProvider>(context,listen: false);

            notificationProvider.setNotificationLength((snapshots.docs.length - notificationAttribute).toInt());


      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // print('home');
    double height = MediaQuery.of(context).size.height;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final orientation = MediaQuery.of(context).orientation;
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final notificationProvider = Provider.of<NotificationLengthProvider>(context);
    final tagProvider = Provider.of<TagProvider>(context);
// print(categoryProvider.categories);

    // _fetchNotifications(context);
    return WillPopScope(
      onWillPop: onWillPop,
      child: SafeArea(
        child: Scaffold(
          appBar:  AppBar(
              title: Text('BookStore'),
            // title: Align(
            //     alignment: Alignment.topLeft,
            //   child: TextLiquidFill(loadDuration: const Duration(seconds: 2),
            //     boxBackgroundColor: themeNotifier.getTheme() ==
            //         ThemeData.dark(useMaterial3: true)
            //             .copyWith(
            //           colorScheme:
            //           const ColorScheme.dark().copyWith(
            //             primary: darkprimarycolor,
            //             error: Colors.red,
            //             onPrimary: darkprimarycolor,
            //             outline: darkprimarycolor,
            //             primaryVariant: darkprimarycolor,
            //             onPrimaryContainer:
            //             darkprimarycolor,
            //           ),
            //         )
            //         ? Colors.black
            //         : Colors.green.shade300,
            //     text:  'Book Store',
            //     waveColor: Colors.white,
            //     textStyle: const TextStyle(
            //       fontSize: 24.0,
            //       fontWeight: FontWeight.bold,
            //       color: Colors.white,
            //     ),
            //     textAlign: TextAlign.center,
            //     // boxHeight: 50.0,
            //   ),
            // ),
    
    
            automaticallyImplyLeading: false,
            actions: [
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      navigateWithNoBack(context, const NotificationScreen());
                    },
                    icon: const Icon(Icons.notifications),
                  ),
                  Positioned(
                    top: 22.0,
                    right: 5.0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      child: Text(
                        notificationProvider.notificationLength.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  // method to show the search bar
                  // navigateWithNoBack(context, BookSearchScreen());
                  final bookListProvider = Provider.of<BookListProvider>(context,listen:false);

                  showSearch(
                      context: context,
                      // delegate to customize the search bar
                      delegate: CustomSearchDelegate(
                          searchData: searchData, books: bookListProvider.books));
                },
                icon: const Icon(CupertinoIcons.search),
              ),
            ],
          ),
          resizeToAvoidBottomInset: false,
          body: SingleChildScrollView(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: ChipsChoice<int>.single(
                          key: ValueKey(tagProvider.tag),
                          value: tagProvider.tag,
                          onChanged: (val) {
                                tagProvider.setTag(val) ;

                          },
                          choiceItems: categoryProvider.categories.isEmpty
                              ? C2Choice.listFrom<int, String>(
                                  source: options,
                                  value: (i, v) => i,
                                  label: (i, v) => v,
                                )
                              : C2Choice.listFrom<int, String>(
                                  source: categoryProvider.categories,
                                  value: (i, v) => i,
                                  label: (i, v) => v,
                                ),
                        ),
                      )
                    ]),
                  ),
                  Padding(
                    padding:  EdgeInsets.symmetric(horizontal:orientation == Orientation.portrait?8:25.0,vertical:orientation == Orientation.portrait?2:8.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: height * 0.73,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _queryBooksByCategory(
                            categoryProvider.categories.isEmpty ? ' ' : categoryProvider.categories[tagProvider.tag]),
                        builder: (BuildContext context,
                            AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }
    
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                                child: LoadingAnimationWidget.fourRotatingDots(
                              color: themeNotifier.getTheme() ==
                                      ThemeData.dark(useMaterial3: true).copyWith(
                                        colorScheme: const ColorScheme.dark().copyWith(
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
                            ));
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Visibility(
                                visible: true,
                                child: Text('No books found'),
                              ),
                            );
                          }
                          return
                              GridView.builder(

                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: orientation == Orientation.portrait?2:4,
                                        crossAxisSpacing: 6,
                                        mainAxisSpacing: 6,
                                        mainAxisExtent: 230),
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  Book book = Book.fromSnapshot(
                                      snapshot.data!.docs[index]);
                                  return InkWell(
                                      key: ValueKey(book.bookid),
                                    onTap: () {
                                      navigateWithNoBack(
                                          context, ViewBookScreen(book: book));
                                    },
                                    child: Card(
                                      elevation: 10,
                                      borderOnForeground: true,
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Column(
                                          children: [
                                            CachedNetworkImage(
                                              height: 170,
                                              width: double.infinity,
                                              fit: BoxFit.fill,
                                              imageUrl: book.coverPhotoFile,
                                              placeholder: (context, url) => const Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                              errorWidget:
                                                  (context, url, error) =>
                                                  const  Icon(Icons.error),
                                            ),
                                            SizedBox(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(4.0),
                                                child: Row(
                                                  children: [
                                                    Flexible(
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            book.title.length > 15
                                                                ? book.title
                                                                        .substring(
                                                                            0,
                                                                            15) +
                                                                    '...'
                                                                : book.title,
                                                            style: const TextStyle(
                                                                fontSize: 12),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    // SizedBox(
                                                    //   width: 30,
                                                    // ),
                                                    Text(
                                                      book.freeRentPaid == 'free'
                                                          ? 'Free'
                                                          : '\$' +
                                                              book.price
                                                                  .toString(),
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                        },
                      ),
    
                      //stack
                    ),
                  )
                ]
                //   },
                // ),
                ),
          ),
        ),
      ),
    );
    // );
  }
}

class CustomSearchDelegate extends SearchDelegate {
  final List<String> searchData;
  final List<Book> books;

  CustomSearchDelegate({required this.searchData, required this.books});

// first overwrite to
// clear the search text
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon:const Icon(CupertinoIcons.clear),
      ),
    ];
  }

// second overwrite to pop out of search menu
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon:const Icon(Icons.arrow_back),
    );
  }

// third overwrite to show query result
  @override
  Widget buildResults(BuildContext context) {
    List<String> matchQuery = [];
    for (var categories in searchData) {
      if (categories.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(categories);
      }
    }
    if (query.toLowerCase() == '') {
      return  Container();
    } else {
      return ListView.builder(
        itemCount: matchQuery.length,
        itemBuilder: (context, index) {
          var result = matchQuery[index];

          if (result.isNotEmpty) {
            return InkWell(
              onTap: () {
                for (var book in books) {
                  if (book.title == result) {
                    navigateWithNoBack(context, ViewBookScreen(book: book));
                  }
                }
              },
              child: ListTile(
                title: Text(result),
              ),
            );
          } else {
            return const  Center(
              child: Text('No book found'),
            );
          }
        },
      );
    }
  }

// last overwrite to show the
// querying process at the runtime
  @override
  Widget buildSuggestions(BuildContext context) {
    List<String> matchQuery = [];
    for (var categories in searchData) {
      if (categories.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(categories);
      }
    }
    if (query.toLowerCase() == '') {
      return Container();
    } else {
      return ListView.builder(
        itemCount: matchQuery.length,
        itemBuilder: (context, index) {
          var result = matchQuery[index];
          if (result.isNotEmpty) {
            return InkWell(
              onTap: () {
                for (var book in books) {
                  if (book.title == result) {
                    navigateWithNoBack(context, ViewBookScreen(book: book));
                  }
                }
              },
              child: ListTile(
                title: Text(result),
              ),
            );
          } else {
            return const Center(
              child: Text('No Book found'),
            );
          }
        },
      );
    }
  }
}
