import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/compat/firestore_compat.dart';
import '../../core/constants/firestore_keys.dart';

class EventAdjustment {
  final double amount;
  final String reason;
  final DateTime at;
  final String byUid;
  final String byName;

  const EventAdjustment({
    required this.amount,
    required this.reason,
    required this.at,
    required this.byUid,
    required this.byName,
  });

  factory EventAdjustment.fromMap(Map<String, dynamic> data) {
    final at = FirestoreCompat.readDateTime(data, [
      FirestoreFields.timestamp,
      'at',
      FirestoreFields.createdAt,
    ]);

    return EventAdjustment(
      amount: FirestoreCompat.readDouble(data, ['amount']),
      reason: FirestoreCompat.readString(data, ['reason']),
      at: at ?? DateTime.now(),
      byUid: FirestoreCompat.readString(data, ['byUid']),
      byName: FirestoreCompat.readString(data, ['byName']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'reason': reason,
      'at': Timestamp.fromDate(at),
      'byUid': byUid,
      'byName': byName,
    };
  }
}
