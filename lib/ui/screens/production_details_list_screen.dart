import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../widgets/main_app_bar.dart';

class ProductionDetailsListScreen extends StatefulWidget {
      ProductionDetailsListScreen({super.key});

  Future<List<Map<String, dynamic>>> _getProductionDetails() async {
    final snapshot = await FirebaseFirestore.instance.collection('productions').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  State<ProductionDetailsListScreen> createState() => _ProductionDetailsListScreenState();
}

class _ProductionDetailsListScreenState extends State<ProductionDetailsListScreen> {
  List<Map<String, dynamic>> _productionList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    widget._getProductionDetails().then((data) {
      setState(() {
        _productionList = data;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'Production Details', icon: Icons.production_quantity_limits),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _productionList.length,
              itemBuilder: (context, index) {
                final item = _productionList[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  title: Text(item['productName'] ?? 'No Name'),
                  subtitle: Text(
                    item['date'] != null
                        ? DateFormat('dd MMM yyyy').format((item['date'] as Timestamp).toDate())
                        : 'No Date',
                  ),
                  trailing: Text(item['quantity'].toString()),
                );
              },
            ),
    );
  }
}
