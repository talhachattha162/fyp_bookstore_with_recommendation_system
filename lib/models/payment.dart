import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  String _userId = '';
  String _bookId = '';
  String _freeRentPaid = '';
  int _pricePaid = 0;
  DateTime _dateTimeCreated;

  Payment(this._userId, this._bookId, this._freeRentPaid, this._pricePaid,
      this._dateTimeCreated);

  Payment.fromMap(Map<String, dynamic> map)
      : _userId = map['userId'],
        _bookId = map['bookId'],
        _freeRentPaid = map['freeRentPaid'],
        _pricePaid = map['pricePaid'],
        _dateTimeCreated = (map['dateTimeCreated'] as Timestamp).toDate();

  Map<String, dynamic> toMap() => {
        'userId': _userId,
        'bookId': _bookId,
        'freeRentPaid': _freeRentPaid,
        'pricePaid': _pricePaid,
        'dateTimeCreated': Timestamp.fromDate(_dateTimeCreated),
      };

  String get userId => _userId;
  set userId(String value) => _userId = value;

  String get bookId => _bookId;
  set bookId(String value) => _bookId = value;

  String get freeRentPaid => _freeRentPaid;
  set freeRentPaid(String value) => _freeRentPaid = value;

  int get pricePaid => _pricePaid;
  set pricePaid(int value) => _pricePaid = value;

  DateTime get dateTimeCreated => _dateTimeCreated;
  set dateTimeCreated(DateTime value) => _dateTimeCreated = value;
}
