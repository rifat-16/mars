import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/compat/firestore_compat.dart';
import '../../core/constants/firestore_keys.dart';
import '../../models/domain/dashboard_metrics.dart';

abstract class DashboardRepository {
  Future<DashboardMetrics> fetchMetrics();
}

class FirebaseDashboardRepository implements DashboardRepository {
  final FirebaseFirestore _firestore;

  FirebaseDashboardRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<DashboardMetrics> fetchMetrics() async {
    final ordersSnapshot = await _firestore
        .collection(FirestoreCollections.orders)
        .get();
    final paymentsSnapshot = await _firestore
        .collection(FirestoreCollections.payments)
        .get();

    var ordersAmount = 0.0;
    for (final doc in ordersSnapshot.docs) {
      ordersAmount += FirestoreCompat.readDouble(doc.data(), [
        FirestoreFields.totalAmount,
        FirestoreFields.amount,
      ]);
    }

    var paymentsAmount = 0.0;
    for (final doc in paymentsSnapshot.docs) {
      paymentsAmount += FirestoreCompat.readDouble(doc.data(), [
        FirestoreFields.amount,
      ]);
    }

    return DashboardMetrics(
      totalOrdersCount: ordersSnapshot.docs.length,
      totalOrdersAmount: ordersAmount,
      totalPaymentsCount: paymentsSnapshot.docs.length,
      totalPaymentsAmount: paymentsAmount,
      dueAmount: ordersAmount - paymentsAmount,
    );
  }
}
