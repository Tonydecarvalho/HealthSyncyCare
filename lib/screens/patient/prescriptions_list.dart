import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PatientPrescriptionsPage extends StatefulWidget {
  const PatientPrescriptionsPage({Key? key}) : super(key: key);

  @override
  _PatientPrescriptionsPageState createState() => _PatientPrescriptionsPageState();
}

class _PatientPrescriptionsPageState extends State<PatientPrescriptionsPage> {
  final String? patientId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF008000),
        title: const Text(
          'My Prescriptions',
          style: TextStyle(
            fontSize: 23.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
      body: patientId == null
          ? const Center(child: Text('Error: User not logged in.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('prescriptions')
                  .where('patientId', isEqualTo: patientId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No prescriptions found.'),
                  );
                }

                final prescriptions = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: prescriptions.length,
                  itemBuilder: (context, index) {
                    final prescription = prescriptions[index];
                    final Timestamp timestamp = prescription['createdAt'];
                    final String formattedDate = DateFormat('yyyy.MM.dd').format(timestamp.toDate());

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 5.0,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(20.0),
                          title: Text(
                            "Date: $formattedDate",
                            style: const TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Color(0xFF008000)),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/prescriptions details',
                              arguments: prescription.id,
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
