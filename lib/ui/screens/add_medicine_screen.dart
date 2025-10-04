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
  final _nameTEController = TextEditingController();
  final _subtitleTEController = TextEditingController();
  final _categoryTEController = TextEditingController();
  final _dosageTEController = TextEditingController();
  final _efficiencyTEController = TextEditingController();
  final _descriptionTEController = TextEditingController();
  final _tpPriceTEController = TextEditingController();
  final _mrpPriceTEController = TextEditingController();

  String name = '';
  String subtitle = '';
  String category = 'Syrup';
  String dosage = '';
  String efficiency = '';
  String description = '';
  double tpPrice = 0.0;
  double mrpPrice = 0.0;

  List<String> categories = ['Syrup', 'Tablet', 'Capsule'];

  bool _isSaving = false;

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
                controller: _nameTEController,
                decoration: _inputDecoration('Medicine Name'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter medicine name' : null,
                onSaved: (value) => name = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subtitleTEController,
                decoration: _inputDecoration('Sub Title'),
                onSaved: (value) => subtitle = value!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: _inputDecoration('Category'),
                value: category,
                items: categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) => setState(() => category = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosageTEController,
                decoration: _inputDecoration('Dosage'),
                onSaved: (value) => dosage = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _efficiencyTEController,
                decoration: _inputDecoration('Efficiency'),
                maxLines: 5,
                onSaved: (value) => efficiency = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionTEController,
                decoration: _inputDecoration('Description'),
                maxLines: 5,
                onSaved: (value) => description = value!,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tpPriceTEController,
                      decoration: _inputDecoration('TP Price'),
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      onSaved: (value) => tpPrice = double.tryParse(value!) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _mrpPriceTEController,
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
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
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
      setState(() => _isSaving = true);
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
        _clearForm();
        // Update the document with the generated ID
        await docRef.update({"id": productId});
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
              content: Text("Medicine saved successfully",
            style: TextStyle(color: Colors.white),
          )
          ),
        );
      } catch (e) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save: $e")),
        );
      }
    }
  }

  void _clearForm() {
    _nameTEController.clear();
    _subtitleTEController.clear();
    _categoryTEController.clear();
    _dosageTEController.clear();
    _efficiencyTEController.clear();
    _descriptionTEController.clear();
    _tpPriceTEController.clear();
    _mrpPriceTEController.clear();
  }

  @override
  void dispose() {
    _nameTEController.dispose();
    _subtitleTEController.dispose();
    _categoryTEController.dispose();
    _dosageTEController.dispose();
    _efficiencyTEController.dispose();
    _descriptionTEController.dispose();
    _tpPriceTEController.dispose();
    _mrpPriceTEController.dispose();
    super.dispose();
  }
}
