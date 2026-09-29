import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/compat/firestore_compat.dart';
import '../../core/constants/firestore_keys.dart';

class Payment {
  final String id;
  final String pharmacyName;
  final String pharmacyPhone;
  final double amount;
  final String paymentMethod;
  final DateTime? timestamp;

  const Payment({
    required this.id,
    required this.pharmacyName,
    required this.pharmacyPhone,
    required this.amount,
    required this.paymentMethod,
    required this.timestamp,
  });

  factory Payment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Payment(
      id: doc.id,
      pharmacyName: FirestoreCompat.readString(data, [
        'pharmacyName',
        FirestoreFields.name,
      ], fallback: 'Unknown Pharmacy'),
      pharmacyPhone: FirestoreCompat.readString(data, [
        FirestoreFields.pharmacyPhone,
        FirestoreFields.phone,
      ]),
      amount: FirestoreCompat.readDouble(data, [FirestoreFields.amount]),
      paymentMethod: FirestoreCompat.readString(data, [
        'paymentMethod',
      ], fallback: 'N/A'),
      timestamp: FirestoreCompat.readDateTime(data, [
        FirestoreFields.timestamp,
        FirestoreFields.createdAt,
      ]),
    );
  }
}
