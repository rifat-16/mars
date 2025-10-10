import 'package:Mars/ui/widgets/main_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerPaymentReceivedHistory extends StatefulWidget {
  final String phoneNumber;
  const CustomerPaymentReceivedHistory({super.key, required this.phoneNumber});

  @override
  State<CustomerPaymentReceivedHistory> createState() => _CustomerPaymentReceivedHistoryState();
}

class _CustomerPaymentReceivedHistoryState extends State<CustomerPaymentReceivedHistory> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<void> _refreshFuture;
  int? _tappedIndex;

  Future<void> _refreshPayments() async {
    // Just rebuilding the widget will refresh the StreamBuilder
    setState(() {
      _tappedIndex = null;
      _refreshFuture = Future.value();
    });
    await _refreshFuture;
  }

  @override
  void initState() {
    super.initState();
    _refreshFuture = Future.value();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'Payment Received', icon: Icons.payment),
      body: RefreshIndicator(
        onRefresh: _refreshPayments,
        child: StreamBuilder<QuerySnapshot>(
          // Only fetch payments for this phone number
          stream: _firestore
              .collection('payments')
              .where('pharmacyPhone', isEqualTo: widget.phoneNumber)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No payments found.'));
            }
            final payments = snapshot.data!.docs;
            return ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index].data() as Map<String, dynamic>;
                final pharmacyName = payment['pharmacyName'] ?? 'Unknown Pharmacy';
                final amount = payment['amount'] != null ? payment['amount'].toString() : 'N/A';
                final paymentMethod = payment['paymentMethod'] ?? 'N/A';
                final timestamp = payment['timestamp'] != null
                    ? (payment['timestamp'] as Timestamp).toDate()
                    : null;
                final formattedTime = timestamp != null
                    ? '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}'
                    : 'Unknown time';

                final isTapped = _tappedIndex == index;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: isTapped ? 12 : 6,
                        offset: Offset(0, isTapped ? 8 : 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pharmacyName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Amount: \$${amount}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Payment Method: $paymentMethod',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Time: $formattedTime',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}