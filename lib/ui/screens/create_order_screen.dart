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
  Map<String, double> _products = {};
  late String _userRole;

  List<Map<String, String>> _previousCustomers = [];
  Map<String, String>? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _loadUserRole();
    _isOwner();
    _fetchPreviousCustomers();
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('position') ?? '';
    });
    if (_userRole != 'Owner' && _userRole != 'Manager') {
      _loadUserInfo();
    }
  }

  Future<void> _isOwner() async {
    if (_userRole != 'Owner' && _userRole != 'Manager') {
      _loadUserInfo();
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
      final snapshot = await FirebaseFirestore.instance.collection('medicines').get();
      setState(() {
        _products = Map.fromEntries(snapshot.docs.map((doc) {
          final data = doc.data();
          final name = data['name'] ?? data['medicineName'] ?? data['productName'] ?? '';
          final tpPrice = data['TP'] ?? data['tp'] ?? 0;
          return MapEntry(name.toString(), (tpPrice is num) ? tpPrice.toDouble() : 0.0);
        }).where((entry) => entry.key.isNotEmpty));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _fetchPreviousCustomers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('orders').get();
      Map<String, Map<String, String>> uniqueCustomers = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final phone = data['phoneNumber'] ?? '';
        if (phone.isNotEmpty && !uniqueCustomers.containsKey(phone)) {
          uniqueCustomers[phone] = {
            'name': data['customerName'] ?? '',
            'address': data['address'] ?? '',
            'phone': phone,
          };
        }
      }
      setState(() {
        _previousCustomers = uniqueCustomers.values.toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load previous customers: $e'), backgroundColor: Colors.red),
      );
    }
  }

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
    final Color green = Colors.green.shade700;
    final Color cardBg = Colors.green.shade50;
    return Scaffold(
      appBar: MainAppBar(title: 'Invoice', icon: Icons.text_snippet),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Info Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: green, width: 1.2),
                ),
                color: cardBg,
                margin: const EdgeInsets.only(bottom: 18),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: green, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Customer Information',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_userRole == 'Owner' || _userRole == 'Manager') ...[
                        DropdownButtonFormField<Map<String, String>>(
                          decoration: InputDecoration(
                            labelText: 'Select Previous Customer',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: green),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          isExpanded: true,
                          value: _selectedCustomer,
                          items: _previousCustomers.map((customer) {
                            return DropdownMenuItem<Map<String, String>>(
                              value: customer,
                              child: Text('${customer['name']} (${customer['address']})'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCustomer = value;
                              if (value != null) {
                                _customerNameController.text = value['name'] ?? '';
                                _addressController.text = value['address'] ?? '';
                                _phoneNumberController.text = value['phone'] ?? '';
                              }
                            });
                          },
                          hint: const Text('Select Previous Customer'),
                        ),
                        const SizedBox(height: 14),
                      ],
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
                          prefixIcon: Icon(Icons.account_circle, color: green),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
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
                          prefixIcon: Icon(Icons.location_on, color: green),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
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
                          prefixIcon: Icon(Icons.phone_android, color: green),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Medicine Info Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: green, width: 1.2),
                ),
                color: cardBg,
                margin: const EdgeInsets.only(bottom: 18),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.medication, color: green, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Medicine Information',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: orderItems.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: green.withOpacity(0.28)),
                              ),
                              elevation: 1,
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: DropdownButtonFormField<String>(
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: green),
                                        value: _products.containsKey(orderItems[index]['product'])
                                            ? orderItems[index]['product']
                                            : null,
                                        hint: const Text('Select Product'),
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
                                        decoration: InputDecoration(
                                          labelText: 'Product',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          filled: true,
                                          fillColor: Colors.green[50],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: green),
                                        keyboardType: TextInputType.number,
                                        initialValue: orderItems[index]['quantity'].toString(),
                                        decoration: InputDecoration(
                                          labelText: 'Qty',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          filled: true,
                                          fillColor: Colors.green[50],
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            orderItems[index]['quantity'] = int.tryParse(value) ?? 1;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          orderItems.removeAt(index);
                                        });
                                      },
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onPressed: () {
                            setState(() {
                              orderItems.add({'product': null, 'quantity': 1});
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Total Amount Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: green, width: 1),
                ),
                color: cardBg,
                margin: const EdgeInsets.only(bottom: 18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: green, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Total Amount:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: green,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            totalAmount.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: green,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'TK',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Submit Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: Visibility(
                    visible: !_isSaving,
                    replacement: const CircularProgressIndicator(),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _onTapSubmitButton,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Submit Order'),
                      ),
                    ),
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
          'status': 'Pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order Placed Successfully'),
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
          SnackBar(
            content: Text(e.message ?? 'Order Failed'),
            backgroundColor: Colors.red,
          ),
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
