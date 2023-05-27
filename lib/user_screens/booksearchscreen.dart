import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookSearchScreen extends StatefulWidget {
  @override
  _BookSearchScreenState createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  final TextEditingController _titleController = TextEditingController();
  String _selectedAuthor='';
  String _selectedPrice='';
  String _selectedCategory='';
  String _selectedPublishYear='';

  List<String> _authors = [''];
  List<String> _prices = ['Free', 'Rent', 'Paid'];
  List<String> _categories = [''];
  List<String> _publishYears = [''];

  @override
  void initState() {
    super.initState();
    fetchAuthors();
    fetchCategories();
    fetchPublishYears();
  }

  Future<void> fetchAuthors() async {
    final QuerySnapshot querySnapshot =
    await FirebaseFirestore.instance.collection('books').get();

    final List<String> authors = querySnapshot.docs
        .map((doc) => doc.get('author') as String)
        .toList();

    setState(() {
      _authors = authors;
    });
  }

  Future<void> fetchCategories() async {
    final QuerySnapshot querySnapshot =
    await FirebaseFirestore.instance.collection('categories').get();

    final List<String> categories = querySnapshot.docs
        .map((doc) => doc.get('name') as String)
        .toList();

    setState(() {
      _categories = categories;
    });
  }

  Future<void> fetchPublishYears() async {
    final QuerySnapshot querySnapshot =
    await FirebaseFirestore.instance.collection('publishyear').get();

    final List<String> publishYears = querySnapshot.docs
        .map((doc) => doc.get('year') as String)
        .toList();

    setState(() {
      _publishYears = publishYears;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Book Title',
              ),
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _selectedAuthor==''?'':_selectedAuthor,
              onChanged: (newValue) {
                setState(() {
                  _selectedAuthor = newValue!;
                });
              },
              items:_authors.isEmpty?null: _authors.map((author) {
                return DropdownMenuItem<String>(
                  value: author,
                  child: Text(author),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Author',
              ),
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _selectedPrice.toString(),
              onChanged: (newValue) {
                setState(() {
                  _selectedPrice = newValue!;
                });
              },
              items:_prices.isEmpty?null:  _prices.map((price) {
                return DropdownMenuItem<String>(
                  value: price,
                  child: Text(price),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Price',
              ),
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
              items: _categories.isEmpty?null:_categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Category',
              ),
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _selectedPublishYear,
              onChanged: (newValue) {
                setState(() {
                  _selectedPublishYear = newValue!;
                });
              },
              items: _publishYears.isEmpty?null:_publishYears.map((year) {
                return DropdownMenuItem<String>(
                  value: year,
                  child: Text(year),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Publish Year',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Perform the search based on the selected filters
                final String title = _titleController.text;
                // Use the selected filters (_selectedAuthor, _selectedPrice, etc.) to query the books collection in Firebase Firestore

                // Reset the filter values to initial state
                setState(() {
                  _titleController.text = '';
                  _selectedAuthor = '';
                  _selectedPrice = '';
                  _selectedCategory = 'null';
                  _selectedPublishYear = '';
                });
              },
              child: Text('Search'),
            ),
          ],
        ),
      ),
    );
  }
}
