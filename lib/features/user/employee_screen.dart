import 'package:flutter/material.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  List<Map<String, String>> _employees = [
    {
      'name': 'John Doe',
      'position': 'Manager',
      'email': 'john@example.com',
      'phone': '017xxxxxxxx',
      'password': 'john1234',
      'location': 'Dhaka',
    },
    {
      'name': 'Jane Smith',
      'position': 'Staff',
      'email': 'jane@example.com',
      'phone': '018xxxxxxxx',
      'password': 'jane5678',
      'location': 'Chittagong',
    },
  ];

  String _searchQuery = '';

  List<Map<String, String>> get _filteredEmployees {
    if (_searchQuery.isEmpty) return _employees;
    return _employees
        .where((e) =>
        e['name']!.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _deleteEmployee(int index) {
    setState(() {
      _employees.removeAt(index);
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Employee deleted')));
  }

  void _editEmployee(int index) {
    print("Edit Employee: ${_employees[index]['name']}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee List'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          setState(() {});
        },
        child: _filteredEmployees.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.people_outline, size: 80, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No employees found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: _filteredEmployees.length,
          itemBuilder: (_, index) {
            final employee = _filteredEmployees[index];
            bool _showPassword = false;
            return StatefulBuilder(
              builder: (context, setInnerState) => Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      employee['name']?[0] ?? '?',
                      style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    employee['name'] ?? 'No Name',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(employee['position'] ?? 'No Position'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${employee['email']}'),
                          Text('Phone: ${employee['phone']}'),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text('Password: ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500)),
                              Expanded(
                                child: Text(
                                  _showPassword
                                      ? employee['password']!
                                      : '********',
                                  style: const TextStyle(
                                      fontFamily: 'monospace'),
                                ),
                              ),
                              IconButton(
                                icon: Icon(_showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () {
                                  setInnerState(() {
                                    _showPassword = !_showPassword;
                                  });
                                },
                              ),
                            ],
                          ),
                          Text('Location: ${employee['location']}'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.green),
                                onPressed: () => _editEmployee(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () => _deleteEmployee(index),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/addEmployee').then((_) {
            setState(() {});
          });
        },
        child: const Icon(Icons.add),
      )
    );
  }
}
