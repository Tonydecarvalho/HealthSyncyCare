import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PatientConditionDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final DocumentSnapshot conditionData =
        ModalRoute.of(context)!.settings.arguments as DocumentSnapshot;

    final String patientId = conditionData['patientId'];
    final String conditionId = conditionData.id;
    final Timestamp timestamp = conditionData['timestamp'];
    final String formattedDate =
        DateFormat('yyyy.MM.dd - kk:mm').format(timestamp.toDate());

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF008000),
        title: const Text(
          'Patient Condition Details',
          style: TextStyle(
            fontSize: 23.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(patientId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Patient not found"));
          }

          final String patientName = snapshot.data!['name'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient name and condition date
                Center(
                  child: Column(
                    children: [
                      Text(
                        patientName,
                        style: TextStyle(
                          fontSize: 28.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF008000),
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.0),
                const Divider(thickness: 2.0),

                // Symptom Section
                const Text(
                  "Symptoms",
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF008000),
                  ),
                ),
                SizedBox(height: 16.0),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: conditionData.reference.collection('symptoms').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text("No symptoms recorded."));
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final symptomData = snapshot.data!.docs[index];
                          final String description = symptomData['description'];
                          final int duration = symptomData['duration'];
                          return buildSymptomCard(description, duration);
                        },
                      );
                    },
                  ),
                ),

                // Prescription button
                SizedBox(height: 20.0),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/create prescription',
                        arguments: {
                          'patientId': patientId,
                          'conditionId': conditionId,
                        },
                      );
                    },
                    backgroundColor: const Color(0xFF008000),
                    icon: const Icon(
                      Icons.local_pharmacy,
                      size: 30.0,
                      color: Color(0XFFFFFFFF),
                    ),
                    label: const Text(
                      'Prescription',
                      style: TextStyle(fontSize: 18.0, color: Color(0xFFFFFFFF)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget for each symptom card
  Widget buildSymptomCard(String description, int duration) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.local_hospital,
              color: Color(0xFF008000),
              size: 40.0,
            ),
            SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    '$duration days',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
