import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../state/payments_provider.dart';
import '../widgets/main_app_bar.dart';

class PaymentReceivedScreen extends StatefulWidget {
  const PaymentReceivedScreen({super.key});

  @override
  State<PaymentReceivedScreen> createState() => _PaymentReceivedScreenState();
}

class _PaymentReceivedScreenState extends State<PaymentReceivedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentsProvider>().listenPayments();
    });
  }

  Future<void> _refresh() async {
    await context.read<PaymentsProvider>().listenPayments();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PaymentsProvider>().state;

    return Scaffold(
      appBar: const MainAppBar(title: 'Payment Received', icon: Icons.payment),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Builder(
          builder: (context) {
            if (state.isLoading || state.isIdle) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.isError) {
              return ListView(
                children: [
                  const SizedBox(height: 220),
                  Center(
                    child: Text(
                      state.errorMessage ?? 'Failed to load payments',
                    ),
                  ),
                ],
              );
            }

            final payments = state.data ?? [];
            if (payments.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 220),
                  Center(child: Text('No payments found.')),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                final timestamp = payment.timestamp;
                final formattedTime = timestamp != null
                    ? '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}'
                    : 'Unknown time';

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.pharmacyName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Amount: ${payment.amount.toStringAsFixed(2)} TK',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Payment Method: ${payment.paymentMethod}'),
                        const SizedBox(height: 4),
                        Text(
                          'Time: $formattedTime',
                          style: const TextStyle(color: Colors.black54),
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
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addPayment),
      ),
    );
  }
}
