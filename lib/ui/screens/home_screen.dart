import 'package:flutter/material.dart';
import '../widgets/action_button.dart';
import '../widgets/main_app_bar.dart';

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
                  onTap: _navigateToMedicineScreen,
                ),
                ActionButton(
                    title: 'Add Medicine',
                    icon: Icons.add,
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
                  onTap: _navigateToDashboardScreen,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Buttons Row 2
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ActionButton(
                  title: ' Employee ',
                  icon: Icons.person,
                  onTap: _navigateToEmployeeScreen,
                ),
                ActionButton(
                  title: ' Inventory ',
                  icon: Icons.inventory_2,
                  onTap: _navigateToInventoryScreen,
                ),
                ActionButton(
                  title: ' Production ',
                  icon: Icons.production_quantity_limits,
                  onTap: _navigateToProductionScreen,
                ),
                ActionButton(
                    title: 'Invoice',
                    icon: Icons.add,
                    onTap: _navigateToAddOrderScreen,
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 40,),

              ]
            ),
          ],
        ),
      ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: BottomNavigationBar(
              currentIndex: 0,
              onTap: (index) {
                switch (index) {
                  case 0:
                    _navigateToDashboardScreen();
                    break;
                  case 1:
                    _navigateToOrdersScreen();
                    break;
                  case 2:
                    _navigateToProfileScreen();
                    break;
                }
              },
              backgroundColor: Colors.white,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.green,
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart_outlined),
                  activeIcon: Icon(Icons.shopping_cart),
                  label: 'Orders',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        )
    );
  }

  void _navigateToMedicineScreen() {
    Navigator.pushNamed(context, '/medicine');
  }

  void _navigateToOrdersScreen() {
    Navigator.pushNamed(context, '/orders');
  }

  void _navigateToDashboardScreen() {
    Navigator.pushNamed(context, '/dashboard');
  }

  void _navigateToProfileScreen() {
    Navigator.pushNamed(context, '/profile');
  }

  void _navigateToInventoryScreen() {
    Navigator.pushNamed(context, '/inventory');
  }

  void _navigateToProductionScreen() {
    Navigator.pushNamed(context, '/addProduction');
  }

  void _navigateToEmployeeScreen() {
    Navigator.pushNamed(context, '/employee');
  }

  void _navigateToAddOrderScreen() {
    Navigator.pushNamed(context, '/createOrder');
  }

  void _navigateToAddMedicineScreen() {
    Navigator.pushNamed(context, '/addMedicine');
  }

}
