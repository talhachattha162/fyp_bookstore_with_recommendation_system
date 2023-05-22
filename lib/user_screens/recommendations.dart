import 'dart:convert';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/user_main_screen.dart';
import 'package:bookstore_recommendation_system_fyp/user_screens/view_book_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final openAI = OpenAI.instance.build(token: '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',baseOption: HttpSetup(receiveTimeout:  25000),isLogger: true);
  String _inputText = '';
  String _recommendation = '';
bool isLoading=false;
  List<String> bookList=[];

  String _selectedItem='Shorter';
  String _selectedItem1='Popular books';

  String titles='';
  String age='';
  String authors='';
  String categories='';
  String language='';


  Future<void> _generateRecommendation() async {
    if(mounted){
    setState(() {
      isLoading = true;
    });
    }
    try {
      String author=authors.isEmpty?'':',authors I like $authors';
      String category=categories.isEmpty?'':',categories I like $categories';
      String age1=age.isEmpty?'':',I am $age years olds';
      String language1=language.isEmpty?'':',Language I prefer $language';
      final request = CompleteText(
          prompt: 'As a reader, I have specific preferences and conditions for the books I would like to read. Here are my requirements:The books I like are $titles$author$category$age1$language1,books  should be $_selectedItem,books should be $_selectedItem1.Considering the above conditions Recommend me 10 books. Only provide the title and author name for each book.',
          model: kTranslateModelV3,
          maxTokens: 180);
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
      final snackBar = SnackBar(
        /// need to set following properties for best effect of awesome_snackbar_content
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,

        content: AwesomeSnackbarContent(
          title: 'Error!',
          message:
          e.toString(),

          /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
          contentType: ContentType.failure,
        ),
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }
    if(mounted){
    setState(() {
      isLoading = false;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        navigateWithNoBack(context, MainScreenUser());
        return false;
      },
      child: Scaffold(
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
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
    
              children: [
                Text('Note',style: TextStyle(fontSize: 14.0, color: Colors.green)),
                Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Add multiple titles,authors,languages,categories separated by comma',
                    style: TextStyle(fontSize: 14.0, color: Colors.grey),
                  ),
                ),
                TextFormField(
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Title is required';
                    }
                    return null; // Return null if the input is valid
                  },
                  decoration: InputDecoration(
                    labelText: 'Enter Book Titles you like *',
                  ),
                  onChanged: (value) {
                    if(mounted){
                    setState(() {
                      titles = value;
                    });
                    }
                  },
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Enter authors name you like (optional)',
                  ),
                  onChanged: (value) {
                    if(mounted){
                      setState(() {
                        authors = value;
                      });
                    }
                  },
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Enter categories you like (optional)',
                  ),
                  onChanged: (value) {
                    if(mounted){
                      setState(() {
                        categories = value;
                      });
                    }
                  },
                ),
                DropdownButton<String>(
                  value: _selectedItem,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedItem = newValue!;
                    });
                  },
                  items: <String>[
                    'Shorter',
                    'Longer'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Languages you prefer (optional)',
                  ),
                  onChanged: (value) {
                    if(mounted){
                      setState(() {
                        language = value;
                      });
                    }
                  },
                ),
    
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Enter your age (optional)',
                  ),
                  onChanged: (value) {
                    if(mounted){
                      setState(() {
                        age = value;
                      });
                    }
                  },keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    
                ),
                DropdownButton<String>(
                  value: _selectedItem1,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedItem1 = newValue!;
                    });
                  },
                  items: <String>[
                    'New releases',
                    'Popular books',
                    'Hidden Gems'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.0),
                isLoading==true?Center(child: CircularProgressIndicator()):ElevatedButton(
                  child: Text('Generate'),
                  onPressed: titles.isEmpty ? null : _generateRecommendation,
                ),
                SizedBox(height: 16.0),
                Text(
                  'Recommendations:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                Text(_recommendation),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
