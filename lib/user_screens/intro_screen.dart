import 'package:bookstore_recommendation_system_fyp/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

import '../utils/navigation.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  IntroScreenState createState() => IntroScreenState();
}

class IntroScreenState extends State<IntroScreen> {
  final introKey = GlobalKey<IntroductionScreenState>();

  void _onIntroEnd(context) {
    navigateWithNoBack(context, const MyApp());
  }

  Widget _buildImage(String assetName, {double? width, double? height}) {
    return Image.asset(
      'lib/assets/images/$assetName',
      width: width,
      height: height,
    );
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

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 16.0);

    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    return WillPopScope(
      onWillPop: onWillPop,
      child: IntroductionScreen(
        key: introKey,
        globalBackgroundColor: Colors.white,
        allowImplicitScrolling: false,
        // autoScrollDuration: 3000,
        globalHeader: Align(
          alignment: Alignment.topLeft,
          child: SafeArea(
            child: _buildImage('logo.png', width: 80, height: 80),
          ),
        ),
        // globalFooter: SizedBox(
        //   width: double.infinity,
        //   height: 60,
        //   child: ElevatedButton(
        //     child: const Text(
        //       'Let\'s go right away!',
        //       style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        //     ),
        //     onPressed: () => _onIntroEnd(context),
        //   ),
        // ),
        pages: [
          PageViewModel(
            title: "Welcome to BookSavvy",
            body:
                "Get personalized book recommendations based on your interests.",
            image: _buildImage('booksavvy.jpg', width: 300, height: 270),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Discover New Books",
            body:
                "Explore a wide range of books and discover your next favorite read.",
            image: _buildImage('discoverbooks.jpg', width: 300, height: 270),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Buy or Rent Books",
            body: "Buy or rent the books you love.",
            image: _buildImage('buybooks.jpg', width: 300, height: 270),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Listen to Audiobooks",
            body:
                "Listen to your favorite books on the go with our audiobook collection.",
            image: _buildImage('audiobook.jpg', width: 300, height: 270),
            decoration: pageDecoration,
          ),
        ],
        baseBtnStyle: TextButton.styleFrom(
          backgroundColor: Colors.green,
        ),
        skipStyle: TextButton.styleFrom(primary: Colors.white),
        doneStyle: TextButton.styleFrom(primary: Colors.white),
        nextStyle: TextButton.styleFrom(primary: Colors.white),
        backStyle: TextButton.styleFrom(primary: Colors.white),
        onDone: () => _onIntroEnd(context),
        onSkip: () => _onIntroEnd(context), // You can override onSkip callback
        showSkipButton: false,
        skipOrBackFlex: 0,
        nextFlex: 0,
        showBackButton: true,
        //rtl: true, // Display as right-to-left
        back: const Icon(Icons.arrow_back),
        skip: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
        next: const Icon(Icons.arrow_forward),
        done:
            const Text('Lets go', style: TextStyle(fontWeight: FontWeight.w600)),
        curve: Curves.fastLinearToSlowEaseIn,
        controlsMargin: const EdgeInsets.all(16),
        controlsPadding: kIsWeb
            ? const EdgeInsets.all(12.0)
            : const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
        dotsDecorator: const DotsDecorator(
          size: Size(10.0, 10.0),
          color: Color(0xFFBDBDBD),
          activeSize: Size(22.0, 10.0),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
          ),
        ),
        dotsContainerDecorator: const ShapeDecoration(
          color: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
        ),
      ),
    );
  }
}
