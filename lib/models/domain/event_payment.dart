import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/compat/firestore_compat.dart';
import '../../core/constants/firestore_keys.dart';

class EventPayment {
  final String id;
  final String eventId;
  final String registrationId;
  final String participantUid;
  final String participantName;
  final String participantPhone;
  final double amount;
  final String paymentMethod;
  final String note;
  final String collectedByUid;
  final String collectedByName;
  final DateTime? collectedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EventPayment({
    required this.id,
    required this.eventId,
    required this.registrationId,
    required this.participantUid,
    required this.participantName,
    required this.participantPhone,
    required this.amount,
    required this.paymentMethod,
    required this.note,
    required this.collectedByUid,
    required this.collectedByName,
    required this.collectedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventPayment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return EventPayment(
      id: doc.id,
      eventId: FirestoreCompat.readString(data, [FirestoreFields.eventId]),
      registrationId: FirestoreCompat.readString(data, [
        FirestoreFields.registrationId,
      ]),
      participantUid: FirestoreCompat.readString(data, [
        FirestoreFields.participantUid,
      ]),
      participantName: FirestoreCompat.readString(data, [
        FirestoreFields.participantName,
      ]),
      participantPhone: FirestoreCompat.readString(data, [
        FirestoreFields.participantPhone,
      ]),
      amount: FirestoreCompat.readDouble(data, [FirestoreFields.amount]),
      paymentMethod: FirestoreCompat.readString(data, [
        FirestoreFields.paymentMethod,
      ]),
      note: FirestoreCompat.readString(data, [FirestoreFields.note]),
      collectedByUid: FirestoreCompat.readString(data, [
        FirestoreFields.collectedByUid,
      ]),
      collectedByName: FirestoreCompat.readString(data, [
        FirestoreFields.collectedByName,
      ]),
      collectedAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.collectedAt,
      ]),
      createdAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.createdAt,
      ]),
      updatedAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.updatedAt,
      ]),
    );
  }
}
