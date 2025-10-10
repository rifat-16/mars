import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/main_app_bar.dart';

class ProductDetailsScreen extends StatelessWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: "Medicine Details", icon: Icons.medical_information),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("medicines").doc(productId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Product not found",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Section
                if (data["imageUrl"] != null && data["imageUrl"].toString().isNotEmpty)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        data["imageUrl"],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                  ),

                const SizedBox(height: 16),

                // Name and Subtitle
                Text(
                  data["name"] ?? "Unnamed Product",
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  data["subtitle"] ?? "No subtitle available",
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),

                const SizedBox(height: 20),

                // Category
                Row(
                  children: [
                    const Icon(Icons.category, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      data["category"] ?? "Uncategorized",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(thickness: 1.2),

                // Dosage
                _buildSectionTitle("Dosage"),
                Text(data["dosage"] ?? "Not specified", style: const TextStyle(fontSize: 16)),

                const SizedBox(height: 16),

                // Efficiency
                _buildSectionTitle("Efficiency"),
                Text(data["efficiency"] ?? "Not specified", style: const TextStyle(fontSize: 16)),

                const SizedBox(height: 16),

                // Description
                _buildSectionTitle("Description"),
                Text(
                  data["description"] ?? "No description available.",
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),

                const SizedBox(height: 20),

                // Pricing Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildPriceCard(
                        title: "TP Price",
                        price: data["tp"]?.toString() ?? "0",
                        color: Colors.green[50]!,
                        textColor: Colors.green[900]!,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPriceCard(
                        title: "MRP Price",
                        price: data["mrp"]?.toString() ?? "0",
                        color: Colors.orange[50]!,
                        textColor: Colors.orange[900]!,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Feature coming soon!")),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text(
                      "Add to Cart",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPriceCard({
    required String title,
    required String price,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 6),
          Text("$price ৳", style: TextStyle(fontSize: 18, color: textColor)),
        ],
      ),
    );
  }
}
