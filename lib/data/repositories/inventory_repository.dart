import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_keys.dart';
import '../../models/domain/inventory_item.dart';

abstract class InventoryRepository {
  Stream<List<InventoryItem>> watchInventory();
}

class FirebaseInventoryRepository implements InventoryRepository {
  final FirebaseFirestore _firestore;

  FirebaseInventoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<InventoryItem>> watchInventory() {
    return _firestore
        .collection(FirestoreCollections.inventory)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(InventoryItem.fromDoc).toList());
  }
}
