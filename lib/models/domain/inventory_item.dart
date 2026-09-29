import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/compat/firestore_compat.dart';
import '../../core/constants/firestore_keys.dart';

class InventoryItem {
  final String id;
  final String productName;
  final String category;
  final int quantity;

  const InventoryItem({
    required this.id,
    required this.productName,
    required this.category,
    required this.quantity,
  });

  factory InventoryItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return InventoryItem(
      id: doc.id,
      productName: FirestoreCompat.readString(data, [
        FirestoreFields.productName,
        FirestoreFields.medicineName,
        FirestoreFields.name,
      ], fallback: 'Unknown'),
      category: FirestoreCompat.readString(data, [FirestoreFields.category]),
      quantity: FirestoreCompat.readInt(data, [FirestoreFields.quantity]),
    );
  }
}
