import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_details_screen.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String subtitle = '';
  String category = 'Syrup';
  String dosage = '';
  String efficiency = '';
  String description = '';
  double tpPrice = 0.0;
  double mrpPrice = 0.0;

  List<String> categories = ['Syrup', 'Tablet', 'Capsule'];

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medicine'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: _inputDecoration('Medicine Name'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter medicine name' : null,
                onSaved: (value) => name = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: _inputDecoration('Sub Title'),
                onSaved: (value) => subtitle = value!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('Category'),
                value: category,
                items: categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) => setState(() => category = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: _inputDecoration('Dosage'),
                onSaved: (value) => dosage = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: _inputDecoration('Efficiency'),
                maxLines: 5,
                onSaved: (value) => efficiency = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: _inputDecoration('Description'),
                maxLines: 5,
                onSaved: (value) => description = value!,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: _inputDecoration('TP Price'),
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      onSaved: (value) => tpPrice = double.tryParse(value!) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      decoration: _inputDecoration('MRP Price'),
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      onSaved: (value) => mrpPrice = double.tryParse(value!) ?? 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveMedicine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Save Medicine',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _saveMedicine() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Map<String, dynamic> product = {
        "name": name,
        "subtitle": subtitle,
        "category": category,
        "dosage": dosage,
        "efficiency": efficiency,
        "description": description,
        "tp": tpPrice,
        "mrp": mrpPrice,
        "createdAt": FieldValue.serverTimestamp(),
      };

      try {
        DocumentReference docRef = await FirebaseFirestore.instance
            .collection("medicines")
            .add(product);

        String productId = docRef.id;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(productId: productId),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save: $e")),
        );
      }
    }
  }
}
