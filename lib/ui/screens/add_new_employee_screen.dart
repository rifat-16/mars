import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _employeeData = {
    'name': '',
    'position': '',
    'email': '',
    'phone': '',
    'password': '',
    'location': '',
  };

  bool _showPassword = false;
  bool _loading = false;

  void _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() => _loading = true);

      try {
        // 1️⃣ Create user in Firebase Authentication
        UserCredential userCred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
            email: _employeeData['email']!,
            password: _employeeData['password']!);

        // 2️⃣ Save user info in Firestore
        await FirebaseFirestore.instance
            .collection('employees')
            .doc(userCred.user!.uid)
            .set({
          'name': _employeeData['name'],
          'position': _employeeData['position'],
          'email': _employeeData['email'],
          'phone': _employeeData['phone'],
          'password': _employeeData['password'],
          'location': _employeeData['location'],
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee added successfully!')),
        );

        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        String msg = 'Something went wrong';
        if (e.code == 'email-already-in-use') {
          msg = 'Email already in use';
        } else if (e.code == 'weak-password') {
          msg = 'Password should be at least 6 characters';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Employee'), backgroundColor: Colors.blue),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Name', prefixIcon: Icon(Icons.person)),
                    validator: (val) =>
                    val == null || val.isEmpty ? 'Enter name' : null,
                    onSaved: (val) => _employeeData['name'] = val ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Position', prefixIcon: Icon(Icons.work)),
                    validator: (val) =>
                    val == null || val.isEmpty ? 'Enter position' : null,
                    onSaved: (val) => _employeeData['position'] = val ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Email', prefixIcon: Icon(Icons.email)),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter email';
                      if (!val.contains('@')) return 'Enter valid email';
                      return null;
                    },
                    onSaved: (val) => _employeeData['email'] = val ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
                    keyboardType: TextInputType.phone,
                    validator: (val) =>
                    val == null || val.isEmpty ? 'Enter phone' : null,
                    onSaved: (val) => _employeeData['phone'] = val ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    obscureText: !_showPassword,
                    validator: (val) =>
                    val == null || val.isEmpty ? 'Enter password' : null,
                    onSaved: (val) => _employeeData['password'] = val ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Location', prefixIcon: Icon(Icons.location_on)),
                    validator: (val) =>
                    val == null || val.isEmpty ? 'Enter location' : null,
                    onSaved: (val) => _employeeData['location'] = val ?? '',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Employee'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _saveEmployee,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
