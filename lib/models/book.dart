import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  String bookid = '';
  String title = '';
  String publishyear = '';
  String author = '';
  String tag1 = '';
  String tag2 = '';
  String tag3 = '';
  int price = 0;
  String coverPhotoFile = '';
  String bookFile = '';
  String copyrightPhotoFile = '';
  String audiobook = '';
  String selectedcategory = '';
  List userliked = [];
  String freeRentPaid = '';
  String userid = '';
  bool isPermitted = false;

  get getIsPermitted => this.isPermitted;

  set setIsPermitted(isPermitted) => this.isPermitted = isPermitted;

  get getBookid => this.bookid;

  set setBookid(bookid) => this.bookid = bookid;

  get getTitle => this.title;

  set setTitle(title) => this.title = title;

  get getpublishyear => this.publishyear;

  set setpublishyear(publishyear) => this.publishyear = publishyear;

  get getAuthor => this.author;

  set setAuthor(author) => this.author = author;

  get getTag1 => this.tag1;

  set setTag1(tag1) => this.tag1 = tag1;

  get getTag2 => this.tag2;

  set setTag2(tag2) => this.tag2 = tag2;

  get getTag3 => this.tag3;

  set setTag3(tag3) => this.tag3 = tag3;

  get getPrice => this.price;

  set setPrice(price) => this.price = price;

  get getCoverPhotoFile => this.coverPhotoFile;

  set setCoverPhotoFile(coverPhotoFile) => this.coverPhotoFile = coverPhotoFile;

  get getBookFile => this.bookFile;

  set setBookFile(bookFile) => this.bookFile = bookFile;

  get getCopyrightPhotoFile => this.copyrightPhotoFile;

  set setCopyrightPhotoFile(copyrightPhotoFile) =>
      this.copyrightPhotoFile = copyrightPhotoFile;

  get getAudiobook => this.audiobook;

  set setAudiobook(audiobook) => this.audiobook = audiobook;

  get getselectedcategory => this.selectedcategory;

  set setselectedcategory(selectedcategory) =>
      this.selectedcategory = selectedcategory;

  get getUserliked => this.userliked;

  set setUserliked(userliked) => this.userliked = userliked;

  get getFreeRentPaid => this.freeRentPaid;

  set setFreeRentPaid(freeRentPaid) => this.freeRentPaid = freeRentPaid;

  get getUserid => this.userid;

  set setUserid(userid) => this.userid = userid;

  Timestamp uploadDate;

  Book(
      this.bookid,
      this.title,
      this.publishyear,
      this.author,
      this.tag1,
      this.tag2,
      this.tag3,
      this.price,
      this.coverPhotoFile,
      this.bookFile,
      this.copyrightPhotoFile,
      this.selectedcategory,
      this.audiobook,
      this.freeRentPaid,
      this.userliked,
      this.userid,
      this.isPermitted,
      this.uploadDate);

  // Getters

  Map<String, dynamic> toMap() {
    return {
      'bookid': bookid,
      'title': title,
      'publishyear': publishyear,
      'author': author,
      'tag1': tag1,
      'tag2': tag2,
      'tag3': tag3,
      'price': price,
      'coverPhotoFile': coverPhotoFile,
      'bookFile': bookFile,
      'copyrightPhotoFile': copyrightPhotoFile,
      'selectedcategory': selectedcategory,
      'audiobook': audiobook,
      'freeRentPaid': freeRentPaid,
      'userliked': userliked,
      'userid': userid,
      'isPermitted': isPermitted,
      'uploadDate': uploadDate
    };
  }

  static Book fromMap(Map<String, dynamic> map) {
    return Book(
      map['bookid'],
      map['title'],
      map['publishyear'],
      map['author'],
      map['tag1'],
      map['tag2'],
      map['tag3'],
      map['price'],
      map['coverPhotoFile'],
      map['bookFile'],
      map['copyrightPhotoFile'],
      map['selectedcategory'],
      map['audiobook'],
      map['freeRentPaid'],
      map['userliked'],
      map['userid'],
      map['isPermitted'],
      map['uploadDate'],
    );
  }

  factory Book.fromSnapshot(QueryDocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    Book b=Book.fromMap(data);
    return b;
  }


}
