import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/main_app_bar.dart';

class OrdersDetailsScreen extends StatefulWidget {
  final String orderId;
  const OrdersDetailsScreen({super.key, required this.orderId});

  @override
  State<OrdersDetailsScreen> createState() => _OrdersDetailsScreenState();
}

class _OrdersDetailsScreenState extends State<OrdersDetailsScreen> {
  String? userRole;


  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('position');
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderId;

    return Scaffold(
      appBar: MainAppBar(title: 'Order Details', icon: Icons.shopping_cart),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found'));
          }

          final order = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          // Safely parse orderItems
          final rawItems = order['orderItems'] ?? [];
          final List<Map<String, dynamic>> items = [];
          if (rawItems is List) {
            for (var e in rawItems) {
              Map<String, dynamic> mapE = {};
              try {
                if (e is Map) {
                  mapE = Map<String, dynamic>.from(e);
                } else {
                  mapE = Map<String, dynamic>.from(e);
                }
              } catch (_) {
                mapE = {};
              }
              final name = mapE['product']?.toString() ?? 'Unknown Item';
              final qtyRaw = mapE['quantity'];
              int qty = 0;
              if (qtyRaw is int) {
                qty = qtyRaw;
              } else if (qtyRaw is String) {
                qty = int.tryParse(qtyRaw) ?? 0;
              }
              items.add({'name': name, 'qty': qty});
            }
          } else {
            items.add({'name': 'Unknown Item', 'qty': 0});
          }

          // Format order date
          String formattedDate = '';
          final orderDate = order['createdAt'];
          if (orderDate is Timestamp) {
            final dt = orderDate.toDate();
            formattedDate =
                '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
          } else if (orderDate is DateTime) {
            formattedDate =
                '${orderDate.day.toString().padLeft(2, '0')}/${orderDate.month.toString().padLeft(2, '0')}/${orderDate.year}';
          } else if (orderDate is String) {
            formattedDate = orderDate;
          } else {
            formattedDate = 'Unknown Date';
          }

          // Safely get other fields with placeholders if null
          final customerName =
              order['customerName']?.toString() ?? 'Unknown Customer';
          final phoneNumber =
              order['phoneNumber']?.toString() ?? 'No Phone Number';
          final address = order['address']?.toString() ?? 'No Address';
          final totalAmount = order['totalAmount']?.toString() ?? '0.00';
          final status = order['status']?.toString() ?? 'Unknown Status';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Customer Info Card
                // Modernized Customer Info Card
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade50, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.07),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Column(
                      children: [
                        buildModernListTile(
                          icon: Icons.person_outline,
                          title: "Customer Name",
                          subtitle: customerName,
                        ),
                        buildDivider(),
                        buildListTile(
                          Icons.phone_outlined,
                          "Phone Number",
                          phoneNumber,
                        ),
                        buildDivider(),
                        buildListTile(
                          Icons.location_on_outlined,
                          "Address",
                          address,
                        ),
                        buildDivider(),
                        buildListTile(
                          Icons.calendar_today_outlined,
                          "Order Date",
                          formattedDate,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Items Card
                Card(
                  elevation: 3,
                  shadowColor: Colors.teal.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.green,
                                size: 26,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Order Items",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (context, idx) => Divider(
                            color: Colors.teal.withOpacity(0.1),
                            indent: 16,
                            endIndent: 16,
                          ),
                          itemBuilder: (context, idx) {
                            final item = items[idx];
                            final qty = item['qty'];
                            final qtyStr = qty.toString();
                            final name =
                                item['name']?.toString() ?? 'Unknown Item';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.withOpacity(0.1),
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.green,
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: Text(
                                'x$qtyStr',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        // Total Amount
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.attach_money_outlined,
                                color: Colors.green,
                                size: 22,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "Total Amount:",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                totalAmount + ' TK',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 2,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.timelapse_outlined,
                                color: status == 'Delivered'
                                    ? Colors.green
                                    : Colors.orange,
                                size: 22,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "Status:",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: status == 'Delivered'
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        const SizedBox(height: 20),
                        // Change Status Button
                        if (status != 'Delivered')
                          if (userRole == 'Owner' || userRole == 'Manager')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                final batch = FirebaseFirestore.instance
                                    .batch();
                                final inventoryRef = FirebaseFirestore.instance
                                    .collection('inventory');
                                final orderRef = FirebaseFirestore.instance
                                    .collection('orders')
                                    .doc(orderId);

                                try {
                                  // 1. Update inventory quantities
                                  for (var item in items) {
                                    final productName = item['name'];
                                    final qtyOrdered = item['qty'] ?? 0;

                                    final snapshot = await inventoryRef
                                        .where(
                                          'productName',
                                          isEqualTo: productName,
                                        )
                                        .limit(1)
                                        .get();

                                    if (snapshot.docs.isNotEmpty) {
                                      final doc = snapshot.docs.first;
                                      final oldQty = doc['quantity'] ?? 0;
                                      final newQty = (oldQty - qtyOrdered)
                                          .clamp(0, oldQty);

                                      batch.update(doc.reference, {
                                        'quantity': newQty,
                                      });
                                    }
                                  }

                                  // 2. Update order status
                                  batch.update(orderRef, {
                                    'status': 'Delivered',
                                  });

                                  // Commit batch
                                  await batch.commit();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Order delivered and inventory updated',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to deliver order: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Delivered',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  ListTile buildListTile(IconData icon, String title, String? subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.green, size: 26),
      title: Text(title),
      subtitle: Text(
        subtitle ?? '',
        style: const TextStyle(color: Colors.black87),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  Divider buildDivider() {
    return Divider(
      height: 0,
      indent: 20,
      endIndent: 20,
      color: Colors.grey[200],
    );
  }
}

  Widget buildModernListTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.shade100,
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.green.shade700, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }