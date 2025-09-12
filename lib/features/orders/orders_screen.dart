import 'package:flutter/material.dart';
import 'package:mars/widgets/main_app_bar.dart';
import 'order_detail_screen.dart'; // নতুন screen import

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final List<Map<String, dynamic>> orders = [
    {
      "id": "#ORD1234",
      "date": "2025-09-10",
      "status": "Delivered",
      "items": [
        {"name": "Paracetamol", "qty": 2, "price": 20},
        {"name": "Vitamin C", "qty": 1, "price": 15},
      ],
    },
    {
      "id": "#ORD5678",
      "date": "2025-09-08",
      "status": "Pending",
      "items": [
        {"name": "Cough Syrup", "qty": 1, "price": 50},
      ],
    },
  ];

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
    return Scaffold(
      appBar: const MainAppBar(title: 'My Orders', icon: Icons.shopping_cart),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          double total = (order["items"] as List)
              .fold(0, (sum, item) => sum + (item["qty"] * item["price"]));

          return Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              title: Text(
                order["id"],
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text("Date: ${order["date"]}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text("${(order["items"] as List).length} items",
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 5),
                  Text("Total: \$${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              trailing: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                  _getStatusColor(order["status"]).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(order["status"],
                    style: TextStyle(
                        color: _getStatusColor(order["status"]),
                        fontWeight: FontWeight.bold)),
              ),
              onTap: () {
                // Navigate to order detail screen
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(order: order)));
              },
            ),
          );
        },
      ),
    );
  }
}
