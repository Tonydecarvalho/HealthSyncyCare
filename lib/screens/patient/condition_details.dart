import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PatientConditionDetailsPatient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Retrieve the condition ID passed from the previous page to query Firestore.
    final String conditionId = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true, // Centers the title within the app bar.
        backgroundColor: const Color(0xFF176139), // Sets the background color of the AppBar.
        leading: IconButton( // Defines a back button for navigation.
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(), // Pops the current route off the navigation stack.
        ),
        title: const Text(
          'Condition Details',
          style: TextStyle(
            fontSize: 23.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('conditions')
            .doc(conditionId)
            .get(), // Fetches the condition details from Firestore using the condition ID.
        builder: (context, conditionSnapshot) {
          if (conditionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Displays a loading spinner while data is fetched.
          }
          if (conditionSnapshot.hasError || !conditionSnapshot.hasData) {
            return const Center(child: Text('Failed to load condition details.')); // Shows an error if data fails to load.
          }
          
          final conditionData = conditionSnapshot.data!; // Accesses the data retrieved from Firestore.
          final Timestamp timestamp = conditionData['timestamp']; // Retrieves the timestamp of the condition.
          final String formattedDate = DateFormat('dd.MM.yyyy - kk:mm').format(timestamp.toDate()); // Formats the timestamp into a readable date.

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20.0),
                const Text(
                  "Symptoms",
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10.0),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('conditions')
                        .doc(conditionId)
                        .collection('symptoms')
                        .snapshots(), // Streams symptom data related to the condition.
                    builder: (context, symptomSnapshot) {
                      if (symptomSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator()); // Displays a spinner while symptom data is loading.
                      }
                      if (symptomSnapshot.hasError || !symptomSnapshot.hasData) {
                        return const Text('No symptoms found.'); // Shows a message if no symptoms are found.
                      }

                      final symptoms = symptomSnapshot.data!.docs; // Accesses the list of symptoms.
                      return ListView.builder(
                        itemCount: symptoms.length,
                        itemBuilder: (context, index) {
                          final symptom = symptoms[index]; // Retrieves individual symptom data.
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      symptom['description'], // Displays the description of the symptom.
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 5.0),
                                    Text(
                                      "Duration: ${symptom['duration']} days", // Displays the duration of the symptom.
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
