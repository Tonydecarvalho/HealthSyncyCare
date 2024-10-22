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
  final String? patientId = FirebaseAuth.instance.currentUser?.uid;
  bool isDurationDescending = true; // To toggle symptom duration sorting
  String searchQuery = ''; // Search query for filtering by symptom

  // Toggle sorting order for symptom durations
  void _toggleDurationSortOrder() {
    setState(() {
      isDurationDescending = !isDurationDescending;
    });
  }

  // Function to handle search input change
  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query.toLowerCase(); // Convert search query to lowercase for case-insensitive search
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF008000),
        title: const Text(
          'Your Conditions',
          style: TextStyle(
            fontSize: 23.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
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
                // Search bar
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search by Symptom',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _onSearchChanged, // Update search query when user types
                  ),
                ),
                const SizedBox(width: 10),
                // Sorting button
                IconButton(
                  onPressed: _toggleDurationSortOrder,
                  icon: Icon(
                    isDurationDescending ? Icons.arrow_downward : Icons.arrow_upward,
                    color: Color(0xFF008000),
                  ),
                  tooltip: isDurationDescending ? 'Sort: Longest First' : 'Sort: Shortest First',
                ),
              ],
            ),
          ),
          Expanded(
            child: patientId == null
                ? const Center(child: Text('Error: User not logged in.'))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('conditions')
                        .where('patientId', isEqualTo: patientId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No conditions found.'),
                        );
                      }

                      var conditions = snapshot.data!.docs;

                      // Fetching symptom data and filtering based on search query
                      return FutureBuilder<List<Map<String, dynamic>>>(
                        future: _getConditionsWithSymptomData(conditions, searchQuery),
                        builder: (context, futureSnapshot) {
                          if (futureSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
                            return const Center(child: Text('No conditions match your search.'));
                          }

                          // Sort conditions by max or min symptom duration
                          var sortedConditions = futureSnapshot.data!;
                          sortedConditions.sort((a, b) {
                            final int durationA = a['maxDuration'] ?? 0;
                            final int durationB = b['maxDuration'] ?? 0;
                            return isDurationDescending
                                ? durationB.compareTo(durationA)
                                : durationA.compareTo(durationB);
                          });

                          return ListView.builder(
                            itemCount: sortedConditions.length,
                            itemBuilder: (context, index) {
                              final condition = sortedConditions[index];
                              final Timestamp timestamp = condition['timestamp'];
                              final String formattedDate =
                                  DateFormat('dd MMMM yyyy').format(timestamp.toDate());
                              final String symptomNames = condition['symptomNames'] ?? 'No symptoms';

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
                                      formattedDate,
                                      style: const TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Symptoms: $symptomNames",
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF008000)),
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/patient condition details patient',
                                        arguments: condition['conditionId'],
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

    for (var condition in conditions) {
      final symptomsSnapshot = await condition.reference.collection('symptoms').get();
      final symptoms = symptomsSnapshot.docs;

      if (symptoms.isNotEmpty) {
        final symptomNames = symptoms.map((symptom) => symptom['description']).join(', ');
        final matchingSymptoms = symptoms
            .where((symptom) =>
                symptom['description'].toString().toLowerCase().contains(searchQuery))
            .toList();
        final maxDuration = symptoms.map((symptom) => symptom['duration']).reduce((a, b) => a > b ? a : b);

        // If the condition has at least one symptom matching the search query, include it
        if (searchQuery.isEmpty || matchingSymptoms.isNotEmpty) {
          conditionData.add({
            'conditionId': condition.id,
            'timestamp': condition['timestamp'],
            'symptomNames': symptomNames,
            'maxDuration': maxDuration,
          });
        }
      } else {
        // If no symptoms are present, include the condition only if there's no search query
        if (searchQuery.isEmpty) {
          conditionData.add({
            'conditionId': condition.id,
            'timestamp': condition['timestamp'],
            'symptomNames': 'No symptoms',
            'maxDuration': 0,
          });
        }
      }
    }

    return conditionData;
  }
}
