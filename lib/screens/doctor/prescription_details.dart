import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Allows using platform services like copying data to clipboard.

class DoctorPrescriptionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Retrieve the prescription ID passed from the previous page.
    final String prescriptionId =
        ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true, // Aligns the title text to the center of the app bar.
        backgroundColor: Color(0xFF176139), // Sets a green color for the app bar.
        leading: IconButton( // Defines a back button in the AppBar.
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(), // Pops the current page off the navigation stack.
        ),
        title: const Text(
          'Prescription Details',
          style: TextStyle(
            fontSize: 23.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('prescriptions')
            .doc(prescriptionId)
            .get(), // Fetches the prescription details from Firestore.
        builder: (context, prescriptionSnapshot) {
          if (prescriptionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Displays a loading indicator until data is fetched.
          }
          if (prescriptionSnapshot.hasError || !prescriptionSnapshot.hasData) {
            return const Center(
                child: Text('Failed to load prescription details.')); // Error handling if data fetch fails.
          }

          final prescriptionData = prescriptionSnapshot.data!;
          final Timestamp timestamp = prescriptionData['createdAt'];
          final String formattedDate =
              DateFormat('dd.MM.yyyy').format(timestamp.toDate()); // Formats the creation date of the prescription.

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Prescription Document",
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Divider(thickness: 2.0),
                const SizedBox(height: 20.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Date: $formattedDate", // Displays the formatted date of the prescription.
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),

                // Prescription Items
                const Text(
                  "Prescribed Drugs:",
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10.0),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('prescriptions')
                        .doc(prescriptionId)
                        .collection('drug')
                        .snapshots(), // Streams data of drugs in the prescription.
                    builder: (context, drugSnapshot) {
                      if (drugSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (drugSnapshot.hasError || !drugSnapshot.hasData) {
                        return const Text('No drugs found.'); // Error handling if no drugs data is found.
                      }

                      final drugs = drugSnapshot.data!.docs;
                      return ListView.builder(
                        itemCount: drugs.length,
                        itemBuilder: (context, index) {
                          final drug = drugs[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Icon(Icons.circle,
                                    size: 10, color: Colors.black54),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        drug['drug'], // Displays drug name.
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        "Quantity: ${drug['quantity']}", // Displays the quantity of the drug.
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        "Notice: ${drug['notice']}", // Displays any special notices associated with the drug.
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
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20.0),

                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Printing in Progress"),
                            content:
                                Text("Your prescription is being printed..."), // Simulates a printing process.
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Closes the dialog.
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/doctor', // Navigates back to the doctor's main page.
                                    (Route<dynamic> route) => false,
                                  );
                                },
                                child: Text("OK"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.print, color: Colors.white), // Print icon.
                    label: Text(
                      "Print Prescription", // Button text.
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF176139),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
}
