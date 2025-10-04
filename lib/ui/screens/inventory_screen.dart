import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/inventory_stock_card.dart';
import '../widgets/main_app_bar.dart';

// Inventory Screen
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String selectedCategory = 'All';
  List<String> categories = ['All', 'Syrup', 'Tablet', 'Capsule'];

  List<Map<String, dynamic>> products = [];
  bool _isLoading = true;

  Future<void> _fetchProducts() async {
    final snapshot = await FirebaseFirestore.instance.collection('productions').get();
    final data = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    setState(() {
      products = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: MainAppBar(title: 'Inventory', icon: Icons.inventory_2),
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                                Text(prod["productName"] ?? '',
                                    style:
                                        const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Stock: ${prod["quantity"] ?? 0}',
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
    return InventoryStockCard(
      title: title,
      value: value,
      color: color,
      icon: icon,
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
        ],
      ),
    );
  }
}
