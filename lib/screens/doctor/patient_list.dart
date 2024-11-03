import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthsyncycare/screens/doctor/patient_details.dart';


class DoctorPatientListPage extends StatefulWidget {
  @override
  _DoctorPatientListPageState createState() => _DoctorPatientListPageState();
}

class _DoctorPatientListPageState extends State<DoctorPatientListPage> {
  final String? doctorId = FirebaseAuth.instance.currentUser?.uid;
  String searchQuery = ''; 
  bool isNameAscending = true; 

  // Function to handle search input change
  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  // Toggle sorting order for patient names
  void _toggleNameSortOrder() {
    setState(() {
      isNameAscending = !isNameAscending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients List', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton( // Back button
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: const Color(0xFF176139),
      ),
      body: Column(
        children: [
          // Search bar with sorting button
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _toggleNameSortOrder,
                  icon: Icon(
                    isNameAscending
                        ? Icons.sort_by_alpha
                        : Icons.sort_by_alpha_outlined,
                    color: const Color(0xFF176139),
                  ),
                  tooltip: isNameAscending ? 'Sort: A-Z' : 'Sort: Z-A',
                ),
              ],
            ),
          ),
          Expanded(
            child: doctorId == null
                ? const Center(child: Text('Error: User not logged in.'))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('doctorId', isEqualTo: doctorId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No patients found.'));
                      }

                      var patients = snapshot.data!.docs;

                      // Filter patients by search query
                      patients = patients.where((patient) {
                        final fullName =
                            "${patient['lastName']} ${patient['firstName']}"
                                .toLowerCase();
                        return fullName.contains(searchQuery);
                      }).toList();

                      // Sort patients by name
                      patients.sort((a, b) {
                        final nameA =
                            "${a['lastName']} ${a['firstName']}".toLowerCase();
                        final nameB =
                            "${b['lastName']} ${b['firstName']}".toLowerCase();
                        return isNameAscending
                            ? nameA.compareTo(nameB)
                            : nameB.compareTo(nameA);
                      });

                      return ListView.builder(
                        itemCount: patients.length,
                        itemBuilder: (context, index) {
                          final patient = patients[index];
                          final String fullName =
                              "${patient['lastName']} ${patient['firstName']}";
                          final String patientId = patient.id;

                          return ListTile(
                            title: Text(
                              fullName,
                              style: const TextStyle(fontSize: 18.0),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PatientDetailsPage(
                                      patientId: patientId),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
