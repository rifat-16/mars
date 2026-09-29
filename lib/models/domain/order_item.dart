import '../../core/compat/firestore_compat.dart';
import '../../core/constants/firestore_keys.dart';

class OrderItem {
  final String product;
  final int quantity;

  const OrderItem({required this.product, required this.quantity});

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      product: FirestoreCompat.readString(data, [
        FirestoreFields.product,
        FirestoreFields.productName,
        FirestoreFields.medicineName,
      ]),
      quantity: FirestoreCompat.readInt(data, [
        FirestoreFields.quantity,
      ], fallback: 1),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirestoreFields.product: product,
      FirestoreFields.quantity: quantity,
    };
  }
}
