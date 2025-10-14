import 'package:Mars/ui/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      backgroundColor: Colors.grey.shade100,
      appBar: MainAppBar(title: 'Home', icon: Icons.home),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade600, Colors.green.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade200.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/logo-removebg-preview.png',
                      height: 60,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Hi $_firstName! Welcome to Mars 🚀',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Modern Buttons Grid
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildActionCard('Medicine', Icons.medical_services, Colors.orange.shade400, _navigateToMedicineScreen),
                _buildActionCard('Orders', Icons.shopping_cart, Colors.blue.shade400, _navigateToOrdersScreen),
                _buildActionCard('Dashboard', Icons.dashboard, Colors.purple.shade400, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DashboardScreen(currentUserPhone: currentUserPhone!),
                    ),
                  );
                }),
                if (userRole == 'Owner') _buildActionCard('Employee', Icons.person, Colors.teal.shade400, _navigateToEmployeeScreen),
                if (userRole == 'Owner' || userRole == 'Manager') _buildActionCard('Inventory', Icons.inventory_2, Colors.red.shade400, _navigateToInventoryScreen),
                if (userRole == 'Owner' || userRole == 'Manager') _buildActionCard('Invoice', Icons.add, Colors.indigo.shade400, _navigateToAddOrderScreen),
                if (userRole == 'Owner' || userRole == 'Manager') _buildActionCard('Production', Icons.production_quantity_limits, Colors.deepOrange.shade400, _navigateToProductionDetailsScreen),
                if (userRole == 'Owner' || userRole == 'Manager') _buildActionCard('Add Production', Icons.production_quantity_limits, Colors.brown.shade400, _navigateToProductionScreen),
                if (userRole == 'Owner') _buildActionCard('Add Medicine', Icons.add, Colors.pink.shade400, _navigateToAddMedicineScreen),
                if (userRole == 'Owner' || userRole == 'Manager') _buildActionCard('Customers', Icons.local_pharmacy, Colors.green.shade400, _navigateToPharmacyListScreen),
                if (userRole == 'Owner') _buildActionCard('Payment Received', Icons.payment, Colors.blueGrey.shade400, _navigateToPaymentReceivedScreen),
                _buildActionCard('Coming Soon', Icons.update, Colors.grey.shade400, () {}),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 64) / 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.3),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.green.shade700,
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  void _navigateToMedicineScreen() => Navigator.pushNamed(context, '/medicine');
  void _navigateToOrdersScreen() => Navigator.pushNamed(context, '/orders');
  void _navigateToProfileScreen() => Navigator.pushNamed(context, '/profile');
  void _navigateToInventoryScreen() => Navigator.pushNamed(context, '/inventory');
  void _navigateToProductionScreen() => Navigator.pushNamed(context, '/addProduction');
  void _navigateToEmployeeScreen() => Navigator.pushNamed(context, '/employee');
  void _navigateToAddOrderScreen() => Navigator.pushNamed(context, '/createOrder');
  void _navigateToAddMedicineScreen() => Navigator.pushNamed(context, '/addMedicine');
  void _navigateToProductionDetailsScreen() => Navigator.pushNamed(context, '/productionDetails');
  void _navigateToPharmacyListScreen() => Navigator.pushNamed(context, '/pharmacyList');
  void _navigateToPaymentReceivedScreen() => Navigator.pushNamed(context, '/paymentReceived');
}