import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/compat/firestore_compat.dart';
import '../../core/constants/firestore_keys.dart';
import 'order_item.dart';

class Order {
  final String id;
  final String customerName;
  final String phoneNumber;
  final String address;
  final double totalAmount;
  final String status;
  final DateTime? createdAt;
  final List<OrderItem> items;
  final String eventId;
  final String eventRegistrationId;
  final String eventParticipantUid;

  const Order({
    required this.id,
    required this.customerName,
    required this.phoneNumber,
    required this.address,
    required this.totalAmount,
    required this.status,
    required this.items,
    required this.createdAt,
    required this.eventId,
    required this.eventRegistrationId,
    required this.eventParticipantUid,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isDelivered => status.toLowerCase() == 'delivered';
  bool get isEventTagged => eventRegistrationId.isNotEmpty;

  factory Order.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawItems = data[FirestoreFields.orderItems];
    final parsedItems = <OrderItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          parsedItems.add(OrderItem.fromMap(item));
        } else if (item is Map) {
          parsedItems.add(OrderItem.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    return Order(
      id: doc.id,
      customerName: FirestoreCompat.readString(data, [
        FirestoreFields.customerName,
        FirestoreFields.name,
      ], fallback: 'Unknown'),
      phoneNumber: FirestoreCompat.readString(data, [
        FirestoreFields.phoneNumber,
        FirestoreFields.phone,
      ]),
      address: FirestoreCompat.readString(data, [FirestoreFields.address]),
      totalAmount: FirestoreCompat.readDouble(data, [
        FirestoreFields.totalAmount,
        FirestoreFields.amount,
      ]),
      status: FirestoreCompat.readString(data, [
        FirestoreFields.status,
      ], fallback: 'Pending'),
      createdAt: FirestoreCompat.readDateTime(data, [
        FirestoreFields.createdAt,
        FirestoreFields.createdAtSnake,
        'date',
        'orderDate',
      ]),
      items: parsedItems,
      eventId: FirestoreCompat.readString(data, [FirestoreFields.eventId]),
      eventRegistrationId: FirestoreCompat.readString(data, [
        FirestoreFields.eventRegistrationId,
      ]),
      eventParticipantUid: FirestoreCompat.readString(data, [
        FirestoreFields.eventParticipantUid,
      ]),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      FirestoreFields.customerName: customerName,
      FirestoreFields.phoneNumber: phoneNumber,
      FirestoreFields.address: address,
      FirestoreFields.totalAmount: totalAmount,
      FirestoreFields.status: status,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.orderItems: items.map((item) => item.toMap()).toList(),
    };

    if (eventId.isNotEmpty) {
      map[FirestoreFields.eventId] = eventId;
    }
    if (eventRegistrationId.isNotEmpty) {
      map[FirestoreFields.eventRegistrationId] = eventRegistrationId;
    }
    if (eventParticipantUid.isNotEmpty) {
      map[FirestoreFields.eventParticipantUid] = eventParticipantUid;
    }

    return map;
  }
}
