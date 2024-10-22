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
  final String? doctorId = FirebaseAuth.instance.currentUser?.uid; // Assuming the doctor is logged in
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _appointments = {};

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  // Function to load appointments from Firestore
  void _loadAppointments() async {
    if (doctorId == null) return;

    // Query Firestore to get appointments for this doctor
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('BookAppointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: true) // Only load confirmed appointments
        .get();

    Map<DateTime, List<Map<String, dynamic>>> loadedAppointments = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
      final patientId = data['patientId'];
      final symptoms = data['symptoms'];

      // Fetch the patient name from the 'users' collection
      final patientSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get();
      final patientData = patientSnapshot.data()!;
      final patientName = '${patientData['firstName']} ${patientData['lastName']}';

      // Get the appointment date (ignoring time) and add to the map
      DateTime dateOnly = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);
      if (loadedAppointments[dateOnly] == null) {
        loadedAppointments[dateOnly] = [];
      }

      // Add the appointment time and patient details to the list
      loadedAppointments[dateOnly]!.add({
        'time': DateFormat.Hm().format(appointmentDate), // Format time as HH:mm
        'patientName': patientName,
        'patientId': patientId, // Keep the patientId to fetch more details later
        'symptoms': symptoms,
      });
    }

    setState(() {
      _appointments = loadedAppointments;
    });
  }

  // Function to get appointments for a specific day
  List<Map<String, dynamic>> _getAppointmentsForDay(DateTime day) {
    return _appointments[DateTime(day.year, day.month, day.day)] ?? [];
  }

  // Function to show patient details in a dialog
  void _showPatientDetails(String patientId) async {
    // Fetch patient details from Firestore
    final patientSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(patientId)
        .get();
    final patientData = patientSnapshot.data()!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${patientData['firstName']} ${patientData['lastName']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${patientData['email']}'),
              Text('Phone: ${patientData['phone']}'),
              Text('Address: ${patientData['address']}, ${patientData['city']}, ${patientData['postalCode']}, ${patientData['country']}'),
              Text('Date of Birth: ${DateFormat('dd MMMM yyyy').format(DateTime.parse(patientData['dateOfBirth']))}'),
              Text('Gender: ${patientData['gender']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
          // Calendar widget to select a day
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _selectedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
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
                        color: Colors.red, // Mark days with appointments
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 10),
          // Display appointments for the selected day
          Expanded(
            child: _buildAppointmentList(),
          ),
        ],
      ),
    );
  }

  // Widget to build the list of appointments
  Widget _buildAppointmentList() {
    List<Map<String, dynamic>> selectedAppointments = _getAppointmentsForDay(_selectedDay);

    if (selectedAppointments.isEmpty) {
      return const Center(
        child: Text('No appointments for this day.'),
      );
    }

    return ListView.builder(
      itemCount: selectedAppointments.length,
      itemBuilder: (context, index) {
        final appointment = selectedAppointments[index];
        return Card(
          color: Colors.green[100], // Set the background color to a light green
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 3.0, // Slight shadow for the card
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
                fontSize: 20.0, // Make the time bigger
                color: Colors.black,
              ),
            ),
            onTap: () {
              _showPatientDetails(appointment['patientId']); // Open dialog with patient details
            },
          ),
        );
      },
    );
  }
}
