import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/main_app_bar.dart';

class PharmacyList extends StatefulWidget {
  const PharmacyList({super.key});

  @override
  State<PharmacyList> createState() => _PharmacyListState();
}

class _PharmacyListState extends State<PharmacyList> {
  List<Map<String, dynamic>> _pharmacies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPharmacies();
  }

  Future<void> _fetchPharmacies() async {
    setState(() => _isLoading = true);
    try {
      // Fetch data from 'orders' collection
      final querySnapshot = await FirebaseFirestore.instance.collection('orders').get();

      // Map data to a list
      final List<Map<String, dynamic>> ordersData = querySnapshot.docs.map((doc) {
        return {
          'name': doc['customerName'] ?? 'Unnamed Pharmacy',
          'address': doc['address'] ?? 'Location not available',
          'phone': doc['phoneNumber'] ?? 'Phone not available',
        };
      }).toList();

      // Remove duplicates based on phone number
      final Map<String, Map<String, dynamic>> uniquePharmacies = {};
      for (var pharmacy in ordersData) {
        final phone = pharmacy['phone'] ?? '';
        if (!uniquePharmacies.containsKey(phone)) {
          uniquePharmacies[phone] = pharmacy;
        }
      }

      setState(() {
        _pharmacies = uniquePharmacies.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch orders: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'Pharmacy List', icon: Icons.local_pharmacy),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pharmacies.isEmpty
              ? const Center(child: Text('No pharmacies found'))
              : RefreshIndicator(
                  onRefresh: _fetchPharmacies,
                  child: ListView.builder(
                    itemCount: _pharmacies.length,
                    itemBuilder: (context, index) {
                      final pharmacy = _pharmacies[index];
                      return InkWell(
                        onTap: () => _navigateToPharmacyDetailsScreen(pharmacy),
                        child: Card(
                          margin: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.local_pharmacy),
                            ),
                            title: Text(
                              pharmacy['name'] ?? 'Unnamed Pharmacy',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              pharmacy['address'] ?? 'Location not available',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _navigateToPharmacyDetailsScreen(Map<String, dynamic> pharmacy) {
    Navigator.pushNamed(
      context,
      '/pharmacyDetails',
      arguments: pharmacy,
    );
  }
}
