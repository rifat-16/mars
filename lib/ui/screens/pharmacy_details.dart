import 'package:Mars/ui/screens/pharmacy_orders_history.dart';
import 'package:Mars/ui/widgets/main_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/pharmacy_details_card.dart';
import 'customer_payment_received_history.dart';

class PharmacyDetails extends StatefulWidget {
  const PharmacyDetails({super.key});

  @override
  State<PharmacyDetails> createState() => _PharmacyDetailsState();
}

class _PharmacyDetailsState extends State<PharmacyDetails> {
  Map<String, dynamic>? pharmacyData;

  Future<double> _calculateTotalPayments(String phone) async {
    double total = 0;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('pharmacyPhone', isEqualTo: phone)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = double.tryParse(data['amount'].toString()) ?? 0;
        total += amount;
      }
    } catch (e) {
      debugPrint('Error calculating total payments: $e');
    }
    return total;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      pharmacyData = args;
    }
  }

  Future<double> _calculateTotalOrdersAmount(String phone) async {
    double total = 0;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('phoneNumber', isEqualTo: phone)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = double.tryParse(data['totalAmount'].toString()) ?? 0;
        total += amount;
      }
    } catch (e) {
      debugPrint('Error calculating total orders: $e');
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final name = pharmacyData?['name'] ?? 'Unknown Pharmacy';
    final address = pharmacyData?['address'] ?? 'Address not available';
    final phone = pharmacyData?['phone'] ?? 'N/A';
    final pharmacyId = pharmacyData?['id'];

    return Scaffold(
      appBar: MainAppBar(title: 'Pharmacy Details', icon: Icons.local_pharmacy),
      body: pharmacyId == null
          ? _buildPharmacyInfo(name, address, phone)
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('pharmacies')
                  .doc(pharmacyId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error loading data: ${snapshot.error}'));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Pharmacy not found'));
                }

                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};

                return _buildPharmacyInfo(
                  data['name'] ?? name,
                  data['address'] ?? address,
                  data['phone'] ?? phone,
                );
              },
            ),
    );
  }

  Widget _buildPharmacyInfo(String name, String address, String phone) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.store, color: Colors.white, size: 26),
                    SizedBox(width: 10),
                    Text(
                      'Customer Information',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoRow('Name', name),
                const SizedBox(height: 10),
                _buildInfoRow('Address', address),
                const SizedBox(height: 10),
                _buildInfoRow('Phone', phone),
              ],
            ),
          ),
          FutureBuilder(
            future: Future.wait([
              _calculateTotalOrdersAmount(phone),
              _calculateTotalPayments(phone),
            ]),
            builder: (context, AsyncSnapshot<List<double>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final totalOrders = snapshot.data?[0] ?? 0;
              final totalPayments = snapshot.data?[1] ?? 0;
              final totalDue = totalOrders - totalPayments;

              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return PharmacyOrdersHistory(phoneNumber: phone);
                      }));
                    },
                    child: PharmacyDetailsCard(
                      title: 'Total Medicine Ordered',
                      totalAmount: '${totalOrders.toStringAsFixed(2)} Tk',
                      color: Colors.amber,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return CustomerPaymentReceivedHistory(phoneNumber: phone);
                      }));
                    },
                    child: PharmacyDetailsCard(
                      title: 'Total Payment Received',
                      totalAmount: '${totalPayments.toStringAsFixed(2)} Tk',
                      color: Colors.green,
                    ),
                  ),
                  PharmacyDetailsCard(
                    title: 'Total Due Left',
                    totalAmount: '${totalDue.toStringAsFixed(2)} Tk',
                    color: totalDue > 0 ? Colors.red : Colors.grey,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Text(
      '$label: $value',
      style: const TextStyle(
        fontSize: 18,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
