import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/compat/firestore_compat.dart';
import '../../core/constants/firestore_keys.dart';

class EventCampaign {
  final String id;
  final String title;
  final String slug;
  final String description;
  final double targetAmount;
  final DateTime? targetDeadline;
  final DateTime? qualificationStartAt;
  final DateTime? qualificationEndAt;
  final String durationLabel;
  final List<String> locations;
  final double extraChargePerHead;
  final String status;
  final String lifecycleStatus;
  final DateTime? registrationOpenAt;
  final DateTime? registrationCloseAt;
  final DateTime? eventStartAt;
  final DateTime? eventEndAt;
  final String billingMode;
  final String welcomeMessageTemplate;
  final String congratsMessageTemplate;

  const EventCampaign({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.targetAmount,
    required this.targetDeadline,
    required this.qualificationStartAt,
    required this.qualificationEndAt,
    required this.durationLabel,
    required this.locations,
    required this.extraChargePerHead,
    required this.status,
    required this.lifecycleStatus,
    required this.registrationOpenAt,
    required this.registrationCloseAt,
    required this.eventStartAt,
    required this.eventEndAt,
    required this.billingMode,
    required this.welcomeMessageTemplate,
    required this.congratsMessageTemplate,
  });

  bool get isActive =>
      lifecycleStatus == 'enrollment_open' ||
      lifecycleStatus == 'running' ||
      status.toLowerCase() == 'active';

  bool get isUpcoming => lifecycleStatus == 'draft';
  bool get isClosed =>
      lifecycleStatus == 'closed' || lifecycleStatus == 'archived';

  factory EventCampaign.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawLocations = data[FirestoreFields.locations];
    final legacyStatus = FirestoreCompat.readString(data, [
      FirestoreFields.status,
    ], fallback: 'draft');
    final lifecycleStatus = FirestoreCompat.readString(data, [
      FirestoreFields.lifecycleStatus,
    ], fallback: _mapLegacyStatusToLifecycle(legacyStatus));

    final locations = <String>[];
    if (rawLocations is List) {
      for (final item in rawLocations) {
        if (item is String && item.trim().isNotEmpty) {
          locations.add(item.trim());
        }
      }
    }

    return EventCampaign(
      id: doc.id,
      title: FirestoreCompat.readString(data, [
        FirestoreFields.title,
        FirestoreFields.name,
      ], fallback: 'Event'),
      slug: FirestoreCompat.readString(data, [FirestoreFields.slug]),
      description: FirestoreCompat.readString(data, [
        FirestoreFields.description,
      ]),
      targetAmount: FirestoreCompat.readDouble(data, [
        FirestoreFields.targetAmount,
      ], fallback: 20000),
      targetDeadline: FirestoreCompat.readDateTime(data, [
        FirestoreFields.targetDeadline,
      ]),
      qualificationStartAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.qualificationStartAt,
      ]),
      qualificationEndAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.qualificationEndAt,
      ]),
      durationLabel: FirestoreCompat.readString(data, [
        FirestoreFields.durationLabel,
      ]),
      locations: locations,
      extraChargePerHead: FirestoreCompat.readDouble(data, [
        FirestoreFields.extraChargePerHead,
      ]),
      status: legacyStatus,
      lifecycleStatus: lifecycleStatus,
      registrationOpenAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.registrationOpenAt,
      ]),
      registrationCloseAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.registrationCloseAt,
      ]),
      eventStartAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.eventStartAt,
      ]),
      eventEndAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.eventEndAt,
      ]),
      billingMode: FirestoreCompat.readString(data, [
        FirestoreFields.billingMode,
      ], fallback: 'order_tag'),
      welcomeMessageTemplate: FirestoreCompat.readString(data, [
        FirestoreFields.welcomeMessageTemplate,
      ]),
      congratsMessageTemplate: FirestoreCompat.readString(data, [
        FirestoreFields.congratsMessageTemplate,
      ]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirestoreFields.title: title,
      FirestoreFields.slug: slug,
      FirestoreFields.description: description,
      FirestoreFields.targetAmount: targetAmount,
      FirestoreFields.targetDeadline: targetDeadline == null
          ? null
          : Timestamp.fromDate(targetDeadline!),
      FirestoreFields.qualificationStartAt: qualificationStartAt == null
          ? null
          : Timestamp.fromDate(qualificationStartAt!),
      FirestoreFields.qualificationEndAt: qualificationEndAt == null
          ? null
          : Timestamp.fromDate(qualificationEndAt!),
      FirestoreFields.durationLabel: durationLabel,
      FirestoreFields.locations: locations,
      FirestoreFields.extraChargePerHead: extraChargePerHead,
      FirestoreFields.status: status,
      FirestoreFields.lifecycleStatus: lifecycleStatus,
      FirestoreFields.registrationOpenAt: registrationOpenAt == null
          ? null
          : Timestamp.fromDate(registrationOpenAt!),
      FirestoreFields.registrationCloseAt: registrationCloseAt == null
          ? null
          : Timestamp.fromDate(registrationCloseAt!),
      FirestoreFields.eventStartAt: eventStartAt == null
          ? null
          : Timestamp.fromDate(eventStartAt!),
      FirestoreFields.eventEndAt: eventEndAt == null
          ? null
          : Timestamp.fromDate(eventEndAt!),
      FirestoreFields.billingMode: billingMode,
      FirestoreFields.welcomeMessageTemplate: welcomeMessageTemplate,
      FirestoreFields.congratsMessageTemplate: congratsMessageTemplate,
    };
  }

  static String _mapLegacyStatusToLifecycle(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'running';
      case 'archived':
        return 'archived';
      case 'closed':
        return 'closed';
      default:
        return 'draft';
    }
  }

  EventCampaign copyWith({
    String? id,
    String? title,
    String? slug,
    String? description,
    double? targetAmount,
    DateTime? targetDeadline,
    DateTime? qualificationStartAt,
    DateTime? qualificationEndAt,
    String? durationLabel,
    List<String>? locations,
    double? extraChargePerHead,
    String? status,
    String? lifecycleStatus,
    DateTime? registrationOpenAt,
    DateTime? registrationCloseAt,
    DateTime? eventStartAt,
    DateTime? eventEndAt,
    String? billingMode,
    String? welcomeMessageTemplate,
    String? congratsMessageTemplate,
  }) {
    return EventCampaign(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDeadline: targetDeadline ?? this.targetDeadline,
      qualificationStartAt: qualificationStartAt ?? this.qualificationStartAt,
      qualificationEndAt: qualificationEndAt ?? this.qualificationEndAt,
      durationLabel: durationLabel ?? this.durationLabel,
      locations: locations ?? this.locations,
      extraChargePerHead: extraChargePerHead ?? this.extraChargePerHead,
      status: status ?? this.status,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      registrationOpenAt: registrationOpenAt ?? this.registrationOpenAt,
      registrationCloseAt: registrationCloseAt ?? this.registrationCloseAt,
      eventStartAt: eventStartAt ?? this.eventStartAt,
      eventEndAt: eventEndAt ?? this.eventEndAt,
      billingMode: billingMode ?? this.billingMode,
      welcomeMessageTemplate:
          welcomeMessageTemplate ?? this.welcomeMessageTemplate,
      congratsMessageTemplate:
          congratsMessageTemplate ?? this.congratsMessageTemplate,
    );
  }
}
