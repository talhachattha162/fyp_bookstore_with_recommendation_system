import 'dart:convert';

import 'package:bookstore_recommendation_system_fyp/user_screens/user_main_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/view_book_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';

import '../utils/navigation.dart';

class BookRecommendationScreen extends StatefulWidget {
  const BookRecommendationScreen({Key? key}) : super(key: key);

  @override
  _BookRecommendationScreenState createState() =>
      _BookRecommendationScreenState();
}

class _BookRecommendationScreenState extends State<BookRecommendationScreen> {

  final openAI = OpenAI.instance.build(token: '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',baseOption: HttpSetup(receiveTimeout:  20000),isLogger: true);
  String _inputText = '';
  String _recommendation = '';
bool isLoading=false;
  List<String> bookList=[];


  Future<void> _generateRecommendation() async {
    if(mounted){
    setState(() {
      isLoading = true;
    });
    }
    try {
      final request = CompleteText(
          prompt: 'Recommend me 5-7 books similar to $_inputText. The books should be popular, highly rated, and recent. Please include the title and author name for each book.',
          model: kTranslateModelV3,
          maxTokens: 130);
      final response = await openAI.onCompleteText(request: request);
     if(mounted){
      setState(() {
        _recommendation = response!.choices.first.text;
      });
     }
      List<String> bookList1 = _recommendation.split('\n').map((book) =>
          book.replaceFirst(RegExp(r'\d+\.\s+'), '').trim()).toList();
          if(mounted){
      setState(() {
        bookList = bookList1;
      });
      }
    }
    catch(e){
      if(mounted){
      setState(() {
        _recommendation = 'error';
      });
      }
    }
    if(mounted){
    setState(() {
      isLoading = false;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:   AppBar(
    title: const Text('Recommendations'),
    leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
    navigateWithNoBack(
    context,
    MainScreenUser());
    },
    )),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Book Title',
              ),
              onChanged: (value) {
                if(mounted){
                setState(() {
                  _inputText = value;
                });
                }
              },
            ),
            SizedBox(height: 16.0),
            isLoading==true?Center(child: CircularProgressIndicator()):ElevatedButton(
              child: Text('Generate'),
              onPressed: _inputText.isEmpty ? null : _generateRecommendation,
            ),
            SizedBox(height: 16.0),
            Text(
              'Recommendation:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(_recommendation),
          ],
        ),
      ),
    );
  }
}
