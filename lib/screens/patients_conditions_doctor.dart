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
                color: Color(0xFFFFFFFF)),
          )),
      body: StreamBuilder(
          stream: patientsConditions.snapshots(),
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
                      style:
                          TextStyle(fontSize: 20.0, color: Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                    streamSnapshot.data!.docs[index];
                return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Material(
                      color: Color(0xFFFFFFFF),
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(20.0),
                      child: InkWell(
                        onTap: () {
                          final DocumentSnapshot selectedCondition =
                              streamSnapshot.data!.docs[index];
                          Navigator.pushNamed(
                            context,
                            "/patient condition details",
                            arguments: selectedCondition,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Text(
                              DateFormat('yyyy.MM.dd').format(
                                (documentSnapshot['timestamp'] as Timestamp)
                                    .toDate(),
                              ),
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 20.0),
                            ),
                            subtitle: Text(documentSnapshot['description']),
                          ),
                        ),
                      ),
                    ));
              },
            );
          }),
    );
  }
}
