import 'package:bookstore_recommendation_system_fyp/user_screens/user_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/linkprovider.dart';
import '../utils/navigation.dart';

class ChangeRecommendationCriteria extends StatefulWidget {
  @override
  _ChangeRecommendationCriteriaState createState() => _ChangeRecommendationCriteriaState();
}

class _ChangeRecommendationCriteriaState extends State<ChangeRecommendationCriteria> {

int _selectedOption=0;
  void _handleOptionChange(int value) {
    if(mounted){
      setState(() {
        _selectedOption = value;
      });
    }
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    LinkProvider linkProvider = Provider.of<LinkProvider>(context, listen: false);
    if(linkProvider.link=='http://talha1623.pythonanywhere.com/recommend?book_name='){
     if(mounted) {
       setState(() {
         _selectedOption = 1;
       });
     }
    }
    else{
      if(mounted) {
        setState(() {
          _selectedOption = 2;
        });
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Text('Change Recommendation Criteria'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                navigateWithNoBack(context, const MainScreenUser());
              },
            ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select an criteria for Recommendations:',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            RadioListTile(
              title: Text('Cosine Similarity'),
              value: 1,
              groupValue: _selectedOption,
              onChanged: (value){
                LinkProvider linkProvider = Provider.of<LinkProvider>(context, listen: false);
                linkProvider.link = 'http://talha1623.pythonanywhere.com/recommend?book_name=';
                _handleOptionChange(value!);
              },
            ),
            RadioListTile(
              title: Text('DBSCAN'),
              value: 2,
              groupValue: _selectedOption,
              onChanged:  (value){
                LinkProvider linkProvider = Provider.of<LinkProvider>(context, listen: false);
                linkProvider.link = 'http://talha1623.pythonanywhere.com/recommend2?book_name=';
                _handleOptionChange(value!);
      },
            ),
          ],
        ),
      ),
    );
  }
}