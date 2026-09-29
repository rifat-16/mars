import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/compat/firestore_compat.dart';
import '../../core/constants/firestore_keys.dart';
import 'event_adjustment.dart';

class EventRegistration {
  final String id;
  final String eventId;
  final String participantUid;
  final String participantName;
  final String participantPhone;
  final String participantPhoneNormalized;
  final String participantAddress;
  final String emergencyPhone;
  final String roleAtRegistration;
  final bool willBringCompanion;
  final int companionCount;
  final String companionRelation;
  final double companionExtraCharge;
  final List<EventAdjustment> manualAdjustments;
  final double autoAchievedAmount;
  final double finalAchievedAmount;
  final double remainingAmount;
  final double medicineIssuedAmount;
  final double financialBaseAmount;
  final double totalPaidAmount;
  final double dueAmount;
  final double advanceAmount;
  final String eligibilityStatus;
  final String approvalStatus;
  final String approvalNote;
  final String approvedByUid;
  final DateTime? approvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? financeUpdatedAt;
  final String financeUpdatedByUid;

  final String enrollmentStatus;
  final DateTime? enrolledAt;
  final String enrolledByUid;
  final String enrolledByName;

  final String billingStatus;
  final DateTime? billingCloseRequestedAt;
  final String billingCloseRequestedByUid;
  final String billingCloseRequestedByName;
  final DateTime? billingClosedAt;
  final String billingClosedByUid;
  final String billingClosedByName;
  final String billingCloseNote;

  final DateTime? welcomePromptedAt;
  final DateTime? congratsPromptedAt;

  const EventRegistration({
    required this.id,
    required this.eventId,
    required this.participantUid,
    required this.participantName,
    required this.participantPhone,
    required this.participantPhoneNormalized,
    required this.participantAddress,
    required this.emergencyPhone,
    required this.roleAtRegistration,
    required this.willBringCompanion,
    required this.companionCount,
    required this.companionRelation,
    required this.companionExtraCharge,
    required this.manualAdjustments,
    required this.autoAchievedAmount,
    required this.finalAchievedAmount,
    required this.remainingAmount,
    required this.medicineIssuedAmount,
    required this.financialBaseAmount,
    required this.totalPaidAmount,
    required this.dueAmount,
    required this.advanceAmount,
    required this.eligibilityStatus,
    required this.approvalStatus,
    required this.approvalNote,
    required this.approvedByUid,
    required this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.financeUpdatedAt,
    required this.financeUpdatedByUid,
    required this.enrollmentStatus,
    required this.enrolledAt,
    required this.enrolledByUid,
    required this.enrolledByName,
    required this.billingStatus,
    required this.billingCloseRequestedAt,
    required this.billingCloseRequestedByUid,
    required this.billingCloseRequestedByName,
    required this.billingClosedAt,
    required this.billingClosedByUid,
    required this.billingClosedByName,
    required this.billingCloseNote,
    required this.welcomePromptedAt,
    required this.congratsPromptedAt,
  });

  bool get isDraft => approvalStatus.toLowerCase() == 'draft';
  bool get isSubmitted => approvalStatus.toLowerCase() == 'submitted';
  bool get isApproved => approvalStatus.toLowerCase() == 'approved';
  bool get isEligible {
    final targetSnapshot = financialBaseAmount > 0 ? financialBaseAmount : 0.0;
    if (targetSnapshot <= 0) {
      return eligibilityStatus.toLowerCase() == 'eligible';
    }
    return medicineIssuedAmount >= targetSnapshot ||
        eligibilityStatus.toLowerCase() == 'eligible';
  }

  bool get hasDue => dueAmount > 0;
  bool get hasAdvance => advanceAmount > 0;
  bool get isBillingClosed => billingStatus == 'closed';
  bool get isCloseRequested => billingStatus == 'close_requested';
  bool get canRequestClose => billingStatus == 'open' && dueAmount >= 0;

  double get manualAdjustmentTotal {
    var total = 0.0;
    for (final item in manualAdjustments) {
      total += item.amount;
    }
    return total;
  }

  factory EventRegistration.empty({required String eventId}) {
    return EventRegistration(
      id: '',
      eventId: eventId,
      participantUid: '',
      participantName: '',
      participantPhone: '',
      participantPhoneNormalized: '',
      participantAddress: '',
      emergencyPhone: '',
      roleAtRegistration: '',
      willBringCompanion: false,
      companionCount: 0,
      companionRelation: '',
      companionExtraCharge: 0,
      manualAdjustments: const [],
      autoAchievedAmount: 0,
      finalAchievedAmount: 0,
      remainingAmount: 0,
      medicineIssuedAmount: 0,
      financialBaseAmount: 0,
      totalPaidAmount: 0,
      dueAmount: 0,
      advanceAmount: 0,
      eligibilityStatus: 'not_eligible',
      approvalStatus: 'draft',
      approvalNote: '',
      approvedByUid: '',
      approvedAt: null,
      createdAt: null,
      updatedAt: null,
      financeUpdatedAt: null,
      financeUpdatedByUid: '',
      enrollmentStatus: 'enrolled',
      enrolledAt: null,
      enrolledByUid: '',
      enrolledByName: '',
      billingStatus: 'open',
      billingCloseRequestedAt: null,
      billingCloseRequestedByUid: '',
      billingCloseRequestedByName: '',
      billingClosedAt: null,
      billingClosedByUid: '',
      billingClosedByName: '',
      billingCloseNote: '',
      welcomePromptedAt: null,
      congratsPromptedAt: null,
    );
  }

  factory EventRegistration.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawAdjustments = data[FirestoreFields.manualAdjustments];
    final manualAdjustments = <EventAdjustment>[];

    if (rawAdjustments is List) {
      for (final item in rawAdjustments) {
        if (item is Map<String, dynamic>) {
          manualAdjustments.add(EventAdjustment.fromMap(item));
        } else if (item is Map) {
          manualAdjustments.add(
            EventAdjustment.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final medicineIssuedAmount = FirestoreCompat.readDouble(data, [
      FirestoreFields.medicineIssuedAmount,
      FirestoreFields.autoAchievedAmount,
      FirestoreFields.finalAchievedAmount,
      FirestoreFields.targetAmount,
    ]);

    final totalPaidAmount = FirestoreCompat.readDouble(data, [
      FirestoreFields.totalPaidAmount,
    ]);

    final dueAmount = FirestoreCompat.readDouble(data, [
      FirestoreFields.dueAmount,
    ]);
    final advanceAmount = FirestoreCompat.readDouble(data, [
      FirestoreFields.advanceAmount,
    ]);
    final computedDue = (medicineIssuedAmount - totalPaidAmount) <= 0
        ? 0.0
        : (medicineIssuedAmount - totalPaidAmount);
    final computedAdvance = (totalPaidAmount - medicineIssuedAmount) <= 0
        ? 0.0
        : (totalPaidAmount - medicineIssuedAmount);
    final financialBaseAmount = FirestoreCompat.readDouble(data, [
      FirestoreFields.financialBaseAmount,
      FirestoreFields.targetAmount,
    ], fallback: medicineIssuedAmount);
    final computedEligibility =
        financialBaseAmount > 0 && medicineIssuedAmount >= financialBaseAmount
        ? 'eligible'
        : 'not_eligible';

    return EventRegistration(
      id: doc.id,
      eventId: FirestoreCompat.readString(data, [FirestoreFields.eventId]),
      participantUid: FirestoreCompat.readString(data, [
        FirestoreFields.participantUid,
      ]),
      participantName: FirestoreCompat.readString(data, [
        FirestoreFields.participantName,
      ]),
      participantPhone: FirestoreCompat.readString(data, [
        FirestoreFields.participantPhone,
      ]),
      participantPhoneNormalized: FirestoreCompat.readString(data, [
        FirestoreFields.participantPhoneNormalized,
      ]),
      participantAddress: FirestoreCompat.readString(data, [
        FirestoreFields.participantAddress,
        FirestoreFields.address,
      ]),
      emergencyPhone: FirestoreCompat.readString(data, [
        FirestoreFields.emergencyPhone,
      ]),
      roleAtRegistration: FirestoreCompat.readString(data, [
        FirestoreFields.roleAtRegistration,
      ]),
      willBringCompanion: data[FirestoreFields.willBringCompanion] == true,
      companionCount: FirestoreCompat.readInt(data, [
        FirestoreFields.companionCount,
      ]),
      companionRelation: FirestoreCompat.readString(data, [
        FirestoreFields.companionRelation,
      ]),
      companionExtraCharge: FirestoreCompat.readDouble(data, [
        FirestoreFields.companionExtraCharge,
      ]),
      manualAdjustments: manualAdjustments,
      autoAchievedAmount: FirestoreCompat.readDouble(data, [
        FirestoreFields.autoAchievedAmount,
      ], fallback: medicineIssuedAmount),
      finalAchievedAmount: FirestoreCompat.readDouble(data, [
        FirestoreFields.finalAchievedAmount,
      ], fallback: medicineIssuedAmount),
      remainingAmount: FirestoreCompat.readDouble(data, [
        FirestoreFields.remainingAmount,
      ]),
      medicineIssuedAmount: medicineIssuedAmount,
      financialBaseAmount: financialBaseAmount,
      totalPaidAmount: totalPaidAmount,
      dueAmount: dueAmount > 0 ? dueAmount : computedDue,
      advanceAmount: advanceAmount > 0 ? advanceAmount : computedAdvance,
      eligibilityStatus: FirestoreCompat.readString(data, [
        FirestoreFields.eligibilityStatus,
      ], fallback: computedEligibility),
      approvalStatus: FirestoreCompat.readString(data, [
        FirestoreFields.approvalStatus,
      ], fallback: 'draft'),
      approvalNote: FirestoreCompat.readString(data, [
        FirestoreFields.approvalNote,
      ]),
      approvedByUid: FirestoreCompat.readString(data, [
        FirestoreFields.approvedByUid,
      ]),
      approvedAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.approvedAt,
      ]),
      createdAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.createdAt,
        FirestoreFields.createdAtSnake,
      ]),
      updatedAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.updatedAt,
      ]),
      financeUpdatedAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.financeUpdatedAt,
      ]),
      financeUpdatedByUid: FirestoreCompat.readString(data, [
        FirestoreFields.financeUpdatedByUid,
      ]),
      enrollmentStatus: FirestoreCompat.readString(data, [
        FirestoreFields.enrollmentStatus,
      ], fallback: 'enrolled'),
      enrolledAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.enrolledAt,
      ]),
      enrolledByUid: FirestoreCompat.readString(data, [
        FirestoreFields.enrolledByUid,
      ]),
      enrolledByName: FirestoreCompat.readString(data, [
        FirestoreFields.enrolledByName,
      ]),
      billingStatus: FirestoreCompat.readString(data, [
        FirestoreFields.billingStatus,
      ], fallback: 'open'),
      billingCloseRequestedAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.billingCloseRequestedAt,
      ]),
      billingCloseRequestedByUid: FirestoreCompat.readString(data, [
        FirestoreFields.billingCloseRequestedByUid,
      ]),
      billingCloseRequestedByName: FirestoreCompat.readString(data, [
        FirestoreFields.billingCloseRequestedByName,
      ]),
      billingClosedAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.billingClosedAt,
      ]),
      billingClosedByUid: FirestoreCompat.readString(data, [
        FirestoreFields.billingClosedByUid,
      ]),
      billingClosedByName: FirestoreCompat.readString(data, [
        FirestoreFields.billingClosedByName,
      ]),
      billingCloseNote: FirestoreCompat.readString(data, [
        FirestoreFields.billingCloseNote,
      ]),
      welcomePromptedAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.welcomePromptedAt,
      ]),
      congratsPromptedAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.congratsPromptedAt,
      ]),
    );
  }

  EventRegistration copyWith({
    String? id,
    String? eventId,
    String? participantUid,
    String? participantName,
    String? participantPhone,
    String? participantPhoneNormalized,
    String? participantAddress,
    String? emergencyPhone,
    String? roleAtRegistration,
    bool? willBringCompanion,
    int? companionCount,
    String? companionRelation,
    double? companionExtraCharge,
    List<EventAdjustment>? manualAdjustments,
    double? autoAchievedAmount,
    double? finalAchievedAmount,
    double? remainingAmount,
    double? medicineIssuedAmount,
    double? financialBaseAmount,
    double? totalPaidAmount,
    double? dueAmount,
    double? advanceAmount,
    String? eligibilityStatus,
    String? approvalStatus,
    String? approvalNote,
    String? approvedByUid,
    DateTime? approvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? financeUpdatedAt,
    String? financeUpdatedByUid,
    String? enrollmentStatus,
    DateTime? enrolledAt,
    String? enrolledByUid,
    String? enrolledByName,
    String? billingStatus,
    DateTime? billingCloseRequestedAt,
    String? billingCloseRequestedByUid,
    String? billingCloseRequestedByName,
    DateTime? billingClosedAt,
    String? billingClosedByUid,
    String? billingClosedByName,
    String? billingCloseNote,
    DateTime? welcomePromptedAt,
    DateTime? congratsPromptedAt,
  }) {
    return EventRegistration(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      participantUid: participantUid ?? this.participantUid,
      participantName: participantName ?? this.participantName,
      participantPhone: participantPhone ?? this.participantPhone,
      participantPhoneNormalized:
          participantPhoneNormalized ?? this.participantPhoneNormalized,
      participantAddress: participantAddress ?? this.participantAddress,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      roleAtRegistration: roleAtRegistration ?? this.roleAtRegistration,
      willBringCompanion: willBringCompanion ?? this.willBringCompanion,
      companionCount: companionCount ?? this.companionCount,
      companionRelation: companionRelation ?? this.companionRelation,
      companionExtraCharge: companionExtraCharge ?? this.companionExtraCharge,
      manualAdjustments: manualAdjustments ?? this.manualAdjustments,
      autoAchievedAmount: autoAchievedAmount ?? this.autoAchievedAmount,
      finalAchievedAmount: finalAchievedAmount ?? this.finalAchievedAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      medicineIssuedAmount: medicineIssuedAmount ?? this.medicineIssuedAmount,
      financialBaseAmount: financialBaseAmount ?? this.financialBaseAmount,
      totalPaidAmount: totalPaidAmount ?? this.totalPaidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      eligibilityStatus: eligibilityStatus ?? this.eligibilityStatus,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvalNote: approvalNote ?? this.approvalNote,
      approvedByUid: approvedByUid ?? this.approvedByUid,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      financeUpdatedAt: financeUpdatedAt ?? this.financeUpdatedAt,
      financeUpdatedByUid: financeUpdatedByUid ?? this.financeUpdatedByUid,
      enrollmentStatus: enrollmentStatus ?? this.enrollmentStatus,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      enrolledByUid: enrolledByUid ?? this.enrolledByUid,
      enrolledByName: enrolledByName ?? this.enrolledByName,
      billingStatus: billingStatus ?? this.billingStatus,
      billingCloseRequestedAt:
          billingCloseRequestedAt ?? this.billingCloseRequestedAt,
      billingCloseRequestedByUid:
          billingCloseRequestedByUid ?? this.billingCloseRequestedByUid,
      billingCloseRequestedByName:
          billingCloseRequestedByName ?? this.billingCloseRequestedByName,
      billingClosedAt: billingClosedAt ?? this.billingClosedAt,
      billingClosedByUid: billingClosedByUid ?? this.billingClosedByUid,
      billingClosedByName: billingClosedByName ?? this.billingClosedByName,
      billingCloseNote: billingCloseNote ?? this.billingCloseNote,
      welcomePromptedAt: welcomePromptedAt ?? this.welcomePromptedAt,
      congratsPromptedAt: congratsPromptedAt ?? this.congratsPromptedAt,
    );
  }

  Map<String, dynamic> toMap({
    required String createdByUid,
    required String updatedByUid,
    bool includeCreatedAt = false,
  }) {
    final map = <String, dynamic>{
      FirestoreFields.eventId: eventId,
      FirestoreFields.participantUid: participantUid,
      FirestoreFields.participantName: participantName,
      FirestoreFields.participantPhone: participantPhone,
      FirestoreFields.participantPhoneNormalized: participantPhoneNormalized,
      FirestoreFields.participantAddress: participantAddress,
      FirestoreFields.emergencyPhone: emergencyPhone,
      FirestoreFields.roleAtRegistration: roleAtRegistration,
      FirestoreFields.willBringCompanion: willBringCompanion,
      FirestoreFields.companionCount: companionCount,
      FirestoreFields.companionRelation: companionRelation,
      FirestoreFields.companionExtraCharge: companionExtraCharge,
      FirestoreFields.manualAdjustments: manualAdjustments
          .map((item) => item.toMap())
          .toList(),
      FirestoreFields.autoAchievedAmount: autoAchievedAmount,
      FirestoreFields.finalAchievedAmount: finalAchievedAmount,
      FirestoreFields.remainingAmount: remainingAmount,
      FirestoreFields.medicineIssuedAmount: medicineIssuedAmount,
      FirestoreFields.financialBaseAmount: financialBaseAmount,
      FirestoreFields.totalPaidAmount: totalPaidAmount,
      FirestoreFields.dueAmount: dueAmount,
      FirestoreFields.advanceAmount: advanceAmount,
      FirestoreFields.financeUpdatedAt: financeUpdatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(financeUpdatedAt!),
      FirestoreFields.financeUpdatedByUid: financeUpdatedByUid,
      FirestoreFields.eligibilityStatus: eligibilityStatus,
      FirestoreFields.approvalStatus: approvalStatus,
      FirestoreFields.approvalNote: approvalNote,
      FirestoreFields.approvedByUid: approvedByUid,
      FirestoreFields.approvedAt: approvedAt == null
          ? null
          : Timestamp.fromDate(approvedAt!),
      FirestoreFields.enrollmentStatus: enrollmentStatus,
      FirestoreFields.enrolledAt: enrolledAt == null
          ? null
          : Timestamp.fromDate(enrolledAt!),
      FirestoreFields.enrolledByUid: enrolledByUid,
      FirestoreFields.enrolledByName: enrolledByName,
      FirestoreFields.billingStatus: billingStatus,
      FirestoreFields.billingCloseRequestedAt: billingCloseRequestedAt == null
          ? null
          : Timestamp.fromDate(billingCloseRequestedAt!),
      FirestoreFields.billingCloseRequestedByUid: billingCloseRequestedByUid,
      FirestoreFields.billingCloseRequestedByName: billingCloseRequestedByName,
      FirestoreFields.billingClosedAt: billingClosedAt == null
          ? null
          : Timestamp.fromDate(billingClosedAt!),
      FirestoreFields.billingClosedByUid: billingClosedByUid,
      FirestoreFields.billingClosedByName: billingClosedByName,
      FirestoreFields.billingCloseNote: billingCloseNote,
      FirestoreFields.welcomePromptedAt: welcomePromptedAt == null
          ? null
          : Timestamp.fromDate(welcomePromptedAt!),
      FirestoreFields.congratsPromptedAt: congratsPromptedAt == null
          ? null
          : Timestamp.fromDate(congratsPromptedAt!),
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.updatedByUid: updatedByUid,
      FirestoreFields.createdByUid: createdByUid,
    };

    if (includeCreatedAt) {
      map[FirestoreFields.createdAt] = FieldValue.serverTimestamp();
    }

    return map;
  }
}
