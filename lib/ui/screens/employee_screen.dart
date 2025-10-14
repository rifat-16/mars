import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/main_app_bar.dart';
import 'add_new_employee_screen.dart';
import 'edit_employee_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  Map<String, bool> _expandedMap = {};

  static const Color _accentColor = Color(0xFF4CAF50); // Modern green accent

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'Employee List', icon: Icons.people_alt),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('employees')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No employees found"));

          final employees = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            itemCount: employees.length,
            itemBuilder: (_, index) {
              final emp = employees[index];
              final data = emp.data()! as Map<String, dynamic>;
              final isExpanded = _expandedMap[emp.id] ?? false;

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: _accentColor.withOpacity(0.15),
                          child: Text(
                            data['name'][0].toUpperCase(),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                letterSpacing: 1.2,
                                color: _accentColor),
                          ),
                        ),
                        title: Text(
                          data['name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 20, color: Colors.black87),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            data['position'],
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w500),
                          ),
                        ),
                        trailing: AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          child: Icon(Icons.keyboard_arrow_down_rounded, color: _accentColor, size: 32),
                        ),
                        onTap: () {
                          setState(() {
                            _expandedMap[emp.id] = !isExpanded;
                          });
                        },
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        child: isExpanded
                            ? Padding(
                                padding: const EdgeInsets.fromLTRB(0, 12, 0, 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _infoRow('Email', data['email']),
                                    _infoRow('Phone', data['phone']),
                                    _infoRow('Password', data['password']),
                                    _infoRow('Location', data['location']),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          onPressed: () => _editEmployee(emp.id),
                                          icon: Icon(Icons.edit_rounded, color: _accentColor, size: 28),
                                          tooltip: 'Edit Employee',
                                        ),
                                        IconButton(
                                          onPressed: () => _confirmDelete(emp.id),
                                          icon: Icon(Icons.delete_outline_rounded,
                                              color: _accentColor.withOpacity(0.7), size: 28),
                                          tooltip: 'Delete Employee',
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
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEmployeeScreen()));
        },
        backgroundColor: _accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87, letterSpacing: 0.4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w400, color: Colors.black54, letterSpacing: 0.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String employeeId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _accentColor, size: 28),
            const SizedBox(width: 10),
            const Text('Confirm Delete'),
          ],
        ),
        content: const Text('Are you sure you want to delete this employee?', style: TextStyle(fontSize: 16)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
              textStyle: const TextStyle(fontWeight: FontWeight.w500),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteEmployee(employeeId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteEmployee(String employeeId) async {
    try {
      await FirebaseFirestore.instance.collection('employees').doc(employeeId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Employee deleted successfully'),
            backgroundColor: _accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete employee: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        );
      }
    }
  }

  void _editEmployee(String employeeId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditEmployeeScreen(employeeId: employeeId)),
    );
  }
}
