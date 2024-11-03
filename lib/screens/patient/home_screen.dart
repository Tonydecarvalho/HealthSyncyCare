import 'package:flutter/material.dart'; // Flutter package for UI elements
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore package for database operations
import 'package:firebase_auth/firebase_auth.dart'; // Firebase package for user authentication
import 'package:intl/intl.dart'; // Package for formatting dates

import '../../email_service.dart'; // Custom email service for sending reminders

/// Home page widget that displays user information and upcoming appointments.
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Variables to store the user's name and the text for the next appointment
  String userName = '';
  String nextAppointmentText = 'No upcoming appointment';

  @override
  void initState() {
    super.initState();
    _getUserName(); // Fetch the user's name when the widget is initialized
    _getNextAppointment(); // Fetch the user's next appointment when the widget is initialized
    checkAndSendReminders(); // Check for reminders when the widget is initialized
  }

  /// Called when the widget is updated. Used to check and send reminders again.
  @override
  void didUpdateWidget(covariant MyHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    checkAndSendReminders();
  }

  /// Fetches the user's name from Firestore and updates the state.
  Future<void> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user != null) {
      final userId = user.uid; // Get the user's ID
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(); // Fetch the user's document from Firestore

      if (userDoc.exists) {
        setState(() {
          userName = userDoc.data()?['firstName'] ?? ''; // Set the user's name
        });
      }
    }
  }

  /// Fetches the user's next appointment from Firestore and updates the state.
  Future<void> _getNextAppointment() async {
    final user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user != null) {
      final userId = user.uid; // Get the user's ID
      final now = DateTime.now(); // Current date and time

      // Query Firestore for the user's next confirmed appointment
      final appointmentSnapshot = await FirebaseFirestore.instance
          .collection('BookAppointments')
          .where('patientId', isEqualTo: userId)
          .where('status', isEqualTo: true)
          .where('appointmentDate', isGreaterThan: now)
          .orderBy('appointmentDate', descending: false)
          .limit(1)
          .get();

      if (appointmentSnapshot.docs.isNotEmpty) {
        final appointmentData = appointmentSnapshot.docs.first.data();
        final DateTime appointmentDate =
            (appointmentData['appointmentDate'] as Timestamp).toDate(); // Convert to DateTime

        setState(() {
          // Format the appointment date and update the text
          nextAppointmentText =
              'Next appointment: ${DateFormat('dd.MM.yy HH:mm').format(appointmentDate)}';
        });
      } else {
        setState(() {
          nextAppointmentText = 'No upcoming appointments'; // No upcoming appointments
        });
      }
    }
  }

  // List of category names to display in the grid view
  final List categoriesNames = [
    "Shared",
    "Appointments",
    "History",
    "Prescription"
  ];

  // List of icons corresponding to each category name
  final List<Icon> categoriesIcons = [
    const Icon(Icons.medical_services_sharp,
        color: Color(0xFF176139), size: 80),
    const Icon(Icons.calendar_month_sharp, color: Color(0xFF176139), size: 80),
    const Icon(Icons.history, color: Color(0xFF176139), size: 80),
    const Icon(Icons.description_sharp, color: Color(0xFF176139), size: 80),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          // Header container with user's name and profile icon
          Container(
            padding: EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 10),
            decoration: const BoxDecoration(
                color: Color(0xFF176139),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                )),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 30,
                      height: 30,
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/profile'); // Navigate to profile page
                      },
                      child: const Icon(Icons.account_circle_sharp,
                          size: 30, color: Color(0xFFFFFFFF)), // Profile icon
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Greeting text with the user's name
                Padding(
                  padding: EdgeInsets.only(left: 3, bottom: 15),
                  child: Text("Hello, $userName",
                      style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          wordSpacing: 2,
                          color: Color(0xFFFFFFFF))),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 20, left: 15, right: 15),
            child: Column(
              children: [
                // Home page title
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text(
                      "Home page",
                      style:
                          TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Grid view displaying different categories
                GridView.builder(
                    itemCount: categoriesNames.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio:
                            (MediaQuery.of(context).size.height) / (4 * 240),
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20),
                    itemBuilder: (context, index) {
                      return InkWell(
                          onTap: () {
                            // Navigate to the corresponding page based on the index
                            switch (index) {
                              case 0:
                                Navigator.pushNamed(
                                    context, '/sharedCondition');
                                break;
                              case 1:
                                Navigator.pushNamed(
                                        context, '/viewPatientAppointment')
                                    .then((_) {
                                  _getNextAppointment(); // Refresh next appointment
                                });
                                break;
                              case 2:
                                Navigator.pushNamed(
                                    context, '/patients conditions patient');
                                break;
                              case 3:
                                Navigator.pushNamed(
                                    context, '/prescriptions list');
                                break;
                              default:
                                break;
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 20, horizontal: 10),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: const Color(0xFFFFFFFF),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0x339E9E9E),
                                      spreadRadius: 5,
                                      blurRadius: 7,
                                      offset: Offset(0, 3)) // Shadow effect
                                ]),
                            child: Column(
                              children: [
                                // Icon for each category
                                Padding(
                                    padding: EdgeInsets.all(10),
                                    child: categoriesIcons[index]),
                                const SizedBox(height: 10),
                                // Category name
                                Text(
                                  categoriesNames[index],
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF000000)),
                                ),
                              ],
                            ),
                          ));
                    }),
                const SizedBox(height: 30),
                // Divider with "Reminder" text
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Divider(),
                    ),
                    const Text("Reminder"),
                    Expanded(
                      child: Divider(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Container displaying the next appointment details
                Container(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5), // Shadow effect
                      ),
                    ],
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Color(0xFF176139),
                        size: 40, // Calendar icon
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title text for the upcoming appointment
                            Text(
                              "Upcoming Appointment",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Text displaying the next appointment date and time
                            Text(
                              nextAppointmentText,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
