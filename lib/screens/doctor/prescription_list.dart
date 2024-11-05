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
  final String? doctorId = FirebaseAuth.instance.currentUser?.uid; // Retrieve the current doctor's UID for querying their patients.
  Map<String, bool> expandedPatients = {}; // Used to track the expansion state of each patient's detail view.
  bool isNameAscending = true; // Controls the sorting order of patient names.
  bool isDateDescending = true; // Controls the sorting order of prescription dates.
  String searchQuery = ''; // Stores the current search term entered by the user.

  @override
  void initState() {
    super.initState();
    _fetchPatientsWithPrescriptions(); // Fetch initial list of patients with prescriptions on widget load.
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
            expandedPatients[doc.id] = false; // Initializes each patient's expanded state to false (collapsed).
          });
        }
      }
    }
  }

  void _toggleExpand(String patientId) {
    setState(() {
      expandedPatients[patientId] = !(expandedPatients[patientId] ?? false); // Toggles the expansion state of a patient's detail view.
    });
  }

  // Toggle sorting order for patient names
  void _toggleNameSortOrder() {
    setState(() {
      isNameAscending = !isNameAscending; // Toggles the name sorting order between ascending and descending.
    });
  }

  // Toggle sorting order for prescription dates
  void _toggleDateSortOrder() {
    setState(() {
      isDateDescending = !isDateDescending; // Toggles the date sorting order between descending and ascending.
    });
  }

  // Function to handle search input change
  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query.toLowerCase(); // Updates the search query to filter the displayed patient list.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF176139),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(), // Allows navigation back to the previous screen.
        ),
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
                    onChanged: _onSearchChanged, // Handles search input changes.
                  ),
                ),
                const SizedBox(width: 10),
                // Sorting buttons next to the search bar
                IconButton(
                  onPressed: _toggleNameSortOrder,
                  icon: Icon(
                    isNameAscending ? Icons.sort_by_alpha : Icons.sort_by_alpha_outlined,
                    color: Color(0xFF176139),
                  ),
                  tooltip: isNameAscending ? 'Sort: A-Z' : 'Sort: Z-A', // Provides a tooltip based on the current sort order.
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _toggleDateSortOrder,
                  icon: Icon(
                    isDateDescending ? Icons.arrow_downward : Icons.arrow_upward,
                    color: Color(0xFF176139),
                  ),
                  tooltip: isDateDescending ? 'Sort: Newest First' : 'Sort: Oldest First', // Provides a tooltip based on the current date sort order.
                ),
              ],
            ),
          ),
          Expanded(
            child: doctorId == null
                ? const Center(child: Text('Error: User not logged in.')) // Error handling if no doctor is logged in.
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('doctorId', isEqualTo: doctorId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator()); // Shows a loading indicator while data is loading.
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No patients found.')); // Displays a message if no patients are found.
                      }

                      var patients = snapshot.data!.docs;

                      // Filters patients based on the search query.
                      patients = patients.where((patient) {
                        final fullName = "${patient['lastName']} ${patient['firstName']}".toLowerCase();
                        return fullName.contains(searchQuery);
                      }).toList();

                      // Sorts patients based on the current sorting criteria.
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
                          );
                          final String patientId = patientData.id;
                          final bool isExpanded = expandedPatients[patientId] ?? false; // Retrieves the expansion state for each patient.

                          return Column(
                            children: [
                              ListTile(
                                title: Text(
                                  fullName,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text("Date of Birth: $dateOfBirth"),
                                trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                                onTap: () => _toggleExpand(patientId), // Handles expanding or collapsing the detail view.
                              ),
                              if (isExpanded) // Conditionally renders the prescriptions if the detail view is expanded.
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

                                    // Sorts prescriptions by date based on the current sorting criteria.
                                    prescriptions.sort((a, b) {
                                      final dateA = (a['createdAt'] as Timestamp).toDate();
                                      final dateB = (b['createdAt'] as Timestamp).toDate();
                                      return isDateDescending ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
                                    });

                                    return ListView.builder(
                                      physics: NeverScrollableScrollPhysics(), // Prevents the inner list from scrolling independently.
                                      shrinkWrap: true, // Allows the inner list to size itself to its children.
                                      itemCount: prescriptions.length,
                                      itemBuilder: (context, index) {
                                        final prescriptionData = prescriptions[index];
                                        final Timestamp timestamp = prescriptionData['createdAt'];
                                        final String formattedDate = DateFormat('dd.MM.yyyy').format(timestamp.toDate());

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
                                                  return Text("${drug['drug']} - Quantity: ${drug['quantity']}"); // Lists each drug and its quantity.
                                                }).toList(),
                                              );
                                            },
                                          ),
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/doctor prescriptions',
                                              arguments: prescriptionData.id, // Navigates to a detailed prescription page when tapped.
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              Divider(), // Adds a visual separator.
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
