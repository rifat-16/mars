import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../core/compat/firestore_compat.dart';
import '../../core/constants/firestore_keys.dart';
import '../../models/domain/event_assignment_option.dart';
import '../../models/domain/event_registration.dart';
import '../../models/domain/order.dart';
import '../../models/domain/order_item.dart';

abstract class OrdersRepository {
  Stream<List<Order>> watchOrders({
    required String role,
    required String userPhone,
  });
  Stream<Order?> watchOrderById(String orderId);
  Future<Map<String, double>> fetchMedicinePrices();
  Future<List<Map<String, String>>> fetchPreviousCustomers();
  Future<List<EventAssignmentOption>> fetchEventAssignmentOptions({
    required String role,
    required String currentUid,
  });
  Future<void> createOrder({
    required String customerName,
    required String address,
    required String phoneNumber,
    required List<OrderItem> items,
    required double totalAmount,
    String? eventId,
    String? eventRegistrationId,
    String? eventParticipantUid,
  });
  Future<void> markOrderDelivered({
    required String orderId,
    required List<OrderItem> items,
    required String actorUid,
    required String actorName,
  });
}

class FirebaseOrdersRepository implements OrdersRepository {
  final FirebaseFirestore _firestore;

  FirebaseOrdersRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Order>> watchOrders({
    required String role,
    required String userPhone,
  }) {
    final isPrivileged = role == 'Owner' || role == 'Manager';
    final base = _firestore.collection(FirestoreCollections.orders);
    final query = isPrivileged
        ? base
        : base.where(FirestoreFields.phoneNumber, isEqualTo: userPhone);

    return query.snapshots().map((snapshot) {
      final orders = snapshot.docs.map(Order.fromDoc).toList();
      orders.sort((a, b) {
        if (a.isPending && !b.isPending) return -1;
        if (!a.isPending && b.isPending) return 1;
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return orders;
    });
  }

  @override
  Stream<Order?> watchOrderById(String orderId) {
    return _firestore
        .collection(FirestoreCollections.orders)
        .doc(orderId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return null;
          }
          return Order.fromDoc(doc);
        });
  }

  @override
  Future<Map<String, double>> fetchMedicinePrices() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.medicines)
        .get();
    final products = <String, double>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = FirestoreCompat.readString(data, [
        FirestoreFields.name,
        FirestoreFields.medicineName,
        FirestoreFields.productName,
      ]);
      if (name.isEmpty) {
        continue;
      }
      final price = FirestoreCompat.readDouble(data, [
        FirestoreFields.tpUpper,
        FirestoreFields.tp,
      ]);
      products[name] = price;
    }

    return products;
  }

  @override
  Future<List<Map<String, String>>> fetchPreviousCustomers() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.orders)
        .get();
    final uniqueCustomers = <String, Map<String, String>>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final phone = FirestoreCompat.readString(data, [
        FirestoreFields.phoneNumber,
      ]);
      if (phone.isEmpty || uniqueCustomers.containsKey(phone)) {
        continue;
      }
      uniqueCustomers[phone] = {
        'name': FirestoreCompat.readString(data, [
          FirestoreFields.customerName,
        ]),
        'address': FirestoreCompat.readString(data, [FirestoreFields.address]),
        'phone': phone,
      };
    }
    return uniqueCustomers.values.toList();
  }

  @override
  Future<List<EventAssignmentOption>> fetchEventAssignmentOptions({
    required String role,
    required String currentUid,
  }) async {
    final privileged = role == 'Owner' || role == 'Manager';

    final eventsSnapshot = await _firestore
        .collection(FirestoreCollections.events)
        .get();
    final eventMeta = <String, Map<String, String>>{};
    for (final doc in eventsSnapshot.docs) {
      final data = doc.data();
      final lifecycle = FirestoreCompat.readString(data, [
        FirestoreFields.lifecycleStatus,
      ], fallback: FirestoreCompat.readString(data, [FirestoreFields.status]));

      if (lifecycle == 'closed' || lifecycle == 'archived') {
        continue;
      }

      eventMeta[doc.id] = {
        'title': FirestoreCompat.readString(data, [
          FirestoreFields.title,
          FirestoreFields.name,
        ], fallback: doc.id),
        'lifecycle': lifecycle,
      };
    }

    if (eventMeta.isEmpty) {
      return const [];
    }

    Query<Map<String, dynamic>> registrationQuery = _firestore.collection(
      FirestoreCollections.eventRegistrations,
    );
    if (!privileged) {
      registrationQuery = registrationQuery.where(
        FirestoreFields.participantUid,
        isEqualTo: currentUid,
      );
    }

    final registrationSnapshot = await registrationQuery.get();
    final options = <EventAssignmentOption>[];

    for (final doc in registrationSnapshot.docs) {
      final data = doc.data();
      final eventId = FirestoreCompat.readString(data, [
        FirestoreFields.eventId,
      ]);
      if (eventId.isEmpty || !eventMeta.containsKey(eventId)) {
        continue;
      }

      final enrollmentStatus = FirestoreCompat.readString(data, [
        FirestoreFields.enrollmentStatus,
      ], fallback: 'enrolled');
      if (enrollmentStatus != 'enrolled') {
        continue;
      }

      final billingStatus = FirestoreCompat.readString(data, [
        FirestoreFields.billingStatus,
      ], fallback: 'open');
      if (billingStatus == 'closed') {
        continue;
      }

      options.add(
        EventAssignmentOption.fromMap(
          data,
          eventTitle: eventMeta[eventId]!['title'] ?? eventId,
          registrationId: doc.id,
        ),
      );
    }

    options.sort((a, b) {
      final eventCompare = a.eventTitle.toLowerCase().compareTo(
        b.eventTitle.toLowerCase(),
      );
      if (eventCompare != 0) return eventCompare;
      return a.participantName.toLowerCase().compareTo(
        b.participantName.toLowerCase(),
      );
    });

    return options;
  }

  @override
  Future<void> createOrder({
    required String customerName,
    required String address,
    required String phoneNumber,
    required List<OrderItem> items,
    required double totalAmount,
    String? eventId,
    String? eventRegistrationId,
    String? eventParticipantUid,
  }) async {
    var resolvedEventId = (eventId ?? '').trim();
    var resolvedRegistrationId = (eventRegistrationId ?? '').trim();
    var resolvedParticipantUid = (eventParticipantUid ?? '').trim();

    if (resolvedRegistrationId.isNotEmpty) {
      final regRef = _firestore
          .collection(FirestoreCollections.eventRegistrations)
          .doc(resolvedRegistrationId);
      final regDoc = await regRef.get();
      if (!regDoc.exists) {
        throw Exception('Selected event enrollment was not found.');
      }

      final regData = regDoc.data() ?? <String, dynamic>{};
      final regEventId = FirestoreCompat.readString(regData, [
        FirestoreFields.eventId,
      ]);
      final billingStatus = FirestoreCompat.readString(regData, [
        FirestoreFields.billingStatus,
      ], fallback: 'open');

      if (billingStatus == 'closed') {
        throw Exception('Billing is already closed for this enrollment.');
      }

      if (resolvedEventId.isNotEmpty &&
          regEventId.isNotEmpty &&
          regEventId != resolvedEventId) {
        throw Exception('Enrollment event does not match selected event.');
      }

      resolvedEventId = regEventId;
      if (resolvedParticipantUid.isEmpty) {
        resolvedParticipantUid = FirestoreCompat.readString(regData, [
          FirestoreFields.participantUid,
        ]);
      }
    } else {
      resolvedEventId = '';
      resolvedParticipantUid = '';
    }

    final payload = <String, dynamic>{
      FirestoreFields.customerName: customerName,
      FirestoreFields.address: address,
      FirestoreFields.phoneNumber: phoneNumber,
      FirestoreFields.totalAmount: totalAmount,
      FirestoreFields.status: 'Pending',
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.orderItems: items.map((e) => e.toMap()).toList(),
    };

    if (resolvedEventId.isNotEmpty) {
      payload[FirestoreFields.eventId] = resolvedEventId;
    }
    if (resolvedRegistrationId.isNotEmpty) {
      payload[FirestoreFields.eventRegistrationId] = resolvedRegistrationId;
    }
    if (resolvedParticipantUid.isNotEmpty) {
      payload[FirestoreFields.eventParticipantUid] = resolvedParticipantUid;
    }

    await _firestore.collection(FirestoreCollections.orders).add(payload);
  }

  @override
  Future<void> markOrderDelivered({
    required String orderId,
    required List<OrderItem> items,
    required String actorUid,
    required String actorName,
  }) async {
    final inventoryUpdates =
        <MapEntry<DocumentReference<Map<String, dynamic>>, int>>[];

    for (final item in items) {
      final inventorySnapshot = await _firestore
          .collection(FirestoreCollections.inventory)
          .where(FirestoreFields.productName, isEqualTo: item.product)
          .limit(1)
          .get();

      if (inventorySnapshot.docs.isNotEmpty) {
        inventoryUpdates.add(
          MapEntry(inventorySnapshot.docs.first.reference, item.quantity),
        );
      }
    }

    final orderRef = _firestore
        .collection(FirestoreCollections.orders)
        .doc(orderId);
    final orderDoc = await orderRef.get();
    final orderData = orderDoc.data() ?? <String, dynamic>{};

    await _firestore.runTransaction((transaction) async {
      for (final update in inventoryUpdates) {
        final snapshot = await transaction.get(update.key);
        final data = snapshot.data() ?? <String, dynamic>{};
        final currentQty = FirestoreCompat.readInt(data, [
          FirestoreFields.quantity,
        ]);
        final nextQty = (currentQty - update.value).clamp(0, currentQty);
        transaction.update(update.key, {FirestoreFields.quantity: nextQty});
      }

      transaction.update(orderRef, {
        FirestoreFields.status: 'Delivered',
        FirestoreFields.deliveredAt: FieldValue.serverTimestamp(),
      });
    });

    final registrationId = FirestoreCompat.readString(orderData, [
      FirestoreFields.eventRegistrationId,
    ]);
    if (registrationId.isNotEmpty) {
      await _recomputeEventFinanceFromOrders(
        registrationId: registrationId,
        actorUid: actorUid,
        actorName: actorName,
      );
    }
  }

  Future<void> _recomputeEventFinanceFromOrders({
    required String registrationId,
    required String actorUid,
    required String actorName,
  }) async {
    final registrationRef = _firestore
        .collection(FirestoreCollections.eventRegistrations)
        .doc(registrationId);
    final registrationDoc = await registrationRef.get();
    if (!registrationDoc.exists) {
      return;
    }

    final registration = EventRegistration.fromDoc(registrationDoc);

    final deliveredOrders = await _firestore
        .collection(FirestoreCollections.orders)
        .where(FirestoreFields.eventRegistrationId, isEqualTo: registrationId)
        .where(FirestoreFields.status, isEqualTo: 'Delivered')
        .get();

    var medicineIssuedAmount = 0.0;
    for (final doc in deliveredOrders.docs) {
      medicineIssuedAmount += FirestoreCompat.readDouble(doc.data(), [
        FirestoreFields.totalAmount,
        FirestoreFields.amount,
      ]);
    }

    final payments = await _firestore
        .collection(FirestoreCollections.eventPayments)
        .where(FirestoreFields.registrationId, isEqualTo: registrationId)
        .get();

    var totalPaidAmount = 0.0;
    for (final doc in payments.docs) {
      totalPaidAmount += FirestoreCompat.readDouble(doc.data(), [
        FirestoreFields.amount,
      ]);
    }

    final dueAmount = (medicineIssuedAmount - totalPaidAmount) <= 0
        ? 0.0
        : (medicineIssuedAmount - totalPaidAmount);
    final advanceAmount = (totalPaidAmount - medicineIssuedAmount) <= 0
        ? 0.0
        : (totalPaidAmount - medicineIssuedAmount);
    final targetSnapshot = registration.financialBaseAmount > 0
        ? registration.financialBaseAmount
        : 0.0;
    final eligibilityStatus =
        (targetSnapshot > 0 && medicineIssuedAmount >= targetSnapshot)
        ? 'eligible'
        : 'not_eligible';

    final finalAchievedAmount =
        medicineIssuedAmount + registration.manualAdjustmentTotal;

    await registrationRef.set({
      FirestoreFields.medicineIssuedAmount: medicineIssuedAmount,
      FirestoreFields.autoAchievedAmount: medicineIssuedAmount,
      FirestoreFields.finalAchievedAmount: finalAchievedAmount,
      FirestoreFields.totalPaidAmount: totalPaidAmount,
      FirestoreFields.dueAmount: dueAmount,
      FirestoreFields.advanceAmount: advanceAmount,
      FirestoreFields.eligibilityStatus: eligibilityStatus,
      FirestoreFields.financeUpdatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.financeUpdatedByUid: actorUid,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.updatedByUid: actorUid,
    }, SetOptions(merge: true));
  }
}
