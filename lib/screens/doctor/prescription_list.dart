import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DoctorPrescriptionsHistoryPage extends StatefulWidget {
  const DoctorPrescriptionsHistoryPage({Key? key}) : super(key: key);

  @override
  _DoctorPrescriptionsHistoryPageState createState() => _DoctorPrescriptionsHistoryPageState();
}

class _DoctorPrescriptionsHistoryPageState extends State<DoctorPrescriptionsHistoryPage> {
  final String? doctorId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF008000),
        title: const Text(
          'My Prescriptions History',
          style: TextStyle(
            fontSize: 23.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
      body: doctorId == null
          ? const Center(child: Text('Error: User not logged in.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('prescriptions')
                  .where('doctorId', isEqualTo: doctorId)
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
                              '/doctor prescriptions',
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
