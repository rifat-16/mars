import 'package:flutter/material.dart';
import '../widgets/main_app_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(title: 'Dashboard', icon: Icons.dashboard),
    );
  }
}
