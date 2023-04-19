import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Payment {
  String _userId = '';
  String _bookId = '';
  String _freeRentPaid = '';
  int _pricePaid = 0;
  DateTime _dateTimeCreated;
  int _durationDays = 0;
  String formattedDate = '';
  String formattedTime = '';

  Payment(this._userId, this._bookId, this._freeRentPaid, this._pricePaid,
      [
      DateTime? dateTimeCreated,this._durationDays = 0,
      this.formattedDate = '',
      this.formattedTime = ''])
      : _dateTimeCreated = dateTimeCreated ?? DateTime.now();

  factory Payment.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    final paymentCreationTime =
        data['dateTimeCreated']?.toDate() ?? DateTime.now();
    final formattedDate = DateFormat("MMMM d, y").format(paymentCreationTime);
    final formattedTime = DateFormat("h:mm a").format(paymentCreationTime);

    return Payment(
      data['userId'],
      data['bookId'],
      data['freeRentPaid'],
      data['pricePaid'],
      paymentCreationTime,
      data['durationDays'],
      formattedDate,
      formattedTime,
    );
  }

  Payment.fromMap(Map<String, dynamic> map)
      : _userId = map['userId'],
        _bookId = map['bookId'],
        _freeRentPaid = map['freeRentPaid'],
        _pricePaid = map['pricePaid'],
        _dateTimeCreated = (map['dateTimeCreated'] as Timestamp).toDate(),
        _durationDays = map['durationDays'];

  Map<String, dynamic> toMap() => {
        'userId': _userId,
        'bookId': _bookId,
        'freeRentPaid': _freeRentPaid,
        'pricePaid': _pricePaid,
        'dateTimeCreated': Timestamp.fromDate(_dateTimeCreated),
        'durationDays': _durationDays
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

  get durationDays => this._durationDays;

  set durationDays(value) => this._durationDays = value;
}
