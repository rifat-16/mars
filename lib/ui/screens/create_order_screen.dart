import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/main_app_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  bool _isSaving = false;
  // Sample products with TP prices
  Map<String, double> _products = {};
  late String _userRole;


  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _loadUserRole();
    _isOwner();
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('position') ?? '';
    });
  }

  Future<void> _isOwner() async{
    if (_userRole != 'Owner' && _userRole != 'Manager'){
      _loadUserInfo();
    } else {
      return;
    }
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      String firstName = prefs.getString('first_name') ?? '';
      String lastName = prefs.getString('last_name') ?? '';
      String name = '$firstName $lastName';
      _customerNameController.text = name;
      _addressController.text = prefs.getString('address') ?? '';
      _phoneNumberController.text = prefs.getString('phone') ?? '';
    });
  }

  Future<void> _fetchProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('medicines')
          .get();

      setState(() {
        _products = Map.fromEntries(snapshot.docs.map((doc) {
          final data = doc.data();
          // Handle different possible field names
          final name = data['name'] ??
              data['medicineName'] ??
              data['productName'] ??
              '';
          final tpPrice = data['TP'] ?? data['tp'] ?? 0;
          return MapEntry(name.toString(), (tpPrice is num) ? tpPrice.toDouble() : 0.0);
        }).where((entry) => entry.key.isNotEmpty));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  // List of selected products with quantity
  List<Map<String, dynamic>> orderItems = [
    {'product': null, 'quantity': 1},
  ];

  double get totalAmount {
    double total = 0;
    for (var item in orderItems) {
      final productName = item['product'];
      final quantity = item['quantity'] ?? 1;
      if (productName != null && _products.containsKey(productName)) {
        total += _products[productName]! * quantity;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'Invoice', icon: Icons.text_snippet),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
                controller: _customerNameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty || value.length != 11) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
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
                            value: _products.containsKey(orderItems[index]['product'])
                                ? orderItems[index]['product']
                                : null,
                            hint: Text('Select Product'),
                            items: _products.keys.map((product) {
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
                  Row(
                    children: [
                      Text(
                        totalAmount.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TK',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Submit button
              Center(
                child: Visibility(
                  visible: _isSaving == false,
                  replacement: CircularProgressIndicator(),
                  child: ElevatedButton(
                    onPressed: _onTapSubmitButton,
                    child: Text('Submit Order'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onTapSubmitButton() async {
    if (_formKey.currentState!.validate()) {
      // Validate that all products are selected (not null)
      bool allProductsSelected = orderItems.every((item) => item['product'] != null);
      if (!allProductsSelected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a product for all items.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });
      try {
        await FirebaseFirestore.instance.collection('orders').add({
          'customerName': _customerNameController.text.trim(),
          'address': _addressController.text.trim(),
          'phoneNumber': _phoneNumberController.text.trim(),
          'orderItems': orderItems,
          'totalAmount': totalAmount,
          'status': 'Pending', // <-- default state
          'createdAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order Placed Successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/orders');
        });
      } on FirebaseException catch (e) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Order Failed'),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }
}
