import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/main_app_bar.dart';


class AddProductionScreen extends StatefulWidget {
  const AddProductionScreen({super.key});

  @override
  State<AddProductionScreen> createState() => _AddProductionScreenState();
}

class _AddProductionScreenState extends State<AddProductionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  DateTime? _selectedDate;
  bool _isSaving = false;

  String? _selectedCategory;
  final List<String> _categories = ['Syrup', 'Tablet', 'Capsule'];

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Map<String, double> products = {};

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('medicines')
          .get();

      setState(() {
        products = Map.fromEntries(snapshot.docs.map((doc) {
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
      print('Error fetching medicines: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'Add Production', icon: Icons.production_quantity_limits),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                value: _productNameController.text.isNotEmpty
                    ? _productNameController.text
                    : null,
                hint: const Text('Select Product'),
                items: products.keys.map((product) {
                  return DropdownMenuItem<String>(
                    value: product,
                    child: Text(product),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _productNameController.text = value ?? '';
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Select Product',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Please select a product' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories
                    .map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Select Category',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter quantity';
                  if (int.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: _selectedDate == null
                          ? 'Select Date'
                          : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Visibility(
                visible: _isSaving == false,
                replacement: const Center(
                  child: CircularProgressIndicator(),
                ),
                child: ElevatedButton(
                  onPressed: _onTabAddProduction,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Add Production', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onTabAddProduction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      _formKey.currentState!.save();

      final firestore = FirebaseFirestore.instance;
      final inventoryRef = firestore.collection('inventory');
      final productionsRef = firestore.collection('productions');

      Map<String, dynamic> production = {
        'createdAt': FieldValue.serverTimestamp(),
        'productName': _productNameController.text,
        'category': _selectedCategory,
        'quantity': int.parse(_quantityController.text),
        'date': _selectedDate,
      };

      try {
        // Step 1: Save production record (history)
        final docRef = await productionsRef.add(production);
        await docRef.update({'id': docRef.id});

        // Step 2: Update or create in inventory
        final existing = await inventoryRef
            .where('productName', isEqualTo: _productNameController.text)
            .limit(1)
            .get();

        if (existing.docs.isNotEmpty) {
          final doc = existing.docs.first;
          final oldQty = doc['quantity'] ?? 0;
          final newQty = oldQty + int.parse(_quantityController.text);
          await inventoryRef.doc(doc.id).update({
            'quantity': newQty,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          await inventoryRef.add({
            'productName': _productNameController.text,
            'category': _selectedCategory,
            'quantity': int.parse(_quantityController.text),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        _clearForm();
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Production added successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      } catch (e) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add production: $e')),
        );
      }
    }
  }

  void _clearForm() {
    _productNameController.clear();
    _quantityController.clear();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}