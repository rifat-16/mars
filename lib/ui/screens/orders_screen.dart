import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/main_app_bar.dart';
import 'orders_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String? userPhoneNumber;
  String? userRole;

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userPhoneNumber = prefs.getString('phone');
    userRole = prefs.getString('position');
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Delivered":
        return Colors.green;
      case "Pending":
        return Colors.orange;
      case "Cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: const MainAppBar(title: 'Orders', icon: Icons.shopping_cart),
          body: StreamBuilder<QuerySnapshot>(
            stream: (userRole == 'Owner' || userRole == 'Manager')
                ? FirebaseFirestore.instance.collection('orders').snapshots()
                : FirebaseFirestore.instance
                    .collection('orders')
                    .where('phoneNumber', isEqualTo: userPhoneNumber)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No orders found"));
              }

              final orders = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return data;
              }).toList();

              // Pending orders upore, baki orders recent date descending
              orders.sort((a, b) {
                final aStatus = a["status"] ?? "";
                final bStatus = b["status"] ?? "";

                if (aStatus == "Pending" && bStatus != "Pending") {
                  return -1;
                } else if (aStatus != "Pending" && bStatus == "Pending") {
                  return 1;
                } else {
                  // Same status, sort by createdAt descending
                  final aDate = a["createdAt"] is Timestamp
                      ? (a["createdAt"] as Timestamp).toDate()
                      : DateTime(2000);
                  final bDate = b["createdAt"] is Timestamp
                      ? (b["createdAt"] as Timestamp).toDate()
                      : DateTime(2000);
                  return bDate.compareTo(aDate); // recent first
                }
              });

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final items = (order["items"] ?? []) as List<dynamic>;
                  double total = 0.0;
                  for (final item in items) {
                    dynamic qtyRaw = item["qty"];
                    dynamic priceRaw = item["price"];
                    double qty = 0.0;
                    double price = 0.0;
                    if (qtyRaw is int) {
                      qty = qtyRaw.toDouble();
                    } else if (qtyRaw is double) {
                      qty = qtyRaw;
                    } else if (qtyRaw is String) {
                      qty = double.tryParse(qtyRaw) ?? 0.0;
                    }
                    if (priceRaw is int) {
                      price = priceRaw.toDouble();
                    } else if (priceRaw is double) {
                      price = priceRaw;
                    } else if (priceRaw is String) {
                      price = double.tryParse(priceRaw) ?? 0.0;
                    }
                    total += qty * price;
                  }

                  final statusColor = _getStatusColor(order["status"] ?? "");

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrdersDetailsScreen(orderId: order["id"]),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: (order["status"] ?? "") == "Pending"
                              ? LinearGradient(
                                  colors: [statusColor.withOpacity(0.15), Colors.white],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: (order["status"] ?? "") != "Pending" ? Colors.white : null,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order["customerName"],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Date: ${order["createdAt"] != null && order["createdAt"] is Timestamp ? DateFormat('dd/MM/yyyy').format((order["createdAt"] as Timestamp).toDate()) : "N/A"}",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Items: ${order["orderItems"] != null ? (order["orderItems"] as List<dynamic>).length : 0}',
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Total: ${total.toStringAsFixed(2)} TK",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                order["status"] ?? "Unknown",
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: (userRole != null && (userRole != 'Owner' && userRole != 'Manager'))
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/createOrder');
                  },
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }
}
