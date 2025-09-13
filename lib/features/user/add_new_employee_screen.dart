import 'package:flutter/material.dart';
import 'package:mars/widgets/main_app_bar.dart';

class AddEmployeeScreen extends StatefulWidget {
  final Function(Map<String, String>) onSave;

  const AddEmployeeScreen({super.key, required this.onSave});

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

  void _saveEmployee() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onSave(_employeeData);
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Employee added')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'Add Employee', icon: Icons.person_add),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Name
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Name', prefixIcon: Icon(Icons.person)),
                    validator: (val) =>
                    val == null || val.isEmpty ? 'Enter name' : null,
                    onSaved: (val) => _employeeData['name'] = val ?? '',
                  ),
                  const SizedBox(height: 12),

                  // Position
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Position', prefixIcon: Icon(Icons.work)),
                    validator: (val) =>
                    val == null || val.isEmpty ? 'Enter position' : null,
                    onSaved: (val) => _employeeData['position'] = val ?? '',
                  ),
                  const SizedBox(height: 12),

                  // Email
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

                  // Phone
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
                    keyboardType: TextInputType.phone,
                    validator: (val) =>
                    val == null || val.isEmpty ? 'Enter phone' : null,
                    onSaved: (val) => _employeeData['phone'] = val ?? '',
                  ),
                  const SizedBox(height: 12),

                  // Password
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() => _showPassword = !_showPassword);
                        },
                      ),
                    ),
                    obscureText: !_showPassword,
                    validator: (val) =>
                    val == null || val.isEmpty ? 'Enter password' : null,
                    onSaved: (val) => _employeeData['password'] = val ?? '',
                  ),
                  const SizedBox(height: 12),

                  // Location
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Location', prefixIcon: Icon(Icons.location_on)),
                    validator: (val) =>
                    val == null || val.isEmpty ? 'Enter location' : null,
                    onSaved: (val) => _employeeData['location'] = val ?? '',
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Employee'),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
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
