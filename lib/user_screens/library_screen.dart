import 'package:bookstore_recommendation_system_fyp/user_screens/order_history.dart';
import 'package:bookstore_recommendation_system_fyp/utils/navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/themenotifier.dart';
import '../utils/global_variables.dart';
import 'rented_books.dart';
import 'favourites_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
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
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            title: const Text('Library'),
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 30,
                ),
                Row(
                  children: [
                    // InkWell(
                    //   onTap: () {
                    //     navigateWithNoBack(context, RentedBooks());
                    //   },
                    //   child: SizedBox(
                    //     height: height * 0.3,
                    //     width: width * 0.49,
                    //     child: Card(
                    //       child: Container(
                    //         padding: EdgeInsets.symmetric(
                    //           horizontal: 26.0,
                    //         ),
                    //         child: Column(
                    //           mainAxisAlignment: MainAxisAlignment.center,
                    //           children: [
                    //             Icon(
                    //               Icons.download_done_outlined,
                    //               size: 20,
                    //               color: themeNotifier.getTheme() ==
                    //                       ThemeData.dark(useMaterial3: true)
                    //                           .copyWith(
                    //                         colorScheme:
                    //                             ColorScheme.dark().copyWith(
                    //                           primary: darkprimarycolor,
                    //                           error: Colors.red,
                    //                           onPrimary: darkprimarycolor,
                    //                           outline: darkprimarycolor,
                    //                           primaryVariant: darkprimarycolor,
                    //                           onPrimaryContainer:
                    //                               darkprimarycolor,
                    //                         ),
                    //                       )
                    //                   ? darkprimarycolor
                    //                   : primarycolor,
                    //             ),
                    //             Text('All Purchased \nBooks',
                    //                 style: TextStyle(
                    //                     color: themeNotifier.getTheme() ==
                    //                             ThemeData.dark(
                    //                                     useMaterial3: true)
                    //                                 .copyWith(
                    //                               colorScheme:
                    //                                   ColorScheme.dark()
                    //                                       .copyWith(
                    //                                 primary: darkprimarycolor,
                    //                                 error: Colors.red,
                    //                                 onPrimary: darkprimarycolor,
                    //                                 outline: darkprimarycolor,
                    //                                 primaryVariant:
                    //                                     darkprimarycolor,
                    //                                 onPrimaryContainer:
                    //                                     darkprimarycolor,
                    //                               ),
                    //                             )
                    //                         ? darkprimarycolor
                    //                         : primarycolor,
                    //                     fontWeight: FontWeight.bold,
                    //                     fontSize: 20)),
                    //           ],
                    //         ),
                    //       ),
                    //       elevation: 50,
                    //     ),
                    //   ),
                    // ),
                    InkWell(
                      onTap: () {
                        navigateWithNoBack(context, FavouritesScreen());
                      },
                      child: SizedBox(
                        width: width * 0.49,
                        height: orientation == Orientation.portrait?height * 0.3:height * 0.5,
                        child: Card(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite_border_outlined,
                                  size: 20,
                                  color: themeNotifier.getTheme() ==
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
                                ),
                                Text('Favourties',
                                    style: TextStyle(
                                        color: themeNotifier.getTheme() ==
                                                ThemeData.dark(
                                                        useMaterial3: true)
                                                    .copyWith(
                                                  colorScheme:
                                                      ColorScheme.dark()
                                                          .copyWith(
                                                    primary: darkprimarycolor,
                                                    error: Colors.red,
                                                    onPrimary: darkprimarycolor,
                                                    outline: darkprimarycolor,
                                                    primaryVariant:
                                                        darkprimarycolor,
                                                    onPrimaryContainer:
                                                        darkprimarycolor,
                                                  ),
                                                )
                                            ? darkprimarycolor
                                            : primarycolor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20)),
                              ],
                            ),
                          ),
                          elevation: 50,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        navigateWithNoBack(context, OrderHistory());
                      },
                      child: SizedBox(
                        width: width * 0.49,
                        height: orientation == Orientation.portrait?height * 0.3:height * 0.5,
                        child: Card(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 20,
                                  color: themeNotifier.getTheme() ==
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
                                ),
                                Text('Orders History',
                                    style: TextStyle(
                                        color: themeNotifier.getTheme() ==
                                                ThemeData.dark(
                                                        useMaterial3: true)
                                                    .copyWith(
                                                  colorScheme:
                                                      ColorScheme.dark()
                                                          .copyWith(
                                                    primary: darkprimarycolor,
                                                    error: Colors.red,
                                                    onPrimary: darkprimarycolor,
                                                    outline: darkprimarycolor,
                                                    primaryVariant:
                                                        darkprimarycolor,
                                                    onPrimaryContainer:
                                                        darkprimarycolor,
                                                  ),
                                                )
                                            ? darkprimarycolor
                                            : primarycolor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20)),
                              ],
                            ),
                          ),
                          elevation: 50,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
    );
  }
}
