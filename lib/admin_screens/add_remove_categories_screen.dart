import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/fluttertoast.dart';

class AddRemoveCategories extends StatefulWidget {
  const AddRemoveCategories({super.key});

  @override
  State<AddRemoveCategories> createState() => _AddRemoveCategoriesState();
}

class _AddRemoveCategoriesState extends State<AddRemoveCategories> {
  List<String> categories = [
    'News',
    'Entertainment',
    'Politics',
    'Automotive',
    'Sports',
    'Education',
    'Fashion',
    'Travel',
    'Food',
    'Tech',
    'Science',
  ];

  TextEditingController _categoryController = TextEditingController();
  Future<void> addCategory(String categoryName) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference categoriesRef = firestore.collection('categories');
    await categoriesRef.add({'name': categoryName});
  }

  Stream<QuerySnapshot> getCategories() {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference categoriesRef = firestore.collection('categories');
    return categoriesRef.snapshots();
  }

  Future<void> deleteCategory(String category, String categoryId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference categoriesRef = firestore.collection('categories');
    QuerySnapshot booksSnapshot = await firestore
        .collection('books')
        .where('selectedcategory', isEqualTo: category)
        .get();

    if (booksSnapshot.docs.isEmpty) {
      await categoriesRef.doc(categoryId).delete();
      flutterToast('Category deleted successfully');
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error'),
          content:
              Text('Cannot delete category. Books with this category exist.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Ok'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return SafeArea(
        child: Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Categories'),
        
            automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
              height: height * 0.7,
              padding: const EdgeInsets.all(10),
              child: StreamBuilder<QuerySnapshot>(
                stream: getCategories(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: Text('Loading...'));
                  }
                  List<String> categories = [];
                  for (var doc in snapshot.data!.docs) {
                    categories
                        .add((doc.data() as Map<String, dynamic>)['name']);
                  }
                  return ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (BuildContext context, int index) {
                      String categoryId = snapshot.data!.docs[index].id;
                      return ListTile(
                        title: Text(categories[index]),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            // Call a function to delete the category from Firestore
                            deleteCategory(categories[index], categoryId);
                          },
                        ),
                      );
                    },
                  );
                },
              )),
          ElevatedButton.icon(
              icon: Icon(CupertinoIcons.add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Add Category'),
                      content: TextField(
                        controller: _categoryController,
                        decoration:
                            InputDecoration(hintText: 'Enter category name'),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text('Add'),
                          onPressed: () {
                            String categoryName = _categoryController.text;
                            // Call a function to add the category to Firestore
                            addCategory(categoryName);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              label: const Text('Add'))
        ],
      ),
    ));
  }
}
