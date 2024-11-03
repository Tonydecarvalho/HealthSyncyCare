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
  String searchQuery = ''; // Search query to filter prescriptions by drug name
  bool isDateDescending = true; // To toggle prescription date sorting

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
        backgroundColor: const Color(0xFF176139),
        leading: IconButton( // Back button
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Prescriptions',
          style: TextStyle(
            fontSize: 23.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar with sorting button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [
                // Search bar
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search by Medication Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _onSearchChanged, // Update search query when user types
                  ),
                ),
                const SizedBox(width: 10),
                // Sorting button
                IconButton(
                  onPressed: _toggleDateSortOrder,
                  icon: Icon(
                    isDateDescending ? Icons.arrow_downward : Icons.arrow_upward,
                    color: Color(0xFF176139),
                  ),
                  tooltip: isDateDescending ? 'Sort: Newest First' : 'Sort: Oldest First',
                ),
              ],
            ),
          ),
          Expanded(
            child: patientId == null
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

                      // Copy prescriptions to a local list and sort them by date locally
                      List<DocumentSnapshot> prescriptions = snapshot.data!.docs;

                      // Sort prescriptions by 'createdAt' locally
                      prescriptions.sort((a, b) {
                        Timestamp aTimestamp = a['createdAt'];
                        Timestamp bTimestamp = b['createdAt'];
                        return isDateDescending
                            ? bTimestamp.compareTo(aTimestamp)
                            : aTimestamp.compareTo(bTimestamp);
                      });

                      return ListView.builder(
                        itemCount: prescriptions.length,
                        itemBuilder: (context, index) {
                          final prescription = prescriptions[index];
                          final Timestamp timestamp = prescription['createdAt'];
                          final String formattedDate = DateFormat('dd MMMM yyyy').format(timestamp.toDate());

                          // Stream for fetching the drug names for filtering and displaying
                          return StreamBuilder<QuerySnapshot>(
                            stream: prescription.reference.collection('drug').snapshots(),
                            builder: (context, drugSnapshot) {
                              if (!drugSnapshot.hasData || drugSnapshot.data!.docs.isEmpty) {
                                return SizedBox.shrink(); // If no drug, skip this prescription
                              }

                              final drugs = drugSnapshot.data!.docs;
                              final drugNames = drugs.map((drug) => drug['drug'].toLowerCase()).join(', ');

                              // Check if the drug names contain the search query
                              if (searchQuery.isNotEmpty && !drugNames.contains(searchQuery)) {
                                return SizedBox.shrink(); // Skip if drug name doesn't match search query
                              }

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
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: drugs.map((drug) {
                                        return Text("${drug['drug']} - Quantity: ${drug['quantity']}");
                                      }).toList(),
                                    ),
                                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF176139)),
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
