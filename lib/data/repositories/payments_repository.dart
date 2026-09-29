import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_keys.dart';
import '../../models/domain/payment.dart';

abstract class PaymentsRepository {
  Stream<List<Payment>> watchPayments();
}

class FirebasePaymentsRepository implements PaymentsRepository {
  final FirebaseFirestore _firestore;

  FirebasePaymentsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Payment>> watchPayments() {
    return _firestore
        .collection(FirestoreCollections.payments)
        .orderBy(FirestoreFields.timestamp, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Payment.fromDoc).toList());
  }
}
