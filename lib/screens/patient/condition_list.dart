import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PatientsConditionsPatient extends StatefulWidget {
  const PatientsConditionsPatient({super.key});

  @override
  State<PatientsConditionsPatient> createState() => _PatientsConditionsPatientState();
}

class _PatientsConditionsPatientState extends State<PatientsConditionsPatient> {
  final CollectionReference patientsConditions =
      FirebaseFirestore.instance.collection("conditions");
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(0xFF008000),
        title: Text(
          "Your Conditions",
          style: TextStyle(
              fontSize: 23.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFFFFF)),
        ),
      ),
      body: currentUser == null
          ? Center(child: Text("No user logged in"))
          : StreamBuilder(
              stream: patientsConditions
                  .where('patientId', isEqualTo: currentUser!.uid)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                if (streamSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (streamSnapshot.hasError) {
                  return Center(child: Text("Something went wrong"));
                }

                if (!streamSnapshot.hasData || streamSnapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 70.0,
                          color: Color(0xFF9E9E9E),
                        ),
                        SizedBox(height: 16.0),
                        Text(
                          "No shared conditions found",
                          style: TextStyle(fontSize: 20.0, color: Color(0xFF9E9E9E)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: streamSnapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final DocumentSnapshot conditionSnapshot = streamSnapshot.data!.docs[index];
                    return _buildConditionCard(
                      timestamp: conditionSnapshot['timestamp'],
                      conditionId: conditionSnapshot.id,
                    );
                  },
                );
              }),
    );
  }

  Widget _buildConditionCard({
    required Timestamp timestamp,
    required String conditionId,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        color: Color(0xFFFFFFFF),
        elevation: 5.0,
        borderRadius: BorderRadius.circular(20.0),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              "/patient condition details patient",
              arguments: conditionId,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('yyyy.MM.dd').format(timestamp.toDate()),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8.0),
                Text(
                  "View details",
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
