class Categories {
  List<String> _categoryName = [];

  Categories(this._categoryName);

  List<String> get categoryName => _categoryName;

  set categoryName(List<String> newName) {
    _categoryName = newName;
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryName': _categoryName,
    };
  }

  factory Categories.fromMap(Map<String, dynamic> map) {
    return Categories(map['categoryName']);
  }
}
