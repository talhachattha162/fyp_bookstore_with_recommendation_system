import 'package:bookstore_recommendation_system_fyp/user_screens/view_book_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/loadingProvider.dart';
import '../providers/themenotifier.dart';
import '../providers/trendingProvider.dart';
import '../utils/global_variables.dart';
import '../utils/navigation.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  DateTime currentBackPressTime = DateTime.now();

  bool isLoading=false;

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
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      await _fetchTrendingBookIds();
    });
  }

  Stream<List<Book>?> _bookStream() {
    final trendingProvider = Provider.of<TrendingProvider>(context,listen:false);
    final collection = FirebaseFirestore.instance.collection('books');

    return collection
        .where(FieldPath.documentId, whereIn: trendingProvider.trendingBookIds)
        .snapshots()
        .map((snapshot) => snapshot.docs.isEmpty
            ? null
            : snapshot.docs.map((doc) => Book.fromSnapshot(doc)).toList());
  }

  // List<String> _trendingBookIds = [];
  Future<void> _fetchTrendingBookIds() async {
    // final loadingProvider = Provider.of<LoadingProvider>(context,listen: false);
    // loadingProvider.setLoading(true);
    setState(() {
      isLoading=true;
    });
    try {
      final response = await http
          .get(Uri.parse('http://tayyab162.pythonanywhere.com/trending-books'));
      if (response.statusCode == 200) {
        final List<dynamic> bookIds = json.decode(response.body);

            final trendingProvider = Provider.of<TrendingProvider>(context,listen: false);
        trendingProvider.setTrendingBookIds(bookIds.cast<String>());

      } else {
        flutterToast('Failed to retrieve trending book Retry');
      }
    } catch (e) {
      flutterToast('Failed to retrieve trending book Retry');
    }
setState(() {
  isLoading=false;
});
  }

  // bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    // final loadingProvider = Provider.of<LoadingProvider>(context);
    // double height = MediaQuery.of(context).size.height;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final trendingProvider = Provider.of<TrendingProvider>(context);

    final orientation = MediaQuery.of(context).orientation;
    return WillPopScope(
      onWillPop: onWillPop,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title:  const Text('Trendings'),
            automaticallyImplyLeading: false,
          ),
          resizeToAvoidBottomInset: false,
          body: isLoading
              ? Center(
                  child: Visibility(
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
                  ),
                  visible: true,
                ))
              : trendingProvider.trendingBookIds.isEmpty
                  ? Center(child: Text('No trendings found'))
                  : StreamBuilder<List<Book>?>(
                      stream: _bookStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Error fetching books'));
                        }
    
                        if (!snapshot.hasData) {
                          return Center(child: Text('Loading...'));
                        }
                        if (snapshot.hasData) {
                          final books = snapshot.data!;
                          return GridView.builder(
                            gridDelegate:
                                 SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: orientation == Orientation.portrait?2:4,
                                    crossAxisSpacing: 6,
                                    mainAxisSpacing: 6,
                                    mainAxisExtent: 230),
                            padding: const EdgeInsets.all(8.0),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (BuildContext context, int index) {
                              final book = books[index];
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
                                          filterQuality:FilterQuality.low ,
                                          height: 170,
                                          width: double.infinity,
                                          fit: BoxFit.fill,
                                          imageUrl: book.coverPhotoFile,
                                          placeholder: (context, url) => const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                          errorWidget: (context, url, error) =>
                                              const Center(child: Icon(Icons.error)),
                                        ),
                                        SizedBox(
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    book.title.length > 15
                                                        ? book.title.substring(
                                                                0, 15) +
                                                            '...'
                                                        : book.title,
                                                    style:
                                                       const TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                Text(
                                                  "\$" + book.price.toString(),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
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
                        }
                        return  Container();
                      },
                    ),
        ),
      ),
    );
  }
}
