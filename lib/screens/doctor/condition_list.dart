import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PatientsConditions extends StatefulWidget {
  // Constructor for the widget with an optional key parameter.
  const PatientsConditions({super.key});

  @override
  State<PatientsConditions> createState() => _PatientsConditionsPage();
}

class _PatientsConditionsPage extends State<PatientsConditions> {
  // References to Firestore collections for users and conditions.
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection("users");
  final CollectionReference conditionsCollection =
      FirebaseFirestore.instance.collection("conditions");
  // Retrieves the current user's UID, expected to be the doctor.
  final String? doctorId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar setup with a back button.
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(0xFF176139),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Patients Conditions",
          style: TextStyle(
            fontSize: 23.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
      // StreamBuilder to listen to changes in the user's collection where 'doctorId' matches the current user.
      body: StreamBuilder(
        stream: usersCollection.where('doctorId', isEqualTo: doctorId).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> patientSnapshot) {
          if (patientSnapshot.connectionState == ConnectionState.waiting) {
            // Shows a loading indicator while data is loading.
            return const Center(child: CircularProgressIndicator());
          }

          if (patientSnapshot.hasError || !patientSnapshot.hasData || patientSnapshot.data!.docs.isEmpty) {
            // Displays a message when no patients are found.
            return Center(child: Text("No patients found."));
          }

          // Retrieves a list of patient IDs from the fetched documents.
          List<String> patientIds = patientSnapshot.data!.docs.map((doc) => doc.id).toList();

          return StreamBuilder(
            // StreamBuilder to listen for conditions associated with fetched patient IDs.
            stream: conditionsCollection
                .where('patientId', whereIn: patientIds)
                .where('hasPrescription', isEqualTo: false)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> conditionSnapshot) {
              if (conditionSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (conditionSnapshot.hasError || !conditionSnapshot.hasData || conditionSnapshot.data!.docs.isEmpty) {
                // Displays a message when no conditions are found.
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

              // Sorts the fetched condition documents by timestamp in descending order.
              List<QueryDocumentSnapshot> sortedConditions = conditionSnapshot.data!.docs;
              sortedConditions.sort((a, b) => (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

              return ListView.builder(
                itemCount: sortedConditions.length,
                itemBuilder: (context, index) {
                  final DocumentSnapshot conditionDoc = sortedConditions[index];
                  final String patientId = conditionDoc['patientId'];

                  return FutureBuilder<DocumentSnapshot>(
                    // FutureBuilder to fetch user details for each condition.
                    future: usersCollection.doc(patientId).get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                        // Displays a default card if user details are not found.
                        return _buildConditionCard(
                          patientName: 'Unknown Patient',
                          timestamp: conditionDoc['timestamp'],
                        );
                      }

                      // Constructs full name from first and last names, handling null cases.
                      final String firstName = userSnapshot.data!['firstName'] ?? 'Unknown';
                      final String lastName = userSnapshot.data!['lastName'] ?? 'Patient';
                      final String fullName = "$firstName $lastName";

                      // Returns a condition card with patient details and navigation option.
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

  // Function to create a card widget for each patient condition.
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
                  DateFormat('dd.MM.yyyy').format(timestamp.toDate()), 
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
