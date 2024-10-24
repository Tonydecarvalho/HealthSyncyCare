import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<Map<String, dynamic>> _getUserAndDoctorData() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (!userSnapshot.exists) {
      throw Exception("User does not exist!");
    }

    Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;

    if (userData.containsKey('doctorId') && userData['doctorId'] != null) {
      String doctorId = userData['doctorId'];
      DocumentSnapshot doctorSnapshot = await FirebaseFirestore.instance.collection('users').doc(doctorId).get();

      if (doctorSnapshot.exists) {
        userData['doctorData'] = doctorSnapshot.data() as Map<String, dynamic>;
      }
    }

    return userData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF008000),
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserAndDoctorData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 50.0),
                  const SizedBox(height: 10.0),
                  Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 18.0)),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No user data found!'));
          }

          Map<String, dynamic> userData = snapshot.data!;
          Map<String, dynamic>? doctorData = userData['doctorData'];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              CircleAvatar(
                radius: 50.0,
                backgroundColor: const Color(0xFF008000),
                child: const Icon(
                  Icons.account_circle,
                  size: 70.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20.0),
              Text(
                FirebaseAuth.instance.currentUser?.email ?? 'User',
                style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              _buildUserInfoCard(userData),
              const SizedBox(height: 15.0),
              doctorData != null ? _buildDoctorInfoCard(doctorData) : _buildNoDoctorInfo(),
              const SizedBox(height: 15.0),
              ElevatedButton(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                ),
                child: const Text('Logout'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserInfoCard(Map<String, dynamic> userData) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gender : ${userData['gender'] ?? ' - '}', style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('First Name : ${userData['firstName'] ?? ' - '}', style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Last Name : ${userData['lastName'] ?? ' - '}', style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Date of Birth : ${userData['dateOfBirth'] ?? ' - '}', style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Address : ${userData['address'] ?? ' - '}', style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('City : ${userData['city'] ?? ' - '}', style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Postal Code : ${userData['postalCode'] ?? ' - '}', style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Country : ${userData['country'] ?? ' - '}', style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Phone : ${userData['phone'] ?? ' - '}', style: const TextStyle(fontSize: 16.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorInfoCard(Map<String, dynamic> doctorData) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My doctor', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10.0),
            Text('Name : ${doctorData['name'] ?? ' - '}', style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Phone : ${doctorData['phone'] ?? ' - '}', style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Email : ${doctorData['email'] ?? ' - '}', style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Address : ${doctorData['address'] ?? ' - '}', style: const TextStyle(fontSize: 16.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDoctorInfo() {
    return const Card(
      elevation: 4.0,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No doctor information found!',
          style: TextStyle(fontSize: 16.0, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}
