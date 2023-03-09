class Review {
  String reviewId = '';
  String bookId = '';
  String uploadedByUserId = '';
  String reviewtext = '';
  int rating = 0;

  Review({
    required this.reviewId,
    required this.bookId,
    required this.uploadedByUserId,
    required this.rating,
    required this.reviewtext,
  });

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'bookId': bookId,
      'uploadedByUserId': uploadedByUserId,
      'rating': rating,
      'reviewtext': reviewtext
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
        reviewId: map['reviewId'],
        bookId: map['bookId'],
        uploadedByUserId: map['uploadedByUserId'],
        rating: map['rating'],
        reviewtext: map['reviewtext']);
  }

  // Getters and setters for each attribute
  String get getReviewId => reviewId;
  set setReviewId(String value) => reviewId = value;

  String get getBookId => bookId;
  set setBookId(String value) => bookId = value;

  String get getUploadedByUserId => uploadedByUserId;
  set setUploadedByUserId(String value) => uploadedByUserId = value;

  int get getRating => rating;
  set setRating(int value) => rating = value;

  get getReviewtext => this.reviewtext;
  set setReviewtext(reviewtext) => this.reviewtext = reviewtext;
}
