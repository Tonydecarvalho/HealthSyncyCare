import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PatientDetailsPage extends StatelessWidget {
  final String patientId; // This holds the patient's ID for querying Firestore.

  const PatientDetailsPage({Key? key, required this.patientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details', style: TextStyle(color: Colors.white)),
        leading: IconButton( // Defines a back button to return to the previous screen.
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),  
        backgroundColor: const Color(0xFF176139),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(patientId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Shows a loading spinner while data is being fetched.
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Patient not found.')); // Error handling for no data found.
          }

          final data = snapshot.data!.data() as Map<String, dynamic>; // Extracts patient data from the snapshot.
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Each ListTile displays a different attribute of the patient.
                ListTile(
                  title: const Text('Full Name'),
                  subtitle: Text("${data['lastName']} ${data['firstName']}"),
                ),
                ListTile(
                  title: const Text('Date of Birth'),
                  subtitle: Text(DateFormat('dd.MM.yyyy').format(DateTime.parse(data['dateOfBirth']))),
                ),
                ListTile(
                  title: const Text('Gender'),
                  subtitle: Text(data['gender']),
                ),
                ListTile(
                  title: const Text('Phone'),
                  subtitle: Text(data['phone']),
                ),
                ListTile(
                  title: const Text('Email'),
                  subtitle: Text(data['email']),
                ),
                ListTile(
                  title: const Text('Address'),
                  subtitle: Text(data['address']),
                ),
                ListTile(
                  title: const Text('City'),
                  subtitle: Text(data['city']),
                ),
                ListTile(
                  title: const Text('Postal Code'),
                  subtitle: Text(data['postalCode']),
                ),
                ListTile(
                  title: const Text('Country'),
                  subtitle: Text(data['country']),
                ),
                const Divider(thickness: 2.0),
                const SizedBox(height: 20.0),
                const Text(
                  "Symptom History",
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF176139),
                  ),
                ),
                _buildSymptomHistoryList(), // Calls a method to build the symptom history list.
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSymptomHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conditions')
          .where('patientId', isEqualTo: patientId)
          .orderBy('timestamp', descending: true)
          .snapshots(), // Fetches condition data for the patient, sorted by timestamp.
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No symptom history found."),
          );
        }

        final conditions = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: conditions.length,
          itemBuilder: (context, index) {
            final condition = conditions[index];
            final Timestamp timestamp = condition['timestamp'];
            final String formattedDate =
                DateFormat('dd.MM.yyyy').format(timestamp.toDate());

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 2.0,
              child: ListTile(
                title: Text(
                  "Condition reported on $formattedDate",
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: _buildSymptomList(condition.reference), // Builds a list of symptoms for each condition.
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSymptomList(DocumentReference conditionRef) {
    return StreamBuilder<QuerySnapshot>(
      stream: conditionRef.collection('symptoms').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No symptoms recorded.");
        }

        final symptoms = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: symptoms.map((symptom) {
            final description = symptom['description'];
            final int duration = symptom['duration'];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                "$description - Duration: $duration days",
                style: const TextStyle(fontSize: 16.0, color: Colors.black54),
              ),
            );
          }).toList(), 
        );
      },
    );
  }
}
