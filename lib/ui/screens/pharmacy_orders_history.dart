import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/main_app_bar.dart';
import 'package:intl/intl.dart';

class PharmacyOrdersHistory extends StatefulWidget {
  final String phoneNumber;
  const PharmacyOrdersHistory({super.key, required this.phoneNumber});

  @override
  State<PharmacyOrdersHistory> createState() => _PharmacyOrdersHistoryState();
}

class _PharmacyOrdersHistoryState extends State<PharmacyOrdersHistory> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchOrders();
  }

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('phoneNumber', isEqualTo: widget.phoneNumber)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(title: 'Orders History', icon: Icons.history),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final orders = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];

                  // Convert Timestamp to formatted String
                  String dateString = 'N/A';
                  if (order['createdAt'] != null &&
                      order['createdAt'] is Timestamp) {
                    final Timestamp ts = order['createdAt'];
                    dateString = DateFormat('dd MMM yyyy').format(ts.toDate());
                  }

                  return _buildOrderCard(
                    order['orderId'] ?? 'N/A',
                    order['customerName'] ?? 'N/A',
                    (order['totalAmount'] ?? 0).toDouble(),
                    dateString,
                    order['phoneNumber'] ?? 'N/A',
                    order['address'] ?? 'N/A',
                  );
                },
              );
            } else {
              return const Center(child: Text('No orders found 😔'));
            }
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    String id,
    String customerName,
    double total,
    String createdAt,
    String phone,
    String address,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 14,
      shadowColor: Colors.greenAccent.withOpacity(0.2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            colors: [Color(0xFFDFF5E1), Color(0xFFFFFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.15),
              offset: const Offset(3, 7),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.green.shade400,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade200.withOpacity(0.6),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: const Icon(Icons.local_pharmacy, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Address: $address',
                    style: TextStyle(fontSize: 14, color: Colors.black87.withOpacity(0.85)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phone: $phone',
                    style: TextStyle(fontSize: 14, color: Colors.black54.withOpacity(0.85)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: \$${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: $createdAt',
                    style: TextStyle(fontSize: 12, color: Colors.grey.withOpacity(0.75)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
