import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/domain/order_item.dart';
import '../../service/sms_service.dart';
import '../../state/orders_provider.dart';
import '../../state/session_provider.dart';
import '../widgets/main_app_bar.dart';

class OrdersDetailsScreen extends StatefulWidget {
  final String orderId;
  const OrdersDetailsScreen({super.key, required this.orderId});

  @override
  State<OrdersDetailsScreen> createState() => _OrdersDetailsScreenState();
}

class _OrdersDetailsScreenState extends State<OrdersDetailsScreen> {
  Future<void> _markDelivered({
    required String orderId,
    required String customerName,
    required String phoneNumber,
    required String totalAmount,
    required List<OrderItem> items,
    required String actorUid,
    required String actorName,
  }) async {
    final ordersProvider = context.read<OrdersProvider>();

    final updated = await ordersProvider.markOrderDelivered(
      orderId: orderId,
      items: items,
      actorUid: actorUid,
      actorName: actorName,
    );

    if (!mounted) return;

    if (!updated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ordersProvider.actionState.errorMessage ??
                'Failed to deliver order',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final productSummary = items
        .map((item) => '${item.product} x${item.quantity}')
        .join(', ');
    final smsMessage =
        'Hello $customerName, your order of $productSummary totaling $totalAmount TK has been delivered. Thank you! (MARS Laboratories Unani)';

    await SmsService.sendSms(number: phoneNumber, message: smsMessage);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order delivered and inventory updated'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final role = session.role;
    final actorUid = session.currentUser?.uid ?? '';
    final actorName = session.currentUser?.fullName.isNotEmpty == true
        ? session.currentUser!.fullName
        : 'Unknown';

    return Scaffold(
      appBar: const MainAppBar(
        title: 'Order Details',
        icon: Icons.shopping_cart,
      ),
      body: StreamBuilder(
        stream: context.read<OrdersProvider>().watchOrderById(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = snapshot.data;
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          final status = order.status;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow(
                          Icons.person_outline,
                          'Customer',
                          order.customerName,
                        ),
                        _detailRow(
                          Icons.phone_outlined,
                          'Phone',
                          order.phoneNumber,
                        ),
                        _detailRow(
                          Icons.location_on_outlined,
                          'Address',
                          order.address,
                        ),
                        _detailRow(
                          Icons.calendar_today_outlined,
                          'Date',
                          order.createdAt
                                  ?.toLocal()
                                  .toString()
                                  .split(' ')
                                  .first ??
                              'Unknown Date',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final item in order.items)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.shopping_bag_outlined),
                            title: Text(item.product),
                            trailing: Text('x${item.quantity}'),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          'Total Amount: ${order.totalAmount.toStringAsFixed(2)} TK',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Status: $status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: status == 'Delivered'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (status != 'Delivered' &&
                            (role == 'Owner' || role == 'Manager'))
                          ElevatedButton(
                            onPressed: () => _markDelivered(
                              orderId: order.id,
                              customerName: order.customerName,
                              phoneNumber: order.phoneNumber,
                              totalAmount: order.totalAmount.toStringAsFixed(2),
                              items: order.items,
                              actorUid: actorUid,
                              actorName: actorName,
                            ),
                            child: const Text('Delivered'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 10),
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
