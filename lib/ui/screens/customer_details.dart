import 'package:Mars/ui/screens/customer_orders_history.dart';
import 'package:Mars/ui/widgets/main_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../service/sms_service.dart';
import '../widgets/pharmacy_details_card.dart';
import 'customer_payment_received_history.dart';

class CustomerDetails extends StatefulWidget {
  const CustomerDetails({super.key});

  @override
  State<CustomerDetails> createState() => _CustomerDetailsState();
}

class _CustomerDetailsState extends State<CustomerDetails> {
  Map<String, dynamic>? pharmacyData;
  bool _isLoading = false;


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
                const SizedBox(height: 10),
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
                  padding: EdgeInsets.all(6),
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
                        return CustomerPaymentReceivedHistory(phoneNumber: phone);
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
          const SizedBox(height: 10),
          // inside _buildPharmacyInfo Column er last e ElevatedButton er jaygay
          // inside _buildPharmacyInfo
          // inside _buildPharmacyInfo
          Padding(
            padding: const EdgeInsets.all(20),
            child: FutureBuilder<DocumentSnapshot>(
              // Check if SMS already sent today
              future: FirebaseFirestore.instance
                  .collection('sms_logs')
                  .doc('${phone}_${DateTime.now().toIso8601String().substring(0,10)}')
                  .get(),
              builder: (context, snapshot) {
                bool smsAlreadySent = false;
                if (snapshot.hasData && snapshot.data!.exists) {
                  smsAlreadySent = true;
                }

                return ElevatedButton(
                  onPressed: smsAlreadySent || _isLoading
                      ? null
                      : () async {
                    setState(() { _isLoading = true; });

                    try {
                      final totalOrders = await _calculateTotalOrdersAmount(phone);
                      final totalPayments = await _calculateTotalPayments(phone);
                      final totalDue = totalOrders - totalPayments;

                      String smsMessage =
                          'Hello ${pharmacyData?['name'] ?? 'Customer'}, your total due amount is ${totalDue.toStringAsFixed(2)} TK. Please pay at your earliest convenience. Thank you! (MARS Laboratories Unani) ';

                      await SmsService.sendSms(number: phone, message: smsMessage);

                      // Log SMS
                      await FirebaseFirestore.instance
                          .collection('sms_logs')
                          .doc('${phone}_${DateTime.now().toIso8601String().substring(0,10)}')
                          .set({
                        'phone': phone,
                        'date': DateTime.now().toIso8601String(),
                        'message': smsMessage,
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Due amount SMS sent successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to send SMS: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      setState(() { _isLoading = false; });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: smsAlreadySent ? Colors.grey : Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : Text(
                    smsAlreadySent ? 'SMS Already Sent Today' : 'Send Due SMS',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
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
