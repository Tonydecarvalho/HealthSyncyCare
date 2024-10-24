import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class ViewDoctorAppointmentPage extends StatefulWidget {
  const ViewDoctorAppointmentPage({Key? key}) : super(key: key);

  @override
  _ViewDoctorAppointmentPageState createState() =>
      _ViewDoctorAppointmentPageState();
}

class _ViewDoctorAppointmentPageState extends State<ViewDoctorAppointmentPage> {
  // Fetch the currently logged-in doctor's ID from Firebase Authentication
  final String? doctorId = FirebaseAuth.instance.currentUser?.uid; 

  // Track the currently selected day on the calendar
  DateTime _selectedDay = DateTime.now();

  // Store the appointments, organized by the date (key: DateTime, value: List of appointments)
  Map<DateTime, List<Map<String, dynamic>>> _appointments = {};

  @override
  void initState() {
    super.initState();
    _loadAppointments(); // Load the doctor's appointments when the widget initializes
  }

  // Function to load the doctor's appointments from Firestore
  void _loadAppointments() async {
    if (doctorId == null) return; // If no doctor is logged in, return

    // Query Firestore to get appointments where the doctorId matches and the appointment is confirmed (status = true)
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('BookAppointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: true)
        .get();

    // A map to temporarily store the loaded appointments organized by date
    Map<DateTime, List<Map<String, dynamic>>> loadedAppointments = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final appointmentDate = (data['appointmentDate'] as Timestamp).toDate(); // Convert Firestore timestamp to DateTime
      final patientId = data['patientId']; // Get the patient ID for the appointment
      final symptoms = data['symptoms']; // Get the symptoms information

      // Fetch the patient's details from the 'users' collection in Firestore
      final patientSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get();
      final patientData = patientSnapshot.data()!;
      final patientName = '${patientData['firstName']} ${patientData['lastName']}'; // Concatenate first and last name

      // Ignore the time portion of the appointment date for better grouping of appointments on the same day
      DateTime dateOnly = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);
      if (loadedAppointments[dateOnly] == null) {
        loadedAppointments[dateOnly] = [];
      }

      // Add the appointment time and patient details to the list of appointments for that date
      loadedAppointments[dateOnly]!.add({
        'time': DateFormat.Hm().format(appointmentDate), // Format time in HH:mm
        'patientName': patientName,
        'patientId': patientId,
        'symptoms': symptoms,
      });
    }

    // Update the state with the loaded appointments
    setState(() {
      _appointments = loadedAppointments;
    });
  }

  // Function to get appointments for a specific day
  List<Map<String, dynamic>> _getAppointmentsForDay(DateTime day) {
    return _appointments[DateTime(day.year, day.month, day.day)] ?? []; // Return the list or an empty list if none exist
  }

  // Function to show a dialog with detailed patient information
  void _showPatientDetails(String patientId) async {
    // Fetch patient details from Firestore using the patient ID
    final patientSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(patientId)
        .get();
    final patientData = patientSnapshot.data()!;

    // Show a dialog displaying the patient's information
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${patientData['firstName']} ${patientData['lastName']}'), // Display patient's name
          content: Column(
            mainAxisSize: MainAxisSize.min, // Ensure the dialog isn't too large
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${patientData['email']}'),
              Text('Phone: ${patientData['phone']}'),
              Text('Address: ${patientData['address']}, ${patientData['city']}, ${patientData['postalCode']}, ${patientData['country']}'),
              Text('Date of Birth: ${DateFormat('dd MMMM yyyy').format(DateTime.parse(patientData['dateOfBirth']))}'), // Format date of birth
              Text('Gender: ${patientData['gender']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor\'s Calendar'),
        backgroundColor: Colors.green, // Set the color of the app bar to green
      ),
      body: Column(
        children: [
          // Calendar widget to display a calendar and allow the doctor to select a day
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1), // Start date of the calendar
            lastDay: DateTime.utc(2030, 12, 31), // End date of the calendar
            focusedDay: _selectedDay, // Initially focused day
            calendarFormat: CalendarFormat.month, // Display the calendar in month format
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day); // Highlight the selected day
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay; // Update the selected day
              });
            },
            // Add markers (dots) to days that have appointments
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (_appointments[DateTime(day.year, day.month, day.day)] != null) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red, // Red dot indicating an appointment
                      ),
                    ),
                  );
                }
                return null; // No marker for days without appointments
              },
            ),
          ),
          const SizedBox(height: 10), // Space between the calendar and the list of appointments
          // Display appointments for the selected day
          Expanded(
            child: _buildAppointmentList(), // Build the list of appointments for the selected day
          ),
        ],
      ),
    );
  }

  // Function to build the list of appointments for the selected day
  Widget _buildAppointmentList() {
    // Get the appointments for the selected day
    List<Map<String, dynamic>> selectedAppointments = _getAppointmentsForDay(_selectedDay);

    // If no appointments are found for the day, show a message
    if (selectedAppointments.isEmpty) {
      return const Center(
        child: Text('No appointments for this day.'),
      );
    }

    // Build a list of appointments using a ListView
    return ListView.builder(
      itemCount: selectedAppointments.length, // Number of appointments
      itemBuilder: (context, index) {
        final appointment = selectedAppointments[index]; // Get the appointment at the current index
        return Card(
          color: Colors.green[100], // Light green background color for each appointment card
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Margins around the card
          elevation: 3.0, // Slight shadow for the card
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0), // Padding inside the card
            title: Text(
              appointment['patientName'], // Display the patient's name
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0, // Font size for the patient's name
              ),
            ),
            subtitle: Text(
              'Symptoms: ${appointment['symptoms']}', // Display the symptoms
              style: const TextStyle(fontSize: 16.0), // Font size for the symptoms
            ),
            trailing: Text(
              appointment['time'], // Display the appointment time
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.0, // Make the time text larger
                color: Colors.black,
              ),
            ),
            onTap: () {
              _showPatientDetails(appointment['patientId']); // Show patient details in a dialog when tapped
            },
          ),
        );
      },
    );
  }
}
