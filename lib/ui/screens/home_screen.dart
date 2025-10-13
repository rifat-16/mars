import 'package:Mars/ui/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/action_button.dart';
import '../widgets/main_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userRole;
  String? _firstName;
  String? currentUserPhone;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('position');
      _firstName = prefs.getString('first_name');
      currentUserPhone = prefs.getString('phone');
    });
  }

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
                    'Hi $_firstName ! Welcome to Mars',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
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
                  title: '   Orders   ',
                  icon: Icons.shopping_cart,
                  onTap: _navigateToOrdersScreen,
                ),
                ActionButton(
                  title: 'Dashboard',
                  icon: Icons.dashboard,
                  onTap: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DashboardScreen(currentUserPhone: currentUserPhone!)));
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Buttons Row 2
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (userRole == 'Owner')
                  ActionButton(
                    title: ' Employee ',
                    icon: Icons.person,
                    onTap: _navigateToEmployeeScreen,
                  ),
                if (userRole == 'Owner' || userRole == 'Manager')
                  ActionButton(
                    title: ' Inventory ',
                    icon: Icons.inventory_2,
                    onTap: _navigateToInventoryScreen,
                  ),
                if (userRole == 'Owner' || userRole == 'Manager')
                  ActionButton(
                    title: 'Invoice',
                    icon: Icons.add,
                    onTap: _navigateToAddOrderScreen,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Add more buttons as needed
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (userRole == 'Owner' || userRole == 'Manager')
                  ActionButton(
                    title: 'Production Details',
                    icon: Icons.production_quantity_limits,
                    onTap: _navigateToProductionDetailsScreen,
                  ),
                if (userRole == 'Owner' || userRole == 'Manager')
                  ActionButton(
                    title: ' Add Production ',
                    icon: Icons.production_quantity_limits,
                    onTap: _navigateToProductionScreen,
                  ),
                if (userRole == 'Owner')
                  ActionButton(
                    title: 'Add Medicine',
                    icon: Icons.add,
                    onTap: _navigateToAddMedicineScreen,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Add more buttons as needed
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (userRole == 'Owner' || userRole == 'Manager')
                  ActionButton(
                    title: 'Customers List',
                    icon: Icons.local_pharmacy,
                    onTap: _navigateToPharmacyListScreen,
                  ),
                if (userRole == 'Owner')
                  ActionButton(
                    title: 'Payment Received',
                    icon: Icons.payment,
                    onTap: _navigateToPaymentReceivedScreen,
                  ),
                ActionButton(
                  title: 'Update coming soon',
                  icon: Icons.update,
                  onTap: () {},
                ),
              ],
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
            unselectedLabelStyle: const TextStyle(fontSize: 12),
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
      ),
    );
  }

  void _navigateToMedicineScreen() {
    Navigator.pushNamed(context, '/medicine');
  }

  void _navigateToOrdersScreen() {
    Navigator.pushNamed(context, '/orders');
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

  void _navigateToProductionDetailsScreen() {
    Navigator.pushNamed(context, '/productionDetails');
  }

  void _navigateToPharmacyListScreen() {
    Navigator.pushNamed(context, '/pharmacyList');
  }

  void _navigateToPaymentReceivedScreen() {
    Navigator.pushNamed(context, '/paymentReceived');
  }
}
