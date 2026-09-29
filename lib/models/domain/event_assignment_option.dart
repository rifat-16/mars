import '../../core/compat/firestore_compat.dart';
import '../../core/constants/firestore_keys.dart';

class EventAssignmentOption {
  final String eventId;
  final String eventTitle;
  final String registrationId;
  final String participantUid;
  final String participantName;
  final String participantPhone;
  final String participantAddress;
  final String enrollmentStatus;
  final String billingStatus;

  const EventAssignmentOption({
    required this.eventId,
    required this.eventTitle,
    required this.registrationId,
    required this.participantUid,
    required this.participantName,
    required this.participantPhone,
    required this.participantAddress,
    required this.enrollmentStatus,
    required this.billingStatus,
  });

  bool get isBillingClosed => billingStatus == 'closed';

  factory EventAssignmentOption.fromMap(
    Map<String, dynamic> data, {
    required String eventTitle,
    required String registrationId,
  }) {
    return EventAssignmentOption(
      eventId: FirestoreCompat.readString(data, [FirestoreFields.eventId]),
      eventTitle: eventTitle,
      registrationId: registrationId,
      participantUid: FirestoreCompat.readString(data, [
        FirestoreFields.participantUid,
      ]),
      participantName: FirestoreCompat.readString(data, [
        FirestoreFields.participantName,
      ]),
      participantPhone: FirestoreCompat.readString(data, [
        FirestoreFields.participantPhone,
      ]),
      participantAddress: FirestoreCompat.readString(data, [
        FirestoreFields.participantAddress,
      ]),
      enrollmentStatus: FirestoreCompat.readString(data, [
        FirestoreFields.enrollmentStatus,
      ], fallback: 'enrolled'),
      billingStatus: FirestoreCompat.readString(data, [
        FirestoreFields.billingStatus,
      ], fallback: 'open'),
    );
  }
}
