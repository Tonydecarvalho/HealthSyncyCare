import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthsyncycare/screens/privacy_policy.dart'; // Import the Privacy Policy screen
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import intl for date formatting

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<Map<String, dynamic>> _getUserAndDoctorData() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (!userSnapshot.exists) {
      throw Exception("User does not exist!");
    }

    Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;

    if (userData.containsKey('doctorId') && userData['doctorId'] != null) {
      String doctorId = userData['doctorId'];
      DocumentSnapshot doctorSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .get();

      if (doctorSnapshot.exists) {
        userData['doctorData'] = doctorSnapshot.data() as Map<String, dynamic>;
      }
    }

    return userData;
  }

  void _navigateToPrivacyPolicy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
    ); // Navigates to the Privacy Policy page
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final TextEditingController _confirmationController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Are you sure you want to delete your account?'),
              const SizedBox(height: 10),
              const Text('Type "delete" to confirm:'),
              TextField(
                controller: _confirmationController,
                decoration: const InputDecoration(
                  labelText: 'Confirmation',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_confirmationController.text.toLowerCase() == 'delete') {
                  try {
                    // Delete BookAppointments for the user
                    final uid = user?.uid;
                    if (uid != null) {
                      // Delete appointments where patientId matches
                      await FirebaseFirestore.instance
                          .collection('BookAppointments')
                          .where('patientId', isEqualTo: uid)
                          .get()
                          .then((querySnapshot) {
                        for (var doc in querySnapshot.docs) {
                          doc.reference.delete(); // Delete each appointment
                        }
                      });
                    }

                    // Delete the user account from Firebase Auth
                    await user?.delete();

                    // Log the user out and redirect to login screen
                    Navigator.of(context).pushReplacementNamed('/login');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please type "delete" to confirm')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
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
                  Text('Error: ${snapshot.error}',
                      style: const TextStyle(fontSize: 18.0)),
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
                style: const TextStyle(
                    fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              _buildUserInfoCard(userData),
              const SizedBox(height: 15.0),
              doctorData != null
                  ? _buildDoctorInfoCard(doctorData)
                  : _buildNoDoctorInfo(),
              const SizedBox(height: 15.0),

              // Logout button
              ElevatedButton(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 15.0),
                ),
                child: const Text('Logout'),
              ),

              const SizedBox(height: 10.0),

              // Delete Account button
              ElevatedButton(
                onPressed: () => _deleteAccount(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 15.0),
                ),
                child: const Text('Delete Account'),
              ),

              const SizedBox(height: 20),

              // Add the privacy policy link
              TextButton(
                onPressed: () => _navigateToPrivacyPolicy(context),
                child: Text(
                  "Privacy Policy",
                  style: TextStyle(
                    color: Colors.blue, // Set the color of the link
                    decoration: TextDecoration.underline, // Underline the link
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserInfoCard(Map<String, dynamic> userData) {
    // Format date of birth
    String formattedDateOfBirth = ' - ';
    if (userData['dateOfBirth'] != null) {
      try {
        DateTime dob = DateTime.parse(userData['dateOfBirth']);
        formattedDateOfBirth = DateFormat('dd.MM.yyyy').format(dob);
      } catch (e) {
        formattedDateOfBirth = 'Invalid Date';
      }
    }

    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gender : ${userData['gender'] ?? ' - '}',
                style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('First Name : ${userData['firstName'] ?? ' - '}',
                style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Last Name : ${userData['lastName'] ?? ' - '}',
                style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Date of Birth : $formattedDateOfBirth',
                style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Address : ${userData['address'] ?? ' - '}',
                style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('City : ${userData['city'] ?? ' - '}',
                style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Postal Code : ${userData['postalCode'] ?? ' - '}',
                style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Country : ${userData['country'] ?? ' - '}',
                style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Phone : ${userData['phone'] ?? ' - '}',
                style: const TextStyle(fontSize: 16.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorInfoCard(Map<String, dynamic> doctorData) {
    final String fullName =
        '${doctorData['firstName'] ?? ' - '} ${doctorData['lastName'] ?? ' - '}';

    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My doctor',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10.0),
            Text('Name : $fullName', style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Phone : ${doctorData['phone'] ?? ' - '}',
                style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Email : ${doctorData['email'] ?? ' - '}',
                style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Address : ${doctorData['address'] ?? ' - '}',
                style: const TextStyle(fontSize: 16.0)),
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
