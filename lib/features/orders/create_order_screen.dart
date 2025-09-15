import 'package:flutter/material.dart';
import 'package:mars/widgets/main_app_bar.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  // Sample products
  final List<String> products = [
    'Paracetamol',
    'Aspirin',
    'Vitamin C',
    'Ibuprofen',
  ];

  // List of selected products with quantity
  List<Map<String, dynamic>> orderItems = [
    {'product': null, 'quantity': 1},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'Invoice', icon: Icons.text_snippet),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Customer Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Medicine Information',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic list of products
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: orderItems.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      // Product dropdown
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.green
                          ),
                          value: orderItems[index]['product'],
                          hint: Text('Select Product'),
                          items: products.map((product) {
                            return DropdownMenuItem<String>(
                              value: product,
                              child: Text(product),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              orderItems[index]['product'] = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Quantity input
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.green
                          ),
                          keyboardType: TextInputType.number,
                          initialValue: orderItems[index]['quantity']
                              .toString(),
                          decoration: InputDecoration(
                            labelText: 'Qty',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              orderItems[index]['quantity'] =
                                  int.tryParse(value) ?? 1;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Remove button
                      IconButton(
                        onPressed: () {
                          setState(() {
                            orderItems.removeAt(index);
                          });
                        },
                        icon: Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Add new product button
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  orderItems.add({'product': null, 'quantity': 1});
                });
              },
              icon: Icon(Icons.add),
              label: Text('Add Product'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount: ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                // Calculate and display total amount here
                Text(
                  '1000',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Submit button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  print('Order: $orderItems');
                  // Here you can send orderItems to backend or calculate total
                },
                child: Text('Submit Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
