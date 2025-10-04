import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  String _address = '';

  @override
  void initState() {
    super.initState();
    _getProfileData();
  }

  Future<void> _getProfileData() async {
    // TODO: Replace with API call to get profile data
    try{
      final user = FirebaseAuth.instance.currentUser!.uid;
      final profileData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user)
          .get();
      if(profileData.exists){
        final data = profileData.data();
        if(data != null){
          setState(() {
            _firstName = data['first_name'];
            _lastName = data['last_name'];
            _email = data['email'];
            _phone = data['phone'];
            _address = data['address'];
          });
        }
      }
    } catch (e) {
      // ❌ Error handle
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage("assets/images/logo-removebg-preview.png"),
                  ),
                  const SizedBox(height: 10),
                  Text(_firstName + " " + _lastName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(_email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text("Edit Profile"),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildProfileTile(Icons.phone, "Phone", _phone),
                  _buildProfileTile(Icons.location_on, "Address", _address),
                  _buildProfileTile(Icons.logout, "Logout", "Sign out from the app"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(IconData ?icon, String title, String subtitle) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: () {},
      ),
    );
  }
}
