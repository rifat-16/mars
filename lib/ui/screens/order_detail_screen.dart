import 'package:flutter/material.dart';
import '../widgets/main_app_bar.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

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
    double total = (order["items"] as List)
        .fold(0, (sum, item) => sum + (item["qty"] * item["price"]));

    return Scaffold(
      appBar: const MainAppBar(title: 'Order Details', icon: Icons.shopping_cart),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order["id"],
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text("Date: ${order["date"]}",
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 5),
            Text("Status: ${order["status"]}",
                style: TextStyle(
                    color: _getStatusColor(order["status"]),
                    fontWeight: FontWeight.bold)),
            const Divider(height: 25),

            Expanded(
              child: ListView(
                children: (order["items"] as List).map<Widget>((item) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.medical_services, color: Colors.green),
                      title: Text(item["name"]),
                      subtitle: Text("Qty: ${item["qty"]}"),
                      trailing: Text("\$${item["price"] * item["qty"]}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  );
                }).toList(),
              ),
            ),

            const Divider(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Amount",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("\$${total.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
