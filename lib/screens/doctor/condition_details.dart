import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PatientConditionDetails extends StatelessWidget {
  // This stateless widget displays the details of a patient's condition.
  
  @override
  Widget build(BuildContext context) {
    // Retrieves the patient condition data passed through the navigator.
    final DocumentSnapshot conditionData =
        ModalRoute.of(context)!.settings.arguments as DocumentSnapshot;

    // Extracts various pieces of data from the conditionData document.
    final String patientId = conditionData['patientId'];
    final String conditionId = conditionData.id;
    final Timestamp timestamp = conditionData['timestamp'];
    // Formats the timestamp into a readable date and time string.
    final String formattedDate =
        DateFormat('dd MMMM yyyy - HH:mm').format(timestamp.toDate());

    return Scaffold(
      // Sets up the AppBar for the UI with a title and a back button.
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF176139),
        leading: IconButton( // Adds a back button to return to the previous screen.
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Patient Condition Details',
          style: TextStyle(
            fontSize: 23.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // Asynchronously fetches patient data from Firestore.
        future: FirebaseFirestore.instance.collection('users').doc(patientId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Shows a loading spinner if the data is still being fetched.
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            // Displays a message if no data is found.
            return Center(child: Text("Patient not found"));
          }

          // If data is successfully fetched, extract the fields from it.
          final userData = snapshot.data!;
          final String fullName = '${userData['firstName']} ${userData['lastName']}';
          final String address = '${userData['address']}, ${userData['city']}, ${userData['postalCode']}, ${userData['country']}';
          final String phone = userData['phone'] ?? 'N/A';
          final String email = userData['email'];
          final String gender = userData['gender'] ?? 'N/A';
          final String dateOfBirth = DateFormat('dd MMMM yyyy').format(DateTime.parse(userData['dateOfBirth']));

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Displays patient full name, DOB, condition date, and contact details centered at the top of the screen.
                Center(
                  child: Column(
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 28.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF176139),
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'Date of Birth: $dateOfBirth',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'Phone: $phone',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'Email: $email',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'Gender: $gender',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'Address: $address',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.0),
                const Divider(thickness: 2.0),

                // Symptom Section: Displays symptoms using a dynamic list if present.
                const Text(
                  "Symptoms",
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF176139),
                  ),
                ),
                SizedBox(height: 16.0),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    // Streams data for symptoms associated with the condition.
                    stream: conditionData.reference.collection('symptoms').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text("No symptoms recorded."));
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final symptomData = snapshot.data!.docs[index];
                          final String description = symptomData['description'];
                          final int duration = symptomData['duration'];
                          return buildSymptomCard(description, duration);
                        },
                      );
                    },
                  ),
                ),

                // Provides a button to navigate to a screen to create a prescription.
                SizedBox(height: 20.0),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/create prescription',
                        arguments: {
                          'patientId': patientId,
                          'conditionId': conditionId,
                        },
                      );
                    },
                    backgroundColor: const Color(0xFF176139),
                    icon: const Icon(
                      Icons.local_pharmacy,
                      size: 30.0,
                      color: Color(0XFFFFFFFF),
                    ),
                    label: const Text(
                      'Prescription',
                      style: TextStyle(fontSize: 18.0, color: Color(0xFFFFFFFF)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper function to build a card for each symptom.
  Widget buildSymptomCard(String description, int duration) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.local_hospital,
              color: Color(0xFF176139),
              size: 40.0,
            ),
            SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    '$duration days',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
