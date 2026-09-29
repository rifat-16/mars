import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../core/compat/firestore_compat.dart';
import '../../core/constants/firestore_keys.dart';
import '../../models/domain/event_adjustment.dart';
import '../../models/domain/event_campaign.dart';
import '../../models/domain/event_message.dart';
import '../../models/domain/event_payment.dart';
import '../../models/domain/event_registration.dart';

abstract class EventsRepository {
  Stream<List<EventCampaign>> watchEventsList();
  Stream<EventCampaign?> watchEventById(String eventId);
  Stream<EventCampaign?> watchActiveEvent();
  Future<String> createEvent({
    required EventCampaign draft,
    required String actorUid,
    required String actorName,
  });
  Future<void> updateEvent({
    required String eventId,
    required EventCampaign draft,
    required String actorUid,
    required String actorName,
  });
  Future<EventCampaign?> fetchEventById(String eventId);
  Stream<List<EventRegistration>> watchRegistrations({
    required String eventId,
    required String role,
    required String currentUid,
  });
  Stream<EventRegistration?> watchRegistrationById(String registrationId);
  Future<EventRegistration?> fetchRegistrationById(String registrationId);
  Future<EventRegistration?> fetchMyRegistration({
    required String eventId,
    required String participantUid,
  });
  Stream<List<EventPayment>> watchPayments({
    required String registrationId,
    required String role,
    required String currentUid,
  });
  Stream<List<EventMessage>> watchMessages({
    required String registrationId,
    required String role,
    required String currentUid,
  });
  Future<String> upsertRegistration({
    required EventCampaign event,
    required EventRegistration draft,
    required String actorUid,
    required String actorName,
    required bool submit,
  });
  Future<void> submitRegistration({
    required String registrationId,
    required EventCampaign event,
    required String actorUid,
    required String actorName,
  });
  Future<void> setApproval({
    required String registrationId,
    required EventCampaign event,
    required String approvalStatus,
    required String note,
    required String actorUid,
    required String actorName,
  });
  Future<void> addManualAdjustment({
    required String registrationId,
    required EventCampaign event,
    required double amount,
    required String reason,
    required String actorUid,
    required String actorName,
  });
  Future<void> removeManualAdjustment({
    required String registrationId,
    required EventCampaign event,
    required int index,
    required String actorUid,
    required String actorName,
  });
  Future<void> recalculateProgress({
    required String registrationId,
    required EventCampaign event,
    required String actorUid,
    required String actorName,
  });
  Future<void> addPayment({
    required EventCampaign event,
    required String registrationId,
    required double amount,
    required String paymentMethod,
    required String note,
    required String actorUid,
    required String actorName,
  });
  Future<void> updatePayment({
    required EventCampaign event,
    required String paymentId,
    required double amount,
    required String paymentMethod,
    required String note,
    required String actorUid,
    required String actorName,
  });
  Future<void> deletePayment({
    required EventCampaign event,
    required String paymentId,
    required String actorUid,
    required String actorName,
  });
  Future<void> recomputeFinanceSnapshot({
    required String registrationId,
    required EventCampaign event,
    required String actorUid,
    required String actorName,
  });
  Future<bool> recomputeRegistrationFinanceFromOrders({
    required String registrationId,
    required EventCampaign event,
    required String actorUid,
    required String actorName,
  });
  Future<void> requestBillingClose({
    required String registrationId,
    required String actorUid,
    required String actorName,
    required String note,
  });
  Future<void> approveBillingClose({
    required String registrationId,
    required String actorUid,
    required String actorName,
    required String note,
  });
  Future<void> rejectBillingClose({
    required String registrationId,
    required String actorUid,
    required String actorName,
    required String note,
  });
  Future<void> logEventMessage({
    required String eventId,
    required String registrationId,
    required String participantUid,
    required String participantPhone,
    required String messageType,
    required String messageBody,
    required String launchResult,
    required String triggerSource,
    required String actorUid,
    required String actorName,
  });
}

class FirebaseEventsRepository implements EventsRepository {
  final FirebaseFirestore _firestore;

  FirebaseEventsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> createEvent({
    required EventCampaign draft,
    required String actorUid,
    required String actorName,
  }) async {
    final ref = _firestore.collection(FirestoreCollections.events).doc();
    final lifecycle = draft.lifecycleStatus.trim().isEmpty
        ? 'draft'
        : draft.lifecycleStatus.trim();
    final legacyStatus = _legacyStatusFromLifecycle(lifecycle);

    await ref.set({
      ...draft.copyWith(id: ref.id, status: legacyStatus).toMap(),
      FirestoreFields.status: legacyStatus,
      FirestoreFields.lifecycleStatus: lifecycle,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.createdByUid: actorUid,
      FirestoreFields.updatedByUid: actorUid,
      FirestoreFields.createdByName: actorName,
    }, SetOptions(merge: true));

    return ref.id;
  }

  @override
  Future<void> updateEvent({
    required String eventId,
    required EventCampaign draft,
    required String actorUid,
    required String actorName,
  }) async {
    final ref = _firestore.collection(FirestoreCollections.events).doc(eventId);
    final doc = await ref.get();
    if (!doc.exists) {
      throw Exception('Event not found.');
    }

    final lifecycle = draft.lifecycleStatus.trim().isEmpty
        ? 'draft'
        : draft.lifecycleStatus.trim();
    final legacyStatus = _legacyStatusFromLifecycle(lifecycle);

    await ref.set({
      ...draft.copyWith(id: eventId, status: legacyStatus).toMap(),
      FirestoreFields.status: legacyStatus,
      FirestoreFields.lifecycleStatus: lifecycle,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.updatedByUid: actorUid,
      FirestoreFields.createdByName: FirestoreCompat.readString(
        doc.data() ?? const <String, dynamic>{},
        [FirestoreFields.createdByName],
        fallback: actorName,
      ),
    }, SetOptions(merge: true));
  }

  @override
  Stream<List<EventCampaign>> watchEventsList() {
    return _firestore.collection(FirestoreCollections.events).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(EventCampaign.fromDoc).toList();
      items.sort((a, b) {
        final aRank = _lifecycleRank(a.lifecycleStatus);
        final bRank = _lifecycleRank(b.lifecycleStatus);
        if (aRank != bRank) {
          return aRank.compareTo(bRank);
        }

        final aDate =
            a.eventStartAt ??
            a.registrationOpenAt ??
            a.targetDeadline ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.eventStartAt ??
            b.registrationOpenAt ??
            b.targetDeadline ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return items;
    });
  }

  @override
  Stream<EventCampaign?> watchEventById(String eventId) {
    return _firestore
        .collection(FirestoreCollections.events)
        .doc(eventId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return EventCampaign.fromDoc(doc);
        });
  }

  @override
  Stream<EventCampaign?> watchActiveEvent() {
    return watchEventsList().map((items) {
      for (final item in items) {
        if (item.lifecycleStatus == 'enrollment_open' ||
            item.lifecycleStatus == 'running' ||
            item.status.toLowerCase() == 'active') {
          return item;
        }
      }
      return items.isEmpty ? null : items.first;
    });
  }

  @override
  Future<EventCampaign?> fetchEventById(String eventId) async {
    final doc = await _firestore
        .collection(FirestoreCollections.events)
        .doc(eventId)
        .get();
    if (!doc.exists) {
      return null;
    }
    return EventCampaign.fromDoc(doc);
  }

  @override
  Stream<List<EventRegistration>> watchRegistrations({
    required String eventId,
    required String role,
    required String currentUid,
  }) {
    final privileged = _isPrivileged(role);
    var query = _firestore
        .collection(FirestoreCollections.eventRegistrations)
        .where(FirestoreFields.eventId, isEqualTo: eventId);

    if (!privileged) {
      query = query.where(
        FirestoreFields.participantUid,
        isEqualTo: currentUid,
      );
    }

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs.map(EventRegistration.fromDoc).toList();
      items.sort((a, b) {
        final aDate =
            a.updatedAt ??
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.updatedAt ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return items;
    });
  }

  @override
  Stream<EventRegistration?> watchRegistrationById(String registrationId) {
    return _firestore
        .collection(FirestoreCollections.eventRegistrations)
        .doc(registrationId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return null;
          }
          return EventRegistration.fromDoc(doc);
        });
  }

  @override
  Future<EventRegistration?> fetchRegistrationById(
    String registrationId,
  ) async {
    final doc = await _firestore
        .collection(FirestoreCollections.eventRegistrations)
        .doc(registrationId)
        .get();
    if (!doc.exists) {
      return null;
    }
    return EventRegistration.fromDoc(doc);
  }

  @override
  Future<EventRegistration?> fetchMyRegistration({
    required String eventId,
    required String participantUid,
  }) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.eventRegistrations)
        .where(FirestoreFields.eventId, isEqualTo: eventId)
        .where(FirestoreFields.participantUid, isEqualTo: participantUid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }
    return EventRegistration.fromDoc(snapshot.docs.first);
  }

  @override
  Stream<List<EventPayment>> watchPayments({
    required String registrationId,
    required String role,
    required String currentUid,
  }) {
    final privileged = _isPrivileged(role);
    var query = _firestore
        .collection(FirestoreCollections.eventPayments)
        .where(FirestoreFields.registrationId, isEqualTo: registrationId);

    if (!privileged) {
      query = query.where(
        FirestoreFields.participantUid,
        isEqualTo: currentUid,
      );
    }

    return query.snapshots().map((snapshot) {
      final payments = snapshot.docs.map(EventPayment.fromDoc).toList();
      payments.sort((a, b) {
        final aTime =
            a.collectedAt?.millisecondsSinceEpoch ??
            a.createdAt?.millisecondsSinceEpoch ??
            0;
        final bTime =
            b.collectedAt?.millisecondsSinceEpoch ??
            b.createdAt?.millisecondsSinceEpoch ??
            0;
        return bTime.compareTo(aTime);
      });
      return payments;
    });
  }

  @override
  Stream<List<EventMessage>> watchMessages({
    required String registrationId,
    required String role,
    required String currentUid,
  }) {
    final privileged = _isPrivileged(role);
    var query = _firestore
        .collection(FirestoreCollections.eventMessages)
        .where(FirestoreFields.registrationId, isEqualTo: registrationId);

    if (!privileged) {
      query = query.where(
        FirestoreFields.participantUid,
        isEqualTo: currentUid,
      );
    }

    return query.snapshots().map((snapshot) {
      final messages = snapshot.docs.map(EventMessage.fromDoc).toList();
      messages.sort((a, b) {
        final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });
      return messages;
    });
  }

  @override
  Future<String> upsertRegistration({
    required EventCampaign event,
    required EventRegistration draft,
    required String actorUid,
    required String actorName,
    required bool submit,
  }) async {
    final normalizedPhone = normalizePhone(draft.participantPhone);
    final registrationId = buildRegistrationId(event.id, normalizedPhone);
    final docRef = _firestore
        .collection(FirestoreCollections.eventRegistrations)
        .doc(registrationId);

    final existingDoc = await docRef.get();
    final existing = existingDoc.exists
        ? EventRegistration.fromDoc(existingDoc)
        : null;
    final existingData = existingDoc.data() ?? <String, dynamic>{};

    final manualAdjustments =
        existing?.manualAdjustments ?? draft.manualAdjustments;

    final medicineIssuedAmount = await _sumDeliveredOrdersByRegistration(
      registrationId,
    );
    final manualTotal = _sumAdjustments(manualAdjustments);
    final finalAchievedAmount = medicineIssuedAmount + manualTotal;

    final totalPaidAmount = existing?.totalPaidAmount ?? 0.0;
    final dueAmount = _dueAmount(
      medicineIssuedAmount: medicineIssuedAmount,
      totalPaidAmount: totalPaidAmount,
    );
    final advanceAmount = _advanceAmount(
      medicineIssuedAmount: medicineIssuedAmount,
      totalPaidAmount: totalPaidAmount,
    );

    final remainingAmount = (event.targetAmount - finalAchievedAmount) < 0
        ? 0.0
        : (event.targetAmount - finalAchievedAmount);
    final targetSnapshot = _resolveTargetSnapshot(
      financialBaseAmount: existing?.financialBaseAmount ?? 0,
      eventTargetAmount: event.targetAmount,
    );
    final eligibilityStatus = _eligibilityStatus(
      medicineIssuedAmount: medicineIssuedAmount,
      targetAmount: targetSnapshot,
    );

    final companionCount = draft.willBringCompanion ? draft.companionCount : 0;
    final companionExtraCharge = draft.willBringCompanion
        ? (companionCount * event.extraChargePerHead).toDouble()
        : 0.0;

    final baseApprovalStatus = existing?.approvalStatus.isNotEmpty == true
        ? existing!.approvalStatus
        : 'draft';
    final approvalStatus = submit
        ? 'submitted'
        : (baseApprovalStatus == 'approved' || baseApprovalStatus == 'rejected'
              ? baseApprovalStatus
              : 'draft');

    final enrollmentStatus = existing?.enrollmentStatus.isNotEmpty == true
        ? existing!.enrollmentStatus
        : 'enrolled';
    final enrolledAt = existing?.enrolledAt ?? DateTime.now();
    final enrolledByUid = existing?.enrolledByUid.isNotEmpty == true
        ? existing!.enrolledByUid
        : actorUid;
    final enrolledByName = existing?.enrolledByName.isNotEmpty == true
        ? existing!.enrolledByName
        : actorName;

    final billingStatus = existing?.billingStatus.isNotEmpty == true
        ? existing!.billingStatus
        : 'open';

    final registration = draft.copyWith(
      id: registrationId,
      eventId: event.id,
      participantPhoneNormalized: normalizedPhone,
      companionCount: companionCount,
      companionExtraCharge: companionExtraCharge,
      manualAdjustments: manualAdjustments,
      autoAchievedAmount: medicineIssuedAmount,
      finalAchievedAmount: finalAchievedAmount,
      remainingAmount: remainingAmount,
      medicineIssuedAmount: medicineIssuedAmount,
      financialBaseAmount: existing?.financialBaseAmount ?? event.targetAmount,
      totalPaidAmount: totalPaidAmount,
      dueAmount: dueAmount,
      advanceAmount: advanceAmount,
      financeUpdatedByUid: actorUid,
      financeUpdatedAt: DateTime.now(),
      eligibilityStatus: eligibilityStatus,
      approvalStatus: approvalStatus,
      approvalNote: existing?.approvalNote ?? '',
      approvedByUid: existing?.approvedByUid ?? '',
      approvedAt: existing?.approvedAt,
      enrollmentStatus: enrollmentStatus,
      enrolledAt: enrolledAt,
      enrolledByUid: enrolledByUid,
      enrolledByName: enrolledByName,
      billingStatus: billingStatus,
      billingCloseRequestedAt: existing?.billingCloseRequestedAt,
      billingCloseRequestedByUid: existing?.billingCloseRequestedByUid,
      billingCloseRequestedByName: existing?.billingCloseRequestedByName,
      billingClosedAt: existing?.billingClosedAt,
      billingClosedByUid: existing?.billingClosedByUid,
      billingClosedByName: existing?.billingClosedByName,
      billingCloseNote: existing?.billingCloseNote,
      welcomePromptedAt: existing?.welcomePromptedAt,
      congratsPromptedAt: existing?.congratsPromptedAt,
    );

    final createdByUid = FirestoreCompat.readString(existingData, [
      FirestoreFields.createdByUid,
    ], fallback: actorUid);

    await docRef.set(
      registration.toMap(
        createdByUid: createdByUid,
        updatedByUid: actorUid,
        includeCreatedAt: !existingDoc.exists,
      ),
      SetOptions(merge: true),
    );

    return registrationId;
  }

  @override
  Future<void> submitRegistration({
    required String registrationId,
    required EventCampaign event,
    required String actorUid,
    required String actorName,
  }) async {
    await _recomputeAndUpdate(
      registrationId: registrationId,
      event: event,
      actorUid: actorUid,
      actorName: actorName,
      approvalStatusOverride: 'submitted',
    );
  }

  @override
  Future<void> setApproval({
    required String registrationId,
    required EventCampaign event,
    required String approvalStatus,
    required String note,
    required String actorUid,
    required String actorName,
  }) async {
    await _recomputeAndUpdate(
      registrationId: registrationId,
      event: event,
      actorUid: actorUid,
      actorName: actorName,
      approvalStatusOverride: approvalStatus,
      approvalNoteOverride: note,
      approvedByUidOverride: actorUid,
      approvedAtOverride: DateTime.now(),
    );
  }

  @override
  Future<void> addManualAdjustment({
    required String registrationId,
    required EventCampaign event,
    required double amount,
    required String reason,
    required String actorUid,
    required String actorName,
  }) async {
    final current = await fetchRegistrationById(registrationId);
    if (current == null) {
      throw Exception('Registration not found.');
    }

    final items = [...current.manualAdjustments];
    items.add(
      EventAdjustment(
        amount: amount,
        reason: reason,
        at: DateTime.now(),
        byUid: actorUid,
        byName: actorName,
      ),
    );

    await _recomputeAndUpdate(
      registrationId: registrationId,
      event: event,
      actorUid: actorUid,
      actorName: actorName,
      manualAdjustmentsOverride: items,
    );
  }

  @override
  Future<void> removeManualAdjustment({
    required String registrationId,
    required EventCampaign event,
    required int index,
    required String actorUid,
    required String actorName,
  }) async {
    final current = await fetchRegistrationById(registrationId);
    if (current == null) {
      throw Exception('Registration not found.');
    }

    final items = [...current.manualAdjustments];
    if (index < 0 || index >= items.length) {
      return;
    }
    items.removeAt(index);

    await _recomputeAndUpdate(
      registrationId: registrationId,
      event: event,
      actorUid: actorUid,
      actorName: actorName,
      manualAdjustmentsOverride: items,
    );
  }

  @override
  Future<void> recalculateProgress({
    required String registrationId,
    required EventCampaign event,
    required String actorUid,
    required String actorName,
  }) async {
    await _recomputeAndUpdate(
      registrationId: registrationId,
      event: event,
      actorUid: actorUid,
      actorName: actorName,
    );
  }

  @override
  Future<void> addPayment({
    required EventCampaign event,
    required String registrationId,
    required double amount,
    required String paymentMethod,
    required String note,
    required String actorUid,
    required String actorName,
  }) async {
    if (amount <= 0) {
      throw Exception('Payment amount must be greater than zero.');
    }

    final paymentRef = _firestore
        .collection(FirestoreCollections.eventPayments)
        .doc();
    final registrationRef = _firestore
        .collection(FirestoreCollections.eventRegistrations)
        .doc(registrationId);

    await _firestore.runTransaction((transaction) async {
      final registrationDoc = await transaction.get(registrationRef);
      if (!registrationDoc.exists) {
        throw Exception('Registration not found.');
      }

      final registration = EventRegistration.fromDoc(registrationDoc);
      final nextTotalPaid = registration.totalPaidAmount + amount;
      final dueAmount = _dueAmount(
        medicineIssuedAmount: registration.medicineIssuedAmount,
        totalPaidAmount: nextTotalPaid,
      );
      final advanceAmount = _advanceAmount(
        medicineIssuedAmount: registration.medicineIssuedAmount,
        totalPaidAmount: nextTotalPaid,
      );

      transaction.set(paymentRef, {
        FirestoreFields.eventId: event.id,
        FirestoreFields.registrationId: registration.id,
        FirestoreFields.participantUid: registration.participantUid,
        FirestoreFields.participantName: registration.participantName,
        FirestoreFields.participantPhone: registration.participantPhone,
        FirestoreFields.amount: amount,
        FirestoreFields.paymentMethod: paymentMethod,
        FirestoreFields.note: note,
        FirestoreFields.collectedByUid: actorUid,
        FirestoreFields.collectedByName: actorName,
        FirestoreFields.collectedAt: FieldValue.serverTimestamp(),
        FirestoreFields.createdAt: FieldValue.serverTimestamp(),
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      });

      transaction.set(registrationRef, {
        FirestoreFields.totalPaidAmount: nextTotalPaid,
        FirestoreFields.dueAmount: dueAmount,
        FirestoreFields.advanceAmount: advanceAmount,
        FirestoreFields.eligibilityStatus: _eligibilityStatus(
          medicineIssuedAmount: registration.medicineIssuedAmount,
          targetAmount: _resolveTargetSnapshot(
            financialBaseAmount: registration.financialBaseAmount,
            eventTargetAmount: event.targetAmount,
          ),
        ),
        FirestoreFields.financeUpdatedAt: FieldValue.serverTimestamp(),
        FirestoreFields.financeUpdatedByUid: actorUid,
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        FirestoreFields.updatedByUid: actorUid,
      }, SetOptions(merge: true));
    });
  }

  @override
  Future<void> updatePayment({
    required EventCampaign event,
    required String paymentId,
    required double amount,
    required String paymentMethod,
    required String note,
    required String actorUid,
    required String actorName,
  }) async {
    if (amount <= 0) {
      throw Exception('Payment amount must be greater than zero.');
    }

    final paymentRef = _firestore
        .collection(FirestoreCollections.eventPayments)
        .doc(paymentId);

    await _firestore.runTransaction((transaction) async {
      final paymentDoc = await transaction.get(paymentRef);
      if (!paymentDoc.exists) {
        throw Exception('Payment not found.');
      }

      final paymentData = paymentDoc.data() ?? <String, dynamic>{};
      final registrationId = FirestoreCompat.readString(paymentData, [
        FirestoreFields.registrationId,
      ]);
      if (registrationId.isEmpty) {
        throw Exception('Payment registration reference missing.');
      }

      final registrationRef = _firestore
          .collection(FirestoreCollections.eventRegistrations)
          .doc(registrationId);
      final registrationDoc = await transaction.get(registrationRef);
      if (!registrationDoc.exists) {
        throw Exception('Registration not found.');
      }

      final registration = EventRegistration.fromDoc(registrationDoc);
      final previousAmount = FirestoreCompat.readDouble(paymentData, [
        FirestoreFields.amount,
      ]);

      final nextTotalPaid =
          (registration.totalPaidAmount - previousAmount + amount).clamp(
            0.0,
            double.infinity,
          );
      final dueAmount = _dueAmount(
        medicineIssuedAmount: registration.medicineIssuedAmount,
        totalPaidAmount: nextTotalPaid,
      );
      final advanceAmount = _advanceAmount(
        medicineIssuedAmount: registration.medicineIssuedAmount,
        totalPaidAmount: nextTotalPaid,
      );

      transaction.set(paymentRef, {
        FirestoreFields.amount: amount,
        FirestoreFields.paymentMethod: paymentMethod,
        FirestoreFields.note: note,
        FirestoreFields.collectedByUid: actorUid,
        FirestoreFields.collectedByName: actorName,
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(registrationRef, {
        FirestoreFields.totalPaidAmount: nextTotalPaid,
        FirestoreFields.dueAmount: dueAmount,
        FirestoreFields.advanceAmount: advanceAmount,
        FirestoreFields.eligibilityStatus: _eligibilityStatus(
          medicineIssuedAmount: registration.medicineIssuedAmount,
          targetAmount: _resolveTargetSnapshot(
            financialBaseAmount: registration.financialBaseAmount,
            eventTargetAmount: event.targetAmount,
          ),
        ),
        FirestoreFields.financeUpdatedAt: FieldValue.serverTimestamp(),
        FirestoreFields.financeUpdatedByUid: actorUid,
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        FirestoreFields.updatedByUid: actorUid,
      }, SetOptions(merge: true));
    });
  }

  @override
  Future<void> deletePayment({
    required EventCampaign event,
    required String paymentId,
    required String actorUid,
    required String actorName,
  }) async {
    final paymentRef = _firestore
        .collection(FirestoreCollections.eventPayments)
        .doc(paymentId);

    await _firestore.runTransaction((transaction) async {
      final paymentDoc = await transaction.get(paymentRef);
      if (!paymentDoc.exists) {
        throw Exception('Payment not found.');
      }

      final paymentData = paymentDoc.data() ?? <String, dynamic>{};
      final registrationId = FirestoreCompat.readString(paymentData, [
        FirestoreFields.registrationId,
      ]);
      if (registrationId.isEmpty) {
        throw Exception('Payment registration reference missing.');
      }

      final registrationRef = _firestore
          .collection(FirestoreCollections.eventRegistrations)
          .doc(registrationId);
      final registrationDoc = await transaction.get(registrationRef);
      if (!registrationDoc.exists) {
        throw Exception('Registration not found.');
      }

      final registration = EventRegistration.fromDoc(registrationDoc);
      final previousAmount = FirestoreCompat.readDouble(paymentData, [
        FirestoreFields.amount,
      ]);
      final nextTotalPaid = (registration.totalPaidAmount - previousAmount)
          .clamp(0.0, double.infinity);
      final dueAmount = _dueAmount(
        medicineIssuedAmount: registration.medicineIssuedAmount,
        totalPaidAmount: nextTotalPaid,
      );
      final advanceAmount = _advanceAmount(
        medicineIssuedAmount: registration.medicineIssuedAmount,
        totalPaidAmount: nextTotalPaid,
      );

      transaction.delete(paymentRef);

      transaction.set(registrationRef, {
        FirestoreFields.totalPaidAmount: nextTotalPaid,
        FirestoreFields.dueAmount: dueAmount,
        FirestoreFields.advanceAmount: advanceAmount,
        FirestoreFields.eligibilityStatus: _eligibilityStatus(
          medicineIssuedAmount: registration.medicineIssuedAmount,
          targetAmount: _resolveTargetSnapshot(
            financialBaseAmount: registration.financialBaseAmount,
            eventTargetAmount: event.targetAmount,
          ),
        ),
        FirestoreFields.financeUpdatedAt: FieldValue.serverTimestamp(),
        FirestoreFields.financeUpdatedByUid: actorUid,
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        FirestoreFields.updatedByUid: actorUid,
      }, SetOptions(merge: true));
    });
  }

  @override
  Future<void> recomputeFinanceSnapshot({
    required String registrationId,
    required EventCampaign event,
    required String actorUid,
    required String actorName,
  }) async {
    await recomputeRegistrationFinanceFromOrders(
      registrationId: registrationId,
      event: event,
      actorUid: actorUid,
      actorName: actorName,
    );
  }

  @override
  Future<bool> recomputeRegistrationFinanceFromOrders({
    required String registrationId,
    required EventCampaign event,
    required String actorUid,
    required String actorName,
  }) async {
    final registrationRef = _firestore
        .collection(FirestoreCollections.eventRegistrations)
        .doc(registrationId);
    final registrationDoc = await registrationRef.get();
    if (!registrationDoc.exists) {
      throw Exception('Registration not found.');
    }

    final registration = EventRegistration.fromDoc(registrationDoc);
    final medicineIssuedAmount = await _sumDeliveredOrdersByRegistration(
      registrationId,
    );
    final totalPaid = await _sumPaymentsByRegistration(registrationId);

    final dueAmount = _dueAmount(
      medicineIssuedAmount: medicineIssuedAmount,
      totalPaidAmount: totalPaid,
    );
    final advanceAmount = _advanceAmount(
      medicineIssuedAmount: medicineIssuedAmount,
      totalPaidAmount: totalPaid,
    );

    final nextEligibilityStatus = _eligibilityStatus(
      medicineIssuedAmount: medicineIssuedAmount,
      targetAmount: _resolveTargetSnapshot(
        financialBaseAmount: registration.financialBaseAmount,
        eventTargetAmount: event.targetAmount,
      ),
    );
    final becameEligible =
        !registration.isEligible && nextEligibilityStatus == 'eligible';

    final manualTotal = registration.manualAdjustmentTotal;
    final finalAchievedAmount = medicineIssuedAmount + manualTotal;
    final remainingAmount = (event.targetAmount - finalAchievedAmount) < 0
        ? 0.0
        : (event.targetAmount - finalAchievedAmount);

    await registrationRef.set({
      FirestoreFields.medicineIssuedAmount: medicineIssuedAmount,
      FirestoreFields.autoAchievedAmount: medicineIssuedAmount,
      FirestoreFields.finalAchievedAmount: finalAchievedAmount,
      FirestoreFields.remainingAmount: remainingAmount,
      FirestoreFields.totalPaidAmount: totalPaid,
      FirestoreFields.dueAmount: dueAmount,
      FirestoreFields.advanceAmount: advanceAmount,
      FirestoreFields.eligibilityStatus: nextEligibilityStatus,
      FirestoreFields.financeUpdatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.financeUpdatedByUid: actorUid,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.updatedByUid: actorUid,
    }, SetOptions(merge: true));

    return becameEligible;
  }

  @override
  Future<void> requestBillingClose({
    required String registrationId,
    required String actorUid,
    required String actorName,
    required String note,
  }) async {
    await _firestore
        .collection(FirestoreCollections.eventRegistrations)
        .doc(registrationId)
        .set({
          FirestoreFields.billingStatus: 'close_requested',
          FirestoreFields.billingCloseRequestedAt: FieldValue.serverTimestamp(),
          FirestoreFields.billingCloseRequestedByUid: actorUid,
          FirestoreFields.billingCloseRequestedByName: actorName,
          FirestoreFields.billingCloseNote: note,
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
          FirestoreFields.updatedByUid: actorUid,
        }, SetOptions(merge: true));
  }

  @override
  Future<void> approveBillingClose({
    required String registrationId,
    required String actorUid,
    required String actorName,
    required String note,
  }) async {
    await _firestore
        .collection(FirestoreCollections.eventRegistrations)
        .doc(registrationId)
        .set({
          FirestoreFields.billingStatus: 'closed',
          FirestoreFields.billingClosedAt: FieldValue.serverTimestamp(),
          FirestoreFields.billingClosedByUid: actorUid,
          FirestoreFields.billingClosedByName: actorName,
          FirestoreFields.billingCloseNote: note,
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
          FirestoreFields.updatedByUid: actorUid,
        }, SetOptions(merge: true));
  }

  @override
  Future<void> rejectBillingClose({
    required String registrationId,
    required String actorUid,
    required String actorName,
    required String note,
  }) async {
    await _firestore
        .collection(FirestoreCollections.eventRegistrations)
        .doc(registrationId)
        .set({
          FirestoreFields.billingStatus: 'open',
          FirestoreFields.billingCloseNote: note,
          FirestoreFields.billingCloseRequestedAt: null,
          FirestoreFields.billingCloseRequestedByUid: '',
          FirestoreFields.billingCloseRequestedByName: '',
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
          FirestoreFields.updatedByUid: actorUid,
        }, SetOptions(merge: true));
  }

  @override
  Future<void> logEventMessage({
    required String eventId,
    required String registrationId,
    required String participantUid,
    required String participantPhone,
    required String messageType,
    required String messageBody,
    required String launchResult,
    required String triggerSource,
    required String actorUid,
    required String actorName,
  }) async {
    await _firestore.collection(FirestoreCollections.eventMessages).add({
      FirestoreFields.eventId: eventId,
      FirestoreFields.registrationId: registrationId,
      FirestoreFields.participantUid: participantUid,
      FirestoreFields.participantPhone: participantPhone,
      FirestoreFields.messageType: messageType,
      FirestoreFields.messageBody: messageBody,
      FirestoreFields.deliveryMode: 'sms_intent',
      FirestoreFields.launchResult: launchResult,
      FirestoreFields.triggerSource: triggerSource,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.createdByUid: actorUid,
      FirestoreFields.createdByName: actorName,
    });

    final promptField = messageType == 'welcome'
        ? FirestoreFields.welcomePromptedAt
        : messageType == 'congrats'
        ? FirestoreFields.congratsPromptedAt
        : '';

    if (promptField.isNotEmpty) {
      await _firestore
          .collection(FirestoreCollections.eventRegistrations)
          .doc(registrationId)
          .set({
            promptField: FieldValue.serverTimestamp(),
            FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
            FirestoreFields.updatedByUid: actorUid,
          }, SetOptions(merge: true));
    }
  }

  Future<void> _recomputeAndUpdate({
    required String registrationId,
    required EventCampaign event,
    required String actorUid,
    required String actorName,
    String? approvalStatusOverride,
    String? approvalNoteOverride,
    String? approvedByUidOverride,
    DateTime? approvedAtOverride,
    List<EventAdjustment>? manualAdjustmentsOverride,
  }) async {
    final docRef = _firestore
        .collection(FirestoreCollections.eventRegistrations)
        .doc(registrationId);

    final doc = await docRef.get();
    if (!doc.exists) {
      throw Exception('Registration not found.');
    }

    final current = EventRegistration.fromDoc(doc);
    final manualAdjustments =
        manualAdjustmentsOverride ?? current.manualAdjustments;

    final medicineIssuedAmount = await _sumDeliveredOrdersByRegistration(
      registrationId,
    );
    final manualTotal = _sumAdjustments(manualAdjustments);
    final finalAchievedAmount = medicineIssuedAmount + manualTotal;
    final remainingAmount = (event.targetAmount - finalAchievedAmount) < 0
        ? 0.0
        : (event.targetAmount - finalAchievedAmount);
    final dueAmount = _dueAmount(
      medicineIssuedAmount: medicineIssuedAmount,
      totalPaidAmount: current.totalPaidAmount,
    );
    final eligibilityStatus = _eligibilityStatus(
      medicineIssuedAmount: medicineIssuedAmount,
      targetAmount: _resolveTargetSnapshot(
        financialBaseAmount: current.financialBaseAmount,
        eventTargetAmount: event.targetAmount,
      ),
    );

    final next = current.copyWith(
      manualAdjustments: manualAdjustments,
      medicineIssuedAmount: medicineIssuedAmount,
      autoAchievedAmount: medicineIssuedAmount,
      finalAchievedAmount: finalAchievedAmount,
      remainingAmount: remainingAmount,
      dueAmount: dueAmount,
      eligibilityStatus: eligibilityStatus,
      approvalStatus: approvalStatusOverride ?? current.approvalStatus,
      approvalNote: approvalNoteOverride ?? current.approvalNote,
      approvedByUid: approvedByUidOverride ?? current.approvedByUid,
      approvedAt: approvedAtOverride ?? current.approvedAt,
      financeUpdatedByUid: actorUid,
      financeUpdatedAt: DateTime.now(),
    );

    final existingData = doc.data() ?? <String, dynamic>{};
    final createdByUid = FirestoreCompat.readString(existingData, [
      FirestoreFields.createdByUid,
    ], fallback: actorUid);

    await docRef.set(
      next.toMap(createdByUid: createdByUid, updatedByUid: actorUid),
      SetOptions(merge: true),
    );
  }

  Future<double> _sumDeliveredOrdersByRegistration(
    String registrationId,
  ) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.orders)
        .where(FirestoreFields.eventRegistrationId, isEqualTo: registrationId)
        .where(FirestoreFields.status, isEqualTo: 'Delivered')
        .get();

    var total = 0.0;
    for (final doc in snapshot.docs) {
      total += FirestoreCompat.readDouble(doc.data(), [
        FirestoreFields.totalAmount,
        FirestoreFields.amount,
      ]);
    }
    return total;
  }

  Future<double> _sumPaymentsByRegistration(String registrationId) async {
    final paymentDocs = await _firestore
        .collection(FirestoreCollections.eventPayments)
        .where(FirestoreFields.registrationId, isEqualTo: registrationId)
        .get();

    var totalPaid = 0.0;
    for (final doc in paymentDocs.docs) {
      totalPaid += FirestoreCompat.readDouble(doc.data(), [
        FirestoreFields.amount,
      ]);
    }
    return totalPaid;
  }

  static double _sumAdjustments(List<EventAdjustment> items) {
    var total = 0.0;
    for (final item in items) {
      total += item.amount;
    }
    return total;
  }

  static double _dueAmount({
    required double medicineIssuedAmount,
    required double totalPaidAmount,
  }) {
    final due = medicineIssuedAmount - totalPaidAmount;
    if (due <= 0) {
      return 0.0;
    }
    return due;
  }

  static double _advanceAmount({
    required double medicineIssuedAmount,
    required double totalPaidAmount,
  }) {
    final advance = totalPaidAmount - medicineIssuedAmount;
    if (advance <= 0) {
      return 0.0;
    }
    return advance;
  }

  static String _eligibilityStatus({
    required double medicineIssuedAmount,
    required double targetAmount,
  }) {
    if (targetAmount > 0 && medicineIssuedAmount >= targetAmount) {
      return 'eligible';
    }
    return 'not_eligible';
  }

  static double _resolveTargetSnapshot({
    required double financialBaseAmount,
    required double eventTargetAmount,
  }) {
    if (financialBaseAmount > 0) {
      return financialBaseAmount;
    }
    if (eventTargetAmount > 0) {
      return eventTargetAmount;
    }
    return 0;
  }

  static bool _isPrivileged(String role) {
    return role == 'Owner' || role == 'Manager';
  }

  static int _lifecycleRank(String status) {
    switch (status) {
      case 'enrollment_open':
      case 'running':
        return 0;
      case 'draft':
        return 1;
      case 'closed':
        return 2;
      case 'archived':
        return 3;
      default:
        return 4;
    }
  }

  static String _legacyStatusFromLifecycle(String lifecycle) {
    switch (lifecycle) {
      case 'enrollment_open':
      case 'running':
        return 'active';
      case 'closed':
        return 'closed';
      case 'archived':
        return 'archived';
      default:
        return 'draft';
    }
  }

  static String normalizePhone(String value) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final ch = value.codeUnitAt(i);
      if (ch >= 48 && ch <= 57) {
        buffer.writeCharCode(ch);
      }
    }
    final result = buffer.toString();
    if (result.length >= 11 && result.startsWith('880')) {
      return '0${result.substring(3)}';
    }
    return result;
  }

  static String buildRegistrationId(String eventId, String normalizedPhone) {
    final normalizedEvent = eventId.replaceAll('/', '_').trim();
    final normalizedNumber = normalizedPhone.isEmpty
        ? 'unknown'
        : normalizedPhone;
    return '${normalizedEvent}_$normalizedNumber';
  }
}
