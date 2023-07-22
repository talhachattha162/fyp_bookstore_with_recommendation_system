import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// import '../utils/fluttertoast.dart';

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

  final _formKey = GlobalKey<FormState>();
  TextEditingController _categoryController = TextEditingController();
  Future<void> addCategory(String categoryName) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference categoriesRef = firestore.collection('categories');
    await categoriesRef.add({'name': categoryName});
    final snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,

      content: AwesomeSnackbarContent(
        title: 'Success!',
        message: "Category Added successfully",

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
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
      final snackBar = SnackBar(
        /// need to set following properties for best effect of awesome_snackbar_content
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,

        content: AwesomeSnackbarContent(
          title: 'Success!',
          message: "Category deleted successfully",

          /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
          contentType: ContentType.success,
        ),
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content:
          const Text('Cannot delete category. Books with this category exist.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Ok'),
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
        title: const Text('Categories'),
        
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
                    return const Center(child: Text('Loading...'));
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
                          icon: const Icon(Icons.delete),
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
              icon: const Icon(CupertinoIcons.add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Add Category'),
                      content: Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _categoryController,
                          decoration:
                          const InputDecoration(hintText: 'Enter category name'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter Category';
                              }
                            }
                        ),

                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Add'),
                          onPressed: () {
    if (_formKey.currentState!.validate()) {
      String categoryName = _categoryController.text;
      // Call a function to add the category to Firestore
      addCategory(categoryName);
      Navigator.of(context).pop();
    }
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
