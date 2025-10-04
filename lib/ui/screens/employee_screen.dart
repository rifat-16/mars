import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_new_employee_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  Map<String, bool> _expandedMap = {};
  Map<String, bool> _passwordVisibleMap = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee List'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('employees')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No employees found"));
          }

          final employees = snapshot.data!.docs;

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (_, index) {
              final emp = employees[index];
              final data = emp.data()! as Map<String, dynamic>;
              final isExpanded = _expandedMap[emp.id] ?? false;

              return InkWell(
                onTap: () {
                  setState(() {
                    _expandedMap[emp.id] = !(_expandedMap[emp.id] ?? false);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: CircleAvatar(child: Text(data['name'][0])),
                        title: Text(
                          data['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          data['position'],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        trailing: isExpanded
                            ? const Icon(Icons.keyboard_arrow_up)
                            : const Icon(Icons.keyboard_arrow_down),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: isExpanded
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Email:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '${data['email'] ?? 'N/A'}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Phone:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '${data['phone'] ?? 'N/A'}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Password:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              '${data['password'] ?? 'N/A'}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Location:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '${data['location'] ?? 'N/A'}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          onPressed: () {},
                                          icon: const Icon(Icons.edit,
                                            color: Colors.green,),
                                        ),
                                        IconButton(
                                          onPressed: () {},
                                          icon: const Icon(Icons.delete,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEmployeeScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
