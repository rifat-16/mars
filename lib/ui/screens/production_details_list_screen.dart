import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../widgets/main_app_bar.dart';

class ProductionDetailsListScreen extends StatefulWidget {
  ProductionDetailsListScreen({super.key});

  Future<List<Map<String, dynamic>>> _getProductionDetails() async {
    final snapshot = await FirebaseFirestore.instance.collection('productions').get();
    List<Map<String, dynamic>> dataList = snapshot.docs.map((doc) => doc.data()).toList();

    // Sort by date, recent first
    dataList.sort((a, b) {
      Timestamp dateA = a['date'] ?? Timestamp(0, 0);
      Timestamp dateB = b['date'] ?? Timestamp(0, 0);
      return dateB.compareTo(dateA); // recent first
    });

    // Serial number update
    for (int i = 0; i < dataList.length; i++) {
      dataList[i]['serial'] = i + 1;
    }

    return dataList;
  }

  @override
  State<ProductionDetailsListScreen> createState() => _ProductionDetailsListScreenState();
}

class _ProductionDetailsListScreenState extends State<ProductionDetailsListScreen> {
  List<Map<String, dynamic>> _productionList = [];
  List<Map<String, dynamic>> _filteredList = [];
  bool _isLoading = true;
  String _selectedFilter = 'Today';

  final List<String> filters = ['Today', 'Last 7 Days', 'Last Month', 'Last Year'];

  @override
  void initState() {
    super.initState();
    widget._getProductionDetails().then((data) {
      setState(() {
        _productionList = data;
        _applyFilter(); // initial filter
        _isLoading = false;
      });
    });
  }

  void _applyFilter() {
    final now = DateTime.now();
    setState(() {
      if (_selectedFilter == 'Today') {
        _filteredList = _productionList.where((item) {
          final date = (item['date'] as Timestamp).toDate();
          return date.year == now.year && date.month == now.month && date.day == now.day;
        }).toList();
      } else if (_selectedFilter == 'Last 7 Days') {
        _filteredList = _productionList.where((item) {
          final date = (item['date'] as Timestamp).toDate();
          return date.isAfter(now.subtract(const Duration(days: 7)));
        }).toList();
      } else if (_selectedFilter == 'Last Month') {
        _filteredList = _productionList.where((item) {
          final date = (item['date'] as Timestamp).toDate();
          return date.year == now.year && date.month == now.month - 1;
        }).toList();
      } else if (_selectedFilter == 'Last Year') {
        _filteredList = _productionList.where((item) {
          final date = (item['date'] as Timestamp).toDate();
          return date.year == now.year - 1;
        }).toList();
      }

      // Serial number update after filter
      for (int i = 0; i < _filteredList.length; i++) {
        _filteredList[i]['serial'] = i + 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        title: 'Production Details',
        icon: Icons.production_quantity_limits,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Filter Dropdown
          Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade200],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  isExpanded: true,
                  dropdownColor: Colors.green.shade100,
                  items: filters.map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: Text(
                        filter,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _selectedFilter = value;
                      _applyFilter();
                    }
                  },
                ),
              ),
            ),
          ),
          // Production List
          Expanded(
            child: ListView.builder(
              itemCount: _filteredList.length,
              itemBuilder: (context, index) {
                final item = _filteredList[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 6,
                  shadowColor: Colors.green.shade100,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.green.shade600,
                      child: Text(
                        '${item['serial']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    title: Text(
                      item['productName'] ?? 'No Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      item['date'] != null
                          ? DateFormat('dd MMM yyyy').format((item['date'] as Timestamp).toDate())
                          : 'No Date',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade300, Colors.green.shade100],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${item['quantity'].toString()} pcs',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}