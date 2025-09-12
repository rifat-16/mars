import 'package:flutter/material.dart';
import 'package:mars/widgets/main_app_bar.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String category = 'Syrup';
  String description = '';
  double tpPrice = 0.0;
  double mrpPrice = 0.0;
  int quantity = 0;

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
      appBar: MainAppBar(title: 'Add Medicine', icon: Icons.medical_services),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Medicine Name
              TextFormField(
                decoration: _inputDecoration('Medicine Name'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter medicine name' : null,
                onSaved: (value) => name = value!,
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('Category'),
                value: category,
                items: categories
                    .map((cat) =>
                    DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) => setState(() => category = value!),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                decoration: _inputDecoration('Description'),
                maxLines: 3,
                onSaved: (value) => description = value!,
              ),
              const SizedBox(height: 16),

              // TP Price & MRP Price Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: _inputDecoration('TP Price'),
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) =>
                      value!.isEmpty ? 'Enter TP Price' : null,
                      onSaved: (value) => tpPrice = double.parse(value!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      decoration: _inputDecoration('MRP Price'),
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) =>
                      value!.isEmpty ? 'Enter MRP Price' : null,
                      onSaved: (value) => mrpPrice = double.parse(value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quantity
              TextFormField(
                decoration: _inputDecoration('Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value!.isEmpty ? 'Enter Quantity' : null,
                onSaved: (value) => quantity = int.parse(value!),
              ),
              const SizedBox(height: 24),

              // Save Button
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

  void _saveMedicine() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // TODO: Save to Firebase / Local DB
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicine saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}
