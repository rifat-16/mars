import 'package:flutter/material.dart';

import '../widgets/main_app_bar.dart';

class AddPharmacy extends StatefulWidget {
  const AddPharmacy({super.key});

  @override
  State<AddPharmacy> createState() => _AddPharmacyState();
}

class _AddPharmacyState extends State<AddPharmacy> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'Add Pharmacy', icon: Icons.add_business),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pharmacy Information', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Pharmacy Name',
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Address',
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Phone',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Save'),
              )
            ]
          ),
        ),
      ),
    );
  }
}
