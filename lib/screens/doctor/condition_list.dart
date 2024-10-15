import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PatientsConditions extends StatefulWidget {
  const PatientsConditions({super.key});

  @override
  State<PatientsConditions> createState() => _PatientsConditionsPage();
}

class _PatientsConditionsPage extends State<PatientsConditions> {
  final CollectionReference patientsConditions =
      FirebaseFirestore.instance.collection("conditions");

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
        stream: patientsConditions
            .where('hasPrescription', isEqualTo: false) 
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
            itemCount: streamSnapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final DocumentSnapshot conditionSnapshot = streamSnapshot.data!.docs[index];
              final patientId = conditionSnapshot['patientId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(patientId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return _buildConditionCard(
                      patientName: 'Unknown Patient',
                      timestamp: conditionSnapshot['timestamp'],
                    );
                  }

                  final userName = userSnapshot.data!['name'] ?? 'Unknown Patient';

                  return _buildConditionCard(
                    patientName: userName,
                    timestamp: conditionSnapshot['timestamp'],
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        "/patient condition details",
                        arguments: conditionSnapshot,
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
                  DateFormat('yyyy.MM.dd').format(timestamp.toDate()),
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
