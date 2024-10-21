import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DoctorPrescriptionsHistoryPage extends StatefulWidget {
  const DoctorPrescriptionsHistoryPage({Key? key}) : super(key: key);

  @override
  _DoctorPrescriptionsHistoryPageState createState() =>
      _DoctorPrescriptionsHistoryPageState();
}

class _DoctorPrescriptionsHistoryPageState
    extends State<DoctorPrescriptionsHistoryPage> {
  final String? doctorId = FirebaseAuth.instance.currentUser?.uid;
  Map<String, bool> expandedPatients = {}; // Track expanded state for each patient
  bool isNameAscending = true; // To toggle patient name sorting
  bool isDateDescending = true; // To toggle prescription date sorting
  String searchQuery = ''; // For filtering patients by search query

  @override
  void initState() {
    super.initState();
    _fetchPatientsWithPrescriptions();
  }

  Future<void> _fetchPatientsWithPrescriptions() async {
    if (doctorId != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      // We need to check which patients have prescriptions
      for (var doc in querySnapshot.docs) {
        final patientId = doc.id;
        final prescriptionsQuery = await FirebaseFirestore.instance
            .collection('prescriptions')
            .where('patientId', isEqualTo: patientId)
            .get();

        // Only keep patients with at least one prescription
        if (prescriptionsQuery.docs.isNotEmpty) {
          setState(() {
            expandedPatients[doc.id] = false; // Initialize collapsed state
          });
        }
      }
    }
  }

  void _toggleExpand(String patientId) {
    setState(() {
      expandedPatients[patientId] = !(expandedPatients[patientId] ?? false);
    });
  }

  // Toggle sorting order for patient names
  void _toggleNameSortOrder() {
    setState(() {
      isNameAscending = !isNameAscending;
    });
  }

  // Toggle sorting order for prescription dates
  void _toggleDateSortOrder() {
    setState(() {
      isDateDescending = !isDateDescending;
    });
  }

  // Function to handle search input change
  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF008000),
        title: const Text(
          'Patients & Prescriptions',
          style: TextStyle(
            fontSize: 23.0,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar with sorting buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [
                // Search bar
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search Patient by Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _onSearchChanged, // Update search query when user types
                  ),
                ),
                const SizedBox(width: 10),
                // Sorting buttons next to the search bar
                IconButton(
                  onPressed: _toggleNameSortOrder,
                  icon: Icon(
                    isNameAscending ? Icons.sort_by_alpha : Icons.sort_by_alpha_outlined,
                    color: Color(0xFF008000),
                  ),
                  tooltip: isNameAscending ? 'Sort: A-Z' : 'Sort: Z-A',
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _toggleDateSortOrder,
                  icon: Icon(
                    isDateDescending ? Icons.arrow_downward : Icons.arrow_upward,
                    color: Color(0xFF008000),
                  ),
                  tooltip: isDateDescending ? 'Sort: Newest First' : 'Sort: Oldest First',
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
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No patients found.'));
                      }

                      var patients = snapshot.data!.docs;

                      // Filter patients by search query
                      patients = patients.where((patient) {
                        final fullName = "${patient['lastName']} ${patient['firstName']}".toLowerCase();
                        return fullName.contains(searchQuery);
                      }).toList();

                      // Sort patients by name
                      patients.sort((a, b) {
                        final nameA = "${a['lastName']} ${a['firstName']}".toLowerCase();
                        final nameB = "${b['lastName']} ${b['firstName']}".toLowerCase();
                        return isNameAscending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
                      });

                      return ListView.builder(
                        itemCount: patients.length,
                        itemBuilder: (context, index) {
                          final patientData = patients[index];
                          final String fullName = "${patientData['lastName']} ${patientData['firstName']}";
                          final String dateOfBirth = DateFormat('dd MMMM yyyy').format(
                            DateTime.parse(patientData['dateOfBirth']),
                          ); // Changed format to dd MMMM yyyy
                          final String patientId = patientData.id;
                          final bool isExpanded = expandedPatients[patientId] ?? false;

                          return Column(
                            children: [
                              ListTile(
                                title: Text(
                                  fullName,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text("Date of Birth: $dateOfBirth"),
                                trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                                onTap: () => _toggleExpand(patientId),
                              ),
                              if (isExpanded)
                                StreamBuilder<QuerySnapshot>(
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

                                    var prescriptions = snapshot.data!.docs;

                                    // Sort prescriptions by date
                                    prescriptions.sort((a, b) {
                                      final dateA = (a['createdAt'] as Timestamp).toDate();
                                      final dateB = (b['createdAt'] as Timestamp).toDate();
                                      return isDateDescending ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
                                    });

                                    return ListView.builder(
                                      physics: NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: prescriptions.length,
                                      itemBuilder: (context, index) {
                                        final prescriptionData = prescriptions[index];
                                        final Timestamp timestamp = prescriptionData['createdAt'];
                                        final String formattedDate = DateFormat('dd.MM.yyyy').format(timestamp.toDate()); // Changed format to dd.MM.yyyy

                                        return ListTile(
                                          title: Text("Prescription Date: $formattedDate"),
                                          subtitle: StreamBuilder<QuerySnapshot>(
                                            stream: prescriptionData.reference.collection('drug').snapshots(),
                                            builder: (context, drugSnapshot) {
                                              if (!drugSnapshot.hasData || drugSnapshot.data!.docs.isEmpty) {
                                                return Text('No drugs found.');
                                              }

                                              final drugs = drugSnapshot.data!.docs;
                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: drugs.map((drug) {
                                                  return Text("${drug['drug']} - Quantity: ${drug['quantity']}");
                                                }).toList(),
                                              );
                                            },
                                          ),
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/doctor prescriptions',
                                              arguments: prescriptionData.id,
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              Divider(),
                            ],
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
