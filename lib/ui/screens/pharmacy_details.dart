import 'package:Mars/ui/widgets/main_app_bar.dart';
import 'package:flutter/material.dart';

import '../widgets/pharmacy_details_card.dart';

class PharmacyDetails extends StatefulWidget {
  const PharmacyDetails({super.key});

  @override
  State<PharmacyDetails> createState() => _PharmacyDetailsState();
}

class _PharmacyDetailsState extends State<PharmacyDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'Pharmacy Details', icon: Icons.local_pharmacy),
      body: Column(
        children: [
          SizedBox(height: 20,),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.store, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Pharmacy Information',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Name: GreenLife Pharmacy',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Address: 123 Main Street, Dhaka',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Phone: +880 1234 567890',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          PharmacyDetailsCard(title: 'Total Medicine Ordered', totalAmount: '1000000 Tk', color: Colors.amber),
          PharmacyDetailsCard(title: 'Total Payment Received', totalAmount: '1000000 Tk', color: Colors.green),
          PharmacyDetailsCard(title: 'Total Due Left', totalAmount: '1000000 Tk', color: Colors.red),
        ],
      ),
    );
  }
}

