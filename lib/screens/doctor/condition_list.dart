import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PatientsConditions extends StatefulWidget {
  const PatientsConditions({super.key});

  @override
  State<PatientsConditions> createState() => _PatientsConditionsPage();
}

class _PatientsConditionsPage extends State<PatientsConditions> {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection("users");
  final CollectionReference conditionsCollection =
      FirebaseFirestore.instance.collection("conditions");
  final String? doctorId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(0xFF008000),
        title: Text(
          "Patients",
          style: TextStyle(
            fontSize: 23.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
      body: StreamBuilder(
        stream: usersCollection.where('doctorId', isEqualTo: doctorId).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> patientSnapshot) {
          if (patientSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (patientSnapshot.hasError || !patientSnapshot.hasData || patientSnapshot.data!.docs.isEmpty) {
            return Center(child: Text("No patients found."));
          }

          List<String> patientIds = patientSnapshot.data!.docs.map((doc) => doc.id).toList();

          return StreamBuilder(
            stream: conditionsCollection
                .where('patientId', whereIn: patientIds)
                .where('hasPrescription', isEqualTo: false)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> conditionSnapshot) {
              if (conditionSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (conditionSnapshot.hasError || !conditionSnapshot.hasData || conditionSnapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list_alt_sharp,
                        size: 70.0,
                        color: Color(0xFF9E9E9E),
                      ),
                      SizedBox(height: 16.0),
                      Text(
                        "No patient conditions found",
                        style: TextStyle(fontSize: 20.0, color: Color(0xFF9E9E9E)),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: conditionSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final DocumentSnapshot conditionDoc = conditionSnapshot.data!.docs[index];
                  final String patientId = conditionDoc['patientId'];

                  return FutureBuilder<DocumentSnapshot>(
                    future: usersCollection.doc(patientId).get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return _buildConditionCard(
                          patientName: 'Unknown Patient',
                          timestamp: conditionDoc['timestamp'],
                        );
                      }

                      final String firstName = userSnapshot.data!['firstName'] ?? 'Unknown';
                      final String lastName = userSnapshot.data!['lastName'] ?? 'Patient';
                      final String fullName = "$firstName $lastName";

                      return _buildConditionCard(
                        patientName: fullName,
                        timestamp: conditionDoc['timestamp'],
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            "/patient condition details",
                            arguments: conditionDoc,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildConditionCard({
    required String patientName,
    required Timestamp timestamp,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        color: Color(0xFFFFFFFF),
        elevation: 5.0,
        borderRadius: BorderRadius.circular(20.0),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8.0),
                Text(
                  DateFormat('dd.MM.yyyy').format(timestamp.toDate()), // Format updated to DD.MM.YYYY
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 18.0,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
