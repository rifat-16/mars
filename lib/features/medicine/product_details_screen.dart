import 'package:flutter/material.dart';
import 'package:mars/widgets/main_app_bar.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: product["name"], icon: Icons.medical_services),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product["name"],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Category: ${product["category"]}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text("Description:", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(product["description"], style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 12),
            Text("TP Price: \$${product["tp"].toStringAsFixed(2)}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text("MRP Price: \$${product["mrp"].toStringAsFixed(2)}", style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
