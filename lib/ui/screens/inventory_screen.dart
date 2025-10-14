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

  Future<void> _fetchInventory() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('inventory').get();
    final data =
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    setState(() {
      products = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Widget _buildProductCard(Map<String, dynamic> prod) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade200, Colors.green.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Icon(
                    Icons.medical_services,
                    size: 48,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                prod["productName"] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                'Stock: ${prod["quantity"] ?? 0}',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Material(
                      color: isSelected ? Colors.green : Colors.grey[300],
                      borderRadius: BorderRadius.circular(30),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Products Grid with animated transition
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  // Fade and slide from below
                  final fade = FadeTransition(opacity: animation, child: child);
                  final slide = SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                    child: fade,
                  );
                  return slide;
                },
                child: filteredProducts.isEmpty
                    ? const Center(
                        key: ValueKey('empty'),
                        child: Text("No products found"),
                      )
                    : GridView.builder(
                        key: ValueKey(selectedCategory),
                        itemCount: filteredProducts.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.78,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemBuilder: (context, index) {
                          final prod = filteredProducts[index];
                          return _buildProductCard(prod);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
