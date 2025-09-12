import 'package:flutter/material.dart';
import 'package:mars/widgets/main_app_bar.dart';
import 'product_details_screen.dart'; // নতুন screen

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  String selectedCategory = 'All';
  List<String> categories = ['All', 'Syrup', 'Tablet', 'Capsule'];

  List<Map<String, dynamic>> medicines = List.generate(10, (index) => {
    "name": "Product ${index + 1}",
    "category": ["Syrup", "Tablet", "Capsule"][index % 3],
    "description": "This is a description of product ${index + 1}",
    "tp": 10.0 + index,
    "mrp": 20.0 + index,
  });

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredMedicines = selectedCategory == 'All'
        ? medicines
        : medicines.where((med) => med["category"] == selectedCategory).toList();

    return Scaffold(
      appBar: MainAppBar(title: 'Medicine Catalog', icon: Icons.medical_services),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Categories
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  bool isSelected = cat == selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => selectedCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Medicine List
            Expanded(
              child: filteredMedicines.isEmpty
                  ? const Center(child: Text("No products found"))
                  : ListView.builder(
                itemCount: filteredMedicines.length,
                itemBuilder: (context, index) {
                  final med = filteredMedicines[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: const Icon(Icons.medical_services, color: Colors.green),
                      title: Text(med["name"]),
                      subtitle: Text('Category: ${med["category"]}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailsScreen(product: med),
                          ),
                        );
                      },
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
