
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/payment.dart';


class PaymentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Payment> _payments = [];

  List<Payment> get payments => _payments;

  void fetchPayments(currentuserid) async {
    final snapshot = await _firestore.collection('payments').where('userId', isEqualTo: currentuserid).get();
    _payments = snapshot.docs.map((doc) => Payment.fromSnapshot(doc)).toList();
    notifyListeners();
  }
}

