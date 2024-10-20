import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class PrescriptionDetailsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String prescriptionId =
        ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(0xFF008000),
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
            .get(),
        builder: (context, prescriptionSnapshot) {
          if (prescriptionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prescriptionSnapshot.hasError || !prescriptionSnapshot.hasData) {
            return const Center(
                child: Text('Failed to load prescription details.'));
          }

          final prescriptionData = prescriptionSnapshot.data!;
          final Timestamp timestamp = prescriptionData['createdAt'];
          final String formattedDate =
              DateFormat('dd.MM.yyyy').format(timestamp.toDate()); // Date format updated

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Document Header
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

                // Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Date: $formattedDate",
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
                        .snapshots(),
                    builder: (context, drugSnapshot) {
                      if (drugSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (drugSnapshot.hasError || !drugSnapshot.hasData) {
                        return const Text('No drugs found.');
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
                                        drug['drug'],
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        "Quantity: ${drug['quantity']}",
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        "Notice: ${drug['notice']}",
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
                      // Afficher le dialogue de "simulation d'impression"
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Printing in Progress"),
                            content:
                                Text("Your prescription is being printed..."),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  // Fermer le dialogue et rediriger vers la page d'accueil
                                  Navigator.of(context)
                                      .pop(); // Fermer le dialogue
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/home', // Remplacez par votre route d'accueil
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
                    icon: Icon(Icons.print, color: Colors.white),
                    label: Text(
                      "Print Prescription",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF008000),
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
