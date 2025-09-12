import 'package:flutter/material.dart';
import 'package:mars/widgets/action_button.dart';
import 'package:mars/widgets/main_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'Home', icon: Icons.home),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Row
            Row(
              children: [
                Image.asset(
                  'assets/images/logo-removebg-preview.png',
                  height: 60,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hi User! Welcome to Mars',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Buttons Row 1
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ActionButton(
                  title: ' Medicine ',
                  icon: Icons.medical_services,
                  onTap: _navigateToAddMedicineScreen,
                ),
                ActionButton(
                  title: '   Orders   ',
                  icon: Icons.shopping_cart,
                  onTap: _navigateToOrdersScreen,
                ),
                ActionButton(
                  title: 'Dashboard',
                  icon: Icons.dashboard,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Buttons Row 2
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ActionButton(
                  title: ' Employee ',
                  icon: Icons.person,
                  onTap: () {},
                ),
                ActionButton(
                  title: ' Inventory ',
                  icon: Icons.inventory_2,
                  onTap: _navigateToInventoryScreen,
                ),
                ActionButton(
                  title: ' Production ',
                  icon: Icons.production_quantity_limits,
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Example Card for quick overview
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Today's Summary",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text("Total Orders: 25"),
                    Text("Pending Orders: 5"),
                    Text("Delivered Orders: 18"),
                    Text("Cancelled Orders: 2"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddMedicineScreen() {
    Navigator.pushNamed(context, '/medicine');
  }

  void _navigateToOrdersScreen() {
    Navigator.pushNamed(context, '/orders');
  }

  void _navigateToInventoryScreen() {
    Navigator.pushNamed(context, '/inventory');
  }
}
