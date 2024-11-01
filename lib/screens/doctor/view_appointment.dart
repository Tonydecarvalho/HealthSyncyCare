import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

/// A page that displays a doctor's calendar and their appointments.
class ViewDoctorAppointmentPage extends StatefulWidget {
  const ViewDoctorAppointmentPage({Key? key}) : super(key: key);

  @override
  _ViewDoctorAppointmentPageState createState() =>
      _ViewDoctorAppointmentPageState();
}

class _ViewDoctorAppointmentPageState extends State<ViewDoctorAppointmentPage> {
  // The ID of the currently logged-in doctor, retrieved from Firebase Auth.
  final String? doctorId = FirebaseAuth.instance.currentUser?.uid;

  // The selected day on the calendar, initially set to today.
  DateTime _selectedDay = DateTime.now();

  // A map storing appointments, grouped by the date.
  Map<DateTime, List<Map<String, dynamic>>> _appointments = {};

  @override
  void initState() {
    super.initState();
    _loadAppointments(); // Load the doctor's appointments when the page is initialized.
  }

  /// Formats a [DateTime] to a human-readable string in the device’s local time zone.
  String formatDateToLocal(DateTime date) {
    return DateFormat('d MMMM y, HH:mm').format(date.toLocal());
  }

  /// Loads the doctor's appointments from Firestore and organizes them by date.
  void _loadAppointments() async {
    if (doctorId == null) return; // Return if there is no logged-in doctor.

    // Query Firestore for appointments associated with the doctor that are confirmed (status = true).
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('BookAppointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: true)
        .get();

    // A temporary map to store the loaded appointments.
    Map<DateTime, List<Map<String, dynamic>>> loadedAppointments = {};

    // Loop through each appointment document in the snapshot.
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
      final patientId = data['patientId'];
      final symptoms = data['symptoms'];

      // Fetch the patient's details from the 'users' collection.
      final patientSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get();
      final patientData = patientSnapshot.data()!;
      final patientName =
          '${patientData['firstName']} ${patientData['lastName']}';

      // Use only the date portion for grouping appointments.
      DateTime dateOnly = DateTime(
          appointmentDate.year, appointmentDate.month, appointmentDate.day);
      if (loadedAppointments[dateOnly] == null) {
        loadedAppointments[dateOnly] = [];
      }

      // Add the appointment details to the list for that date.
      loadedAppointments[dateOnly]!.add({
        'time': formatDateToLocal(
            appointmentDate), // Format the appointment time to local.
        'patientName': patientName,
        'patientId': patientId,
        'symptoms': symptoms,
      });
    }

    // Update the state with the loaded appointments.
    setState(() {
      _appointments = loadedAppointments;
    });
  }

  /// Returns the appointments for the selected day.
  List<Map<String, dynamic>> _getAppointmentsForDay(DateTime day) {
    return _appointments[DateTime(day.year, day.month, day.day)] ?? [];
  }

  /// Shows a dialog with detailed information about the patient.
  void _showPatientDetails(String patientId) async {
    // Fetch patient details from Firestore.
    final patientSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(patientId)
        .get();
    final patientData = patientSnapshot.data()!;

    // Display a dialog with the patient's details.
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${patientData['firstName']} ${patientData['lastName']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Make the dialog box compact.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${patientData['email']}'),
              Text('Phone: ${patientData['phone']}'),
              Text(
                  'Address: ${patientData['address']}, ${patientData['city']}, ${patientData['postalCode']}, ${patientData['country']}'),
              Text(
                  'Date of Birth: ${DateFormat('dd MMMM yyyy').format(DateTime.parse(patientData['dateOfBirth']))}'),
              Text('Gender: ${patientData['gender']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog.
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
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // A calendar widget for selecting and viewing appointments by day.
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _selectedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) {
              return isSameDay(
                  _selectedDay, day); // Highlight the selected day.
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay; // Update the selected day.
              });
            },
            // Add a marker (dot) to days that have appointments.
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (_appointments[DateTime(day.year, day.month, day.day)] !=
                    null) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red, // Red dot to indicate appointments.
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 10), // Add some space below the calendar.
          // Display the list of appointments for the selected day.
          Expanded(
            child: _buildAppointmentList(),
          ),
        ],
      ),
    );
  }

  /// Builds a list of appointments for the selected day.
  Widget _buildAppointmentList() {
    List<Map<String, dynamic>> selectedAppointments =
        _getAppointmentsForDay(_selectedDay);

    if (selectedAppointments.isEmpty) {
      return const Center(
        child: Text('No appointments for this day.'),
      );
    }

    // Use a ListView to display each appointment in a card.
    return ListView.builder(
      itemCount: selectedAppointments.length,
      itemBuilder: (context, index) {
        final appointment = selectedAppointments[index];
        return Card(
          color: Colors.green[100], // Light green background for the card.
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 3.0, // Shadow effect for the card.
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            title: Text(
              appointment['patientName'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            subtitle: Text(
              'Symptoms: ${appointment['symptoms']}',
              style: const TextStyle(fontSize: 16.0),
            ),
            trailing: Text(
              appointment['time'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
                color: Colors.black,
              ),
            ),
            onTap: () {
              _showPatientDetails(
                  appointment['patientId']); // Show patient details on tap.
            },
          ),
        );
      },
    );
  }
}
