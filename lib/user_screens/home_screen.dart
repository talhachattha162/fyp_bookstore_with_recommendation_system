import 'package:bookstore_recommendation_system_fyp/user_screens/view_book_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/global_variables.dart';
import 'package:bookstore_recommendation_system_fyp/utils/navigation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../providers/themenotifier.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tag = 0;
  List<String> categories = [];
  List<String> options = ['loading'];

  List<Book> books = [];

  List<String> titles = [];
  List<String> searchData = [];

  intialize() {
    titles = books.map((book) {
      return book.title;
    }).toList();
    searchData.addAll(titles);
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
      if (mounted) {
        setState(() {
          books.addAll(bookList);
          intialize();
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getCategories();
    getBooks();
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
    FirebaseFirestore.instance.collection('categories').get().then((snapshot) {
      if (mounted) {
        setState(() {
          categories = List.castFrom<dynamic, String>(
              snapshot.docs.map((doc) => doc.get('name')).toList());
        });
      }
    });
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
    // print('home');
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    double height = MediaQuery.of(context).size.height;
    return
        // MultiProvider(
        //   providers: [
        //     ChangeNotifierProvider<BooksProvider>(
        //         create: (_) => BooksProvider()
        //           ..fetchBooks(categories.isNotEmpty ? categories[tag] : ' '))
        //   ],
        //   child:
        WillPopScope(
      onWillPop: onWillPop,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Book Store'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                  onPressed: () {
                    themeNotifier.setTheme(themeNotifier.getTheme() ==
                            ThemeData(
                                // useMaterial3: true,
                                appBarTheme:
                                    AppBarTheme(color: Colors.green[300]),
                                primarySwatch: primarycolor,
                                fontFamily: 'RobotoMono')
                        ? ThemeData.dark(useMaterial3: true).copyWith(
                            colorScheme: ColorScheme.dark().copyWith(
                              primary: darkprimarycolor,
                              error: Colors.red,
                              onPrimary: darkprimarycolor,
                              outline: darkprimarycolor,
                              primaryVariant: darkprimarycolor,
                              onPrimaryContainer: darkprimarycolor,
                            ),
                          )
                        : ThemeData(
                            appBarTheme: AppBarTheme(color: Colors.green[300]),
                            primarySwatch: primarycolor,
                            fontFamily: 'RobotoMono'));
                  },
                  icon: const Icon(CupertinoIcons.moon)),
              IconButton(
                onPressed: () {
                  // method to show the search bar
                  showSearch(
                      context: context,
                      // delegate to customize the search bar
                      delegate: CustomSearchDelegate(
                          searchData: searchData, books: books));
                },
                icon: const Icon(CupertinoIcons.search),
              )
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
                          value: tag,
                          onChanged: (val) {
                            setState(() {
                              tag = val;
                            });
                          },
                          choiceItems: categories.isEmpty
                              ? C2Choice.listFrom<int, String>(
                                  source: options,
                                  value: (i, v) => i,
                                  label: (i, v) => v,
                                )
                              : C2Choice.listFrom<int, String>(
                                  source: categories,
                                  value: (i, v) => i,
                                  label: (i, v) => v,
                                ),
                        ),
                      )
                    ]),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: height * 0.73,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _queryBooksByCategory(
                          categories.isEmpty ? ' ' : categories[tag]),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: Text('Loading...'));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return  Center(
        child: Visibility(
          visible: true,
          child: Text('No books found'),
        ),
      );
                        }
                        return Stack(
                          children: [
                            GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 6,
                                      mainAxisSpacing: 6,
                                      mainAxisExtent: 230),
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                Book book = Book.fromSnapshot(
                                    snapshot.data!.docs[index]);
                                return InkWell(
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
                                            placeholder: (context, url) => Center(
                                                child:
                                                    CircularProgressIndicator()),
                                            errorWidget:
                                                (context, url, error) =>
                                                    new Icon(Icons.error),
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
                                                          book.title.length > 20
                                                              ? book.title
                                                                      .substring(
                                                                          0,
                                                                          20) +
                                                                  '...'
                                                              : book.title,
                                                          style: TextStyle(
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
                                                    style: TextStyle(
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
                            ),
                          ],
                        );
                      },
                    ),

                    //stack
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
        icon: Icon(CupertinoIcons.clear),
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
      icon: Icon(Icons.arrow_back),
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
            return Center(
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
            return Center(
              child: Text('No Book found'),
            );
          }
        },
      );
    }
  }
}
