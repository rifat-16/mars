import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/main_app_bar.dart';

class EditEmployeeScreen extends StatefulWidget {
  final String employeeId;

  const EditEmployeeScreen({super.key, required this.employeeId});

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isUpdating = false; // Add this at the top with _isLoading

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
  }

  void _loadEmployeeData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('employees')
          .doc(widget.employeeId)
          .get();
      final data = doc.data()!;
      _nameController.text = data['name'] ?? '';
      _positionController.text = data['position'] ?? '';
      _emailController.text = data['email'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _passwordController.text = data['password'] ?? '';
      _locationController.text = data['location'] ?? '';
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load employee data: $e')),
      );
    }
  }

  void _updateEmployee() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUpdating = true; // Start loader
      });

      try {
        await FirebaseFirestore.instance
            .collection('employees')
            .doc(widget.employeeId)
            .update({
          'name': _nameController.text,
          'position': _positionController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'password': _passwordController.text,
          'location': _locationController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update employee: $e')),
        );
      } finally {
        setState(() {
          _isUpdating = false; // Stop loader
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'Edit Employee', icon: Icons.edit),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(labelText: 'Position'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter position' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter email' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter phone' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter password' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter location' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isUpdating ? null : _updateEmployee,
                child: _isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Update Employee'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
