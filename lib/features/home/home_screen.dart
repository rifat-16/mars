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
      body: Column(
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/logo-removebg-preview.png',
                height: 80,
              ),
              SizedBox(height: 10),
              Text(
                'Hi user! Welcome to Mars',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ActionButton(
                    title: ' Medicine ',
                    icon: Icons.medical_services,
                    onTap: _navigateToAddMedicineScreen,
                  ),
                  ActionButton(
                    title: '   Order   ',
                    icon: Icons.shopping_cart,
                    onTap: () {},
                  ),
                  ActionButton(
                      title: 'Dashboard',
                      icon: Icons.dashboard,
                      onTap: () {}
                  ),
                  ActionButton(
                      title: 'Employee',
                      icon: Icons.person,
                      onTap: () {}
                  ),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToAddMedicineScreen() {
    Navigator.pushNamed(context, '/medicine');
  }

}
