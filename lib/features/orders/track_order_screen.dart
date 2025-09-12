import 'package:flutter/material.dart';
import 'package:mars/widgets/main_app_bar.dart';

class TrackOrderScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const TrackOrderScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Dummy tracking steps
    List<String> steps = ["Ordered", "Packed", "Shipped", "Delivered"];
    String status = order["status"];

    return Scaffold(
      appBar: const MainAppBar(title: 'Track Order', icon: Icons.local_shipping),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: steps.map((step) {
            bool completed = steps.indexOf(step) <= steps.indexOf(status);
            return ListTile(
              leading: Icon(
                completed ? Icons.check_circle : Icons.radio_button_unchecked,
                color: completed ? Colors.green : Colors.grey,
              ),
              title: Text(step),
            );
          }).toList(),
        ),
      ),
    );
  }
}
