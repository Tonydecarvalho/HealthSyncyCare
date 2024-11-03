import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PatientsConditionsPatient extends StatefulWidget {
  const PatientsConditionsPatient({super.key});

  @override
  State<PatientsConditionsPatient> createState() =>
      _PatientsConditionsPatientState();
}

class _PatientsConditionsPatientState extends State<PatientsConditionsPatient> {
  // Retrieve the current patient's ID from Firebase Authentication
  final String? patientId = FirebaseAuth.instance.currentUser?.uid;

  // To toggle the sort order of the conditions by date (newest to oldest or vice versa)
  bool isDateDescending = true;

  // To store the user's search query for filtering conditions by symptoms
  String searchQuery = '';

  // This function toggles the sorting order when the user clicks the sorting button
  void _toggleDateSortOrder() {
    setState(() {
      isDateDescending = !isDateDescending; // Switch between ascending and descending order
    });
  }

  // This function updates the search query when the user types in the search bar
  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query.toLowerCase(); // Convert to lowercase for case-insensitive searching
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Header of the page
        centerTitle: true,
        backgroundColor: const Color(0xFF176139), // Green color for the app bar
        title: const Text(
          'Your Conditions',
          style: TextStyle(
            fontSize: 23.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF), // White text
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar and sorting button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [
                // TextField widget to input search queries
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search by Symptom',
                      border: OutlineInputBorder(), // Box around the search input
                      prefixIcon: const Icon(Icons.search), // Search icon
                    ),
                    onChanged: _onSearchChanged, // Call this function when the user types
                  ),
                ),
                const SizedBox(width: 10),
                // Button to toggle sorting by date
                IconButton(
                  onPressed: _toggleDateSortOrder, // Call function when clicked
                  icon: Icon(
                    isDateDescending ? Icons.arrow_downward : Icons.arrow_upward, // Change icon based on order
                    color: const Color(0xFF176139), // Green color
                  ),
                  tooltip: isDateDescending ? 'Sort: Newest First' : 'Sort: Oldest First', // Tooltip
                ),
              ],
            ),
          ),
          // Body content that displays the patient's conditions
          Expanded(
            child: patientId == null
                ? const Center(child: Text('Error: User not logged in.')) // Error if no user is logged in
                : StreamBuilder<QuerySnapshot>(
                    // Stream to listen to changes in the 'conditions' collection in Firestore
                    stream: FirebaseFirestore.instance
                        .collection('conditions')
                        .where('patientId', isEqualTo: patientId) // Filter conditions by patient ID
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator()); // Show loading indicator
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No conditions found.'), // Show message if no conditions found
                        );
                      }

                      var conditions = snapshot.data!.docs; // Get the list of conditions

                      // FutureBuilder to fetch and display conditions with symptoms
                      return FutureBuilder<List<Map<String, dynamic>>>(
                        future: _getConditionsWithSymptomData(conditions, searchQuery), // Fetch conditions
                        builder: (context, futureSnapshot) {
                          if (futureSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator()); // Show loading indicator
                          }

                          if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
                            return const Center(child: Text('No conditions match your search.')); // No matching conditions
                          }

                          // Sort the conditions by timestamp (date added)
                          var sortedConditions = futureSnapshot.data!;
                          sortedConditions.sort((a, b) {
                            final Timestamp dateA = a['timestamp'];
                            final Timestamp dateB = b['timestamp'];
                            return isDateDescending
                                ? dateB.compareTo(dateA) // Sort by date (newest to oldest)
                                : dateA.compareTo(dateB); // Sort by date (oldest to newest)
                          });

                          // Display the sorted conditions in a ListView
                          return ListView.builder(
                            itemCount: sortedConditions.length,
                            itemBuilder: (context, index) {
                              final condition = sortedConditions[index];
                              final Timestamp timestamp = condition['timestamp'];
                              final String formattedDate =
                                  DateFormat('dd MMMM yyyy').format(timestamp.toDate()); // Format the date
                              final String symptomNames = condition['symptomNames'] ?? 'No symptoms'; // Get symptom names

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0), // Rounded corners for cards
                                  ),
                                  elevation: 5.0, // Add shadow effect
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(20.0),
                                    title: Text(
                                      formattedDate, // Display the date of the condition
                                      style: const TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87, // Black text color
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Symptoms: $symptomNames", // Display the symptoms
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF176139)), // Right arrow icon
                                    onTap: () {
                                      // Navigate to the patient condition details page when tapped
                                      Navigator.pushNamed(
                                        context,
                                        '/patient condition details patient',
                                        arguments: condition['conditionId'], // Pass the condition ID as an argument
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

  // Fetch symptom data for each condition, filter by search query, and return as a list of maps
  Future<List<Map<String, dynamic>>> _getConditionsWithSymptomData(
      List<QueryDocumentSnapshot> conditions, String searchQuery) async {
    List<Map<String, dynamic>> conditionData = [];

    // Iterate through each condition to fetch the symptoms
    for (var condition in conditions) {
      final symptomsSnapshot = await condition.reference.collection('symptoms').get(); // Get symptoms subcollection
      final symptoms = symptomsSnapshot.docs;

      if (symptoms.isNotEmpty) {
        // Collect the names of the symptoms
        final symptomNames = symptoms.map((symptom) => symptom['description']).join(', ');

        // Filter conditions based on the search query
        final matchingSymptoms = symptoms
            .where((symptom) =>
                symptom['description'].toString().toLowerCase().contains(searchQuery)) // Case-insensitive search
            .toList();

        // If the search query is empty or there are matching symptoms, add the condition
        if (searchQuery.isEmpty || matchingSymptoms.isNotEmpty) {
          conditionData.add({
            'conditionId': condition.id, // Store the condition ID
            'timestamp': condition['timestamp'], // Store the date of the condition
            'symptomNames': symptomNames, // Store the symptom names
          });
        }
      } else {
        // If no symptoms, include the condition only if there's no search query
        if (searchQuery.isEmpty) {
          conditionData.add({
            'conditionId': condition.id, // Store the condition ID
            'timestamp': condition['timestamp'], // Store the date of the condition
            'symptomNames': 'No symptoms', // No symptoms recorded
          });
        }
      }
    }

    return conditionData; // Return the list of conditions with their data
  }
}
