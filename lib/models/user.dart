class Users {
  String uid = '';
  String name = '';
  String email = '';
  String password = '';
  String photo = '';
  String age = '';
  int balance = 0;
  int notifications = 0;
  String authenticationmethod = '';
  Users(this.uid, this.name, this.age, this.email, this.password, this.photo,
      this.balance, this.authenticationmethod, this.notifications);

  // setters

  set setBalance(balance) => this.balance = balance;

  void setName(String name) {
    this.name = name;
  }

  void setEmail(String email) {
    this.email = email;
  }

  void setPassword(String password) {
    this.password = password;
  }

  void setPhoto(String photo) {
    this.photo = photo;
  }

  void setAge(String age) {
    this.age = age;
  }

  set setUid(String uid) => this.uid = uid;

  set setAuthenticationmethod(authenticationmethod) =>
      this.authenticationmethod = authenticationmethod;
  // getters
  String getName() {
    return name;
  }

  get getAuthenticationmethod => this.authenticationmethod;

  String get getUid => this.uid;

  String getEmail() {
    return email;
  }

  String getPassword() {
    return password;
  }

  String getPhoto() {
    return photo;
  }

  String getAge() {
    return age;
  }

  get getBalance => this.balance;

  int getNotifications() {
    return notifications;
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'age': age,
      'email': email,
      'password': password,
      'photo': photo,
      'balance': balance,
      'authenticationmethod': authenticationmethod,
      'notifications': notifications
    };
  }

  factory Users.fromMap(Map<String, dynamic> map) {
    return Users(
        map['uid'],
        map['name'],
        map['age'],
        map['email'],
        map['password'],
        map['photo'],
        map['balance'],
        map['authenticationmethod'],
        map['notifications']);
  }
}
