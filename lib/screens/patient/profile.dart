import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthsyncycare/screens/privacy_policy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  // Create the state for our class
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Variables for edition
  bool _isEditing = false;
  final TextEditingController _addressController = TextEditingController(); // Controllers for the text fields
  final TextEditingController _cityController = TextEditingController(); // Controllers for the text fields
  final TextEditingController _postalCodeController = TextEditingController(); // Controllers for the text fields
  final TextEditingController _phoneController = TextEditingController(); // Controllers for the text fields

  // Logout function
  Future<void> _logout(BuildContext context) async {
    // Sign out the user
    await FirebaseAuth.instance.signOut();
    // Redirect to the login screen
    Navigator.of(context).pushReplacementNamed('/login');
  }

  // Get the user data from Firestore
  Future<Map<String, dynamic>> _getUserAndDoctorData() async {
    // Get the user ID
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Get the user data from Firestore
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (!userSnapshot.exists) {
      throw Exception("User does not exist!");
    }

    // Get the user data as a Map 
    Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;

    // Get the doctor data if the user has a doctor
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

    // Set initial values for controllers
    _addressController.text = userData['address'] ?? '';
    _cityController.text = userData['city'] ?? '';
    _postalCodeController.text = userData['postalCode'] ?? '';
    _phoneController.text = userData['phone'] ?? '';

    return userData;
  }

  // Update the user data in Firestore with the new values
  Future<void> _updateUserData() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'address': _addressController.text,
      'city': _cityController.text,
      'postalCode': _postalCodeController.text,
      'phone': _phoneController.text,
    });
  }

  // Navigate to the privacy policy page when the user clicks on the link
  void _navigateToPrivacyPolicy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
    );
  }
  
  // Delete the user account 
  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final TextEditingController _confirmationController =
        TextEditingController();
    // Show a dialog to confirm the deletion
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
        backgroundColor: const Color(0xFF176139),
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
         leading: IconButton( // Back button
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Edit and Save buttons
          if (!_isEditing)
            IconButton( // Edit button state
              icon: const Icon(Icons.edit),
              color: Colors.white,
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              color: Colors.white,
              onPressed: () async {
                await _updateUserData();
                setState(() {
                  _isEditing = false;
                });
              },
            ),
        ],
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
             Image.asset(
                  'assets/Healthsyncycare.png',
                  height: 100,
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
                  backgroundColor: Color(0xFF176139),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Logout', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),

              const SizedBox(height: 10.0),

              // Delete Account button
              OutlinedButton(
                onPressed: () => _deleteAccount(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 15.0),
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Delete Account',
                    style: TextStyle(fontSize: 18, color: Colors.red)),
              ),
              const SizedBox(height: 20),

              // Add the privacy policy link
              TextButton(
                onPressed: () => _navigateToPrivacyPolicy(context),
                child: Text(
                  "Privacy Policy",
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
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
    // User information card
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gender: ${userData['gender'] ?? ' - '}',
                style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('First Name: ${userData['firstName'] ?? ' - '}',
                style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Last Name: ${userData['lastName'] ?? ' - '}',
                style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Date of Birth: $formattedDateOfBirth',
                style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Country: ${userData['country'] ?? ' - '}',
                style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            _isEditing
                ? TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                    ),
                  )
                : Text('Address: ${userData['address'] ?? ' - '}',
                    style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            _isEditing
                ? TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                    ),
                  )
                : Text('City: ${userData['city'] ?? ' - '}',
                    style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            _isEditing
                ? TextField(
                    controller: _postalCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Postal Code',
                    ),
                  )
                : Text('Postal Code: ${userData['postalCode'] ?? ' - '}',
                    style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            _isEditing
                ? TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                    ),
                  )
                : Text('Phone: ${userData['phone'] ?? ' - '}',
                    style: const TextStyle(fontSize: 16.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorInfoCard(Map<String, dynamic> doctorData) {
    final String fullName =
        '${doctorData['firstName'] ?? ' - '} ${doctorData['lastName'] ?? ' - '}';

    // Doctor information card
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
            Text('Name: $fullName', style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Phone: ${doctorData['phone'] ?? ' - '}',
                style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Email: ${doctorData['email'] ?? ' - '}',
                style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 10.0),
            Text('Address: ${doctorData['address'] ?? ' - '}',
                style: const TextStyle(fontSize: 16.0)),
          ],
        ),
      ),
    );
  }
  // No doctor information card
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
