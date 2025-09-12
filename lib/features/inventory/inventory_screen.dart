import 'package:flutter/material.dart';
import 'package:mars/widgets/main_app_bar.dart';

// Inventory Screen
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String selectedCategory = 'All';
  List<String> categories = ['All', 'Syrup', 'Tablet', 'Capsule'];

  // Dummy products data
  List<Map<String, dynamic>> products = List.generate(10, (index) => {
    "name": "Product ${index + 1}",
    "category": ["Syrup", "Tablet", "Capsule"][index % 3],
    "description":
    "This is a detailed description for Product ${index + 1}. It can be long and explain product features clearly.",
    "tp": 10.0 + index,
    "mrp": 20.0 + index,
    "produced": 100 + index * 5,
    "stock": 80 + index * 3,
    "sealed": 20 + index * 2,
  });

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredProducts = selectedCategory == 'All'
        ? products
        : products
        .where((prod) => prod["category"] == selectedCategory)
        .toList();

    return Scaffold(
      appBar: const MainAppBar(title: 'Inventory', icon: Icons.inventory_2),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  bool isSelected = category == selectedCategory;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green : Colors.grey[300],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Products Grid
            Expanded(
              child: filteredProducts.isEmpty
                  ? const Center(child: Text("No products found"))
                  : GridView.builder(
                itemCount: filteredProducts.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final prod = filteredProducts[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailsScreen(product: prod),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(Icons.medical_services,
                                    size: 40, color: Colors.green),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(prod["name"],
                              style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Stock: ${prod["stock"]}',
                              style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Product Details Screen
class ProductDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  const ProductDetailsScreen({super.key, required this.product});

  Widget _buildInfoCard(
      String title,
      String value, {
        Color? color,
        IconData? icon,
      }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 24, color: color ?? Colors.blueGrey),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: color ?? Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? 'Product Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildInfoCard('Name', product['name'] ?? '-', icon: Icons.label),
          _buildInfoCard('Price', '\$${product['price'] ?? '0.00'}', color: Colors.green, icon: Icons.attach_money),
          _buildInfoCard('Stock', '${product['stock'] ?? 0}', color: Colors.orange, icon: Icons.inventory),
          _buildInfoCard('Description', product['description'] ?? '-', icon: Icons.description),
        ],
      ),
    );
  }
}
