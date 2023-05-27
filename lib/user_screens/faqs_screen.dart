import 'dart:async';
import 'dart:io';

import 'package:bookstore_recommendation_system_fyp/user_screens/user_main_screen.dart';
import 'package:bookstore_recommendation_system_fyp/utils/navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/internetavailabilitynotifier.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) async {
      final internetAvailabilityNotifier =
          Provider.of<InternetNotifier>(context, listen: false);
      try {
        final result = await InternetAddress.lookup('google.com');
        if ((result.isNotEmpty && result[0].rawAddress.isNotEmpty)) {
          internetAvailabilityNotifier.setInternetAvailability(true);
        } else {}
      } on SocketException catch (_) {
        internetAvailabilityNotifier.setInternetAvailability(false);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
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
    return WillPopScope(
      onWillPop: () async {
        navigateWithNoBack(context, MainScreenUser());
        return false;
      },
      child: SafeArea(
        child: Scaffold(
            appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    navigateWithNoBack(context, const MainScreenUser());
                  },
                ),
                title: const Text('FAQS')),
            body:  SingleChildScrollView(
    scrollDirection: Axis.vertical,child: Steps())),
      ),
    );
  }
}

class Step {
  Step(this.title, this.body, [this.subSteps = const <Step>[]]);
  String title;
  String body;
  List<Step> subSteps;
}

List<Step> getSteps() {
  return [
    Step('Can User rent books?', 'Yes ofcourse a normal user can rent books'),
    Step('Is there any free books in the app?',
        'Yes, there are free books available'),
    Step('Is there any audio books?',
        'Some books have audio books also and some dont have'),
    Step(
      'Do this app have payment methods?',
      'There is only one payment gateway in this application',
    ),
    Step(
      'Do this app available on web,desktop platform?',
      'Intially this app is on Android but we will expand it in these platform soon',
    ),
  ];
}

class Steps extends StatefulWidget {
  const Steps({Key? key}) : super(key: key);
  @override
  State<Steps> createState() => _StepsState();
}

class _StepsState extends State<Steps> {
  final List<Step> _steps = getSteps();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(child: _renderSteps(_steps)),
    );
  }

  Widget _renderSteps(List<Step> steps) {
    return ExpansionPanelList.radio(
      children: steps.map<ExpansionPanelRadio>((Step step) {
        return ExpansionPanelRadio(
            headerBuilder: (BuildContext context, bool isExpanded) {
              return ListTile(
                title: Text(step.title),
              );
            },
            body: ListTile(
                title: Text(step.body), subtitle: _renderSteps(step.subSteps)),
            value: step.title);
      }).toList(),
    );
  }
}
