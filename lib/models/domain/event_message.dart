import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/compat/firestore_compat.dart';
import '../../core/constants/firestore_keys.dart';

class EventMessage {
  final String id;
  final String eventId;
  final String registrationId;
  final String participantUid;
  final String participantPhone;
  final String messageType;
  final String messageBody;
  final String deliveryMode;
  final String launchResult;
  final String triggerSource;
  final DateTime? createdAt;
  final String createdByUid;
  final String createdByName;

  const EventMessage({
    required this.id,
    required this.eventId,
    required this.registrationId,
    required this.participantUid,
    required this.participantPhone,
    required this.messageType,
    required this.messageBody,
    required this.deliveryMode,
    required this.launchResult,
    required this.triggerSource,
    required this.createdAt,
    required this.createdByUid,
    required this.createdByName,
  });

  factory EventMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return EventMessage(
      id: doc.id,
      eventId: FirestoreCompat.readString(data, [FirestoreFields.eventId]),
      registrationId: FirestoreCompat.readString(data, [
        FirestoreFields.registrationId,
      ]),
      participantUid: FirestoreCompat.readString(data, [
        FirestoreFields.participantUid,
      ]),
      participantPhone: FirestoreCompat.readString(data, [
        FirestoreFields.participantPhone,
      ]),
      messageType: FirestoreCompat.readString(data, [
        FirestoreFields.messageType,
      ]),
      messageBody: FirestoreCompat.readString(data, [
        FirestoreFields.messageBody,
      ]),
      deliveryMode: FirestoreCompat.readString(data, [
        FirestoreFields.deliveryMode,
      ]),
      launchResult: FirestoreCompat.readString(data, [
        FirestoreFields.launchResult,
      ]),
      triggerSource: FirestoreCompat.readString(data, [
        FirestoreFields.triggerSource,
      ]),
      createdAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.createdAt,
      ]),
      createdByUid: FirestoreCompat.readString(data, [
        FirestoreFields.createdByUid,
      ]),
      createdByName: FirestoreCompat.readString(data, [
        FirestoreFields.createdByName,
      ]),
    );
  }
}
