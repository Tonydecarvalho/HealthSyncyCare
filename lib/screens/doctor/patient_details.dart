import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PatientDetailsPage extends StatelessWidget {
  final String patientId;

  const PatientDetailsPage({Key? key, required this.patientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
        backgroundColor: const Color(0xFF008000),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(patientId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Patient not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    color: Color(0xFF008000),
                  ),
                ),
                _buildSymptomHistoryList(),
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
          .snapshots(),
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
                subtitle: _buildSymptomList(condition.reference),
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
