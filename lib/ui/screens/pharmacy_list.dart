import 'package:flutter/material.dart';

import '../widgets/main_app_bar.dart';

class PharmacyList extends StatefulWidget {
  const PharmacyList({super.key});

  @override
  State<PharmacyList> createState() => _PharmacyListState();
}

class _PharmacyListState extends State<PharmacyList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'Pharmacy List', icon: Icons.local_pharmacy),
      body: ListView.builder(
          itemCount: 10,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: _NavigateToPharmacyDetailsScreen,
              child: Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.local_pharmacy),
                  ),
                  title: Text('Pharmacy $index',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('Location $index',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            );
          }
      )
    );
  }

  void _NavigateToPharmacyDetailsScreen() {
    Navigator.pushNamed(context, '/pharmacyDetails');
  }
}
