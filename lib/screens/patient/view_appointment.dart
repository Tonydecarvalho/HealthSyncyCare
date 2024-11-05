import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting
import 'book_appointment.dart'; // Import your booking page

class ViewPatientAppointmentPage extends StatefulWidget {
  const ViewPatientAppointmentPage({super.key});

  @override
  _ViewPatientAppointmentPageState createState() => _ViewPatientAppointmentPageState();
}

class _ViewPatientAppointmentPageState extends State<ViewPatientAppointmentPage> {
  bool _isLoading = true; // Flag to track loading state
  String? _userId; // Store the logged-in user's ID
  List<Map<String, dynamic>> _upcomingAppointments = []; // List to store upcoming appointments

  @override
  void initState() {
    super.initState();
    _fetchUserId(); // Fetch user ID when the page is loaded
  }

  // Function to fetch the logged-in user's ID
  Future<void> _fetchUserId() async {
    try {
      setState(() => _isLoading = true); // Set loading state to true
      User? user = FirebaseAuth.instance.currentUser; // Get the current user

      if (user != null) {
        _userId = user.uid; // Store the user's ID
        await _fetchUpcomingAppointments(); // Fetch upcoming appointments for the user
      } else {
        throw Exception('No user logged in'); // Throw an error if no user is logged in
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching user ID: $e")), // Display error message
      );
    } finally {
      setState(() => _isLoading = false); // Set loading state to false
    }
  }

  // Fetch upcoming appointments for the logged-in user with status == true
  Future<void> _fetchUpcomingAppointments() async {
    setState(() => _isLoading = true); // Set loading state to true
    try {
      final now = DateTime.now(); // Get the current date and time
      // Query Firestore for appointments where the patientId matches the logged-in user, status is true (confirmed), and the appointment is in the future
      final appointmentsSnapshot = await FirebaseFirestore.instance
          .collection('BookAppointments')
          .where('patientId', isEqualTo: _userId)
          .where('status', isEqualTo: true)
          .where('appointmentDate', isGreaterThanOrEqualTo: now) // Only upcoming appointments
          .orderBy('appointmentDate', descending: false) // Sort by date, ascending
          .get();

      List<Map<String, dynamic>> appointments = [];

      // Iterate through each appointment and get additional details like the doctor's name
      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        final appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
        final status = 'Confirmed'; // Since we filter by status == true, all appointments are confirmed
        final doctorId = data['doctorId']; // Get the doctorId from the appointment

        // Fetch doctor's details using the doctorId
        final doctorDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(doctorId)
            .get();
        final doctorFirstName = doctorDoc['firstName'];
        final doctorLastName = doctorDoc['lastName'];
        final doctorName = '$doctorFirstName $doctorLastName'; // Get the full name of the doctor

        // Add the appointment details to the list
        appointments.add({
          'docId': doc.id, // Store document ID for cancellation
          'date': appointmentDate,
          'status': status,
          'symptoms': data['symptoms'],
          'doctorName': doctorName, // Include the doctor's name
        });
      }

      setState(() {
        _upcomingAppointments = appointments; // Update the list of upcoming appointments
      });
    } catch (e) {
      // Display error message if fetching appointments fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching appointments: $e")),
      );
    } finally {
      setState(() => _isLoading = false); // Set loading state to false
    }
  }

  // Function to format the date with the month name
  String formatDate(DateTime date) {
    return DateFormat('d MMMM y').format(date); // Format the date, e.g., "18 October 2024"
  }

  // Function to cancel the appointment
  Future<void> _cancelAppointment(String docId) async {
    try {
      // Update the appointment status to false (cancel the appointment)
      await FirebaseFirestore.instance
          .collection('BookAppointments')
          .doc(docId)
          .update({'status': false});

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment successfully canceled')),
      );

      // Refresh the list of upcoming appointments
      await _fetchUpcomingAppointments();
    } catch (e) {
      // Show an error message if cancellation fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel appointment: $e')),
      );
    }
  }

  // Show a confirmation dialog before canceling the appointment
  Future<void> _showCancelConfirmationDialog(String docId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dialog from closing without confirmation
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Appointment'),
          content: const Text('Are you sure you want to cancel this appointment?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without canceling
              },
            ),
            ElevatedButton(
              child: const Text('Yes'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red), // Set button color to red
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _cancelAppointment(docId); // Proceed with cancellation
              },
            ),
          ],
        );
      },
    );
  }

  // Function to build each appointment card with edit and cancel buttons
  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final DateTime appointmentDate = appointment['date']; // Appointment date
    final String status = appointment['status']; // Appointment status
    final String symptoms = appointment['symptoms'] ?? 'No symptoms provided'; // Symptoms provided by the patient
    final String docId = appointment['docId']; // Document ID for the appointment
    final String doctorName = appointment['doctorName']; // Doctor's name

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15), // Margins for the card
      elevation: 4, // Elevation for card shadow effect
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Rounded corners for the card
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Appointment details (Date, time, doctor, etc.)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatDate(appointmentDate), // Format and display the appointment date
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Time: ${appointmentDate.hour}:${appointmentDate.minute.toString().padLeft(2, '0')}', // Display the appointment time
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Doctor: $doctorName', // Display the doctor's name
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Symptoms: $symptoms', // Display the symptoms
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Status: $status', // Display the appointment status
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: status == 'Confirmed' ? Colors.green : Colors.orange, // Green for confirmed, orange otherwise
                    ),
                  ),
                ],
              ),
            ),
            // Edit and cancel buttons for each appointment
            Column(
              children: [
                ElevatedButton(
                  onPressed: () => _showEditSymptomsDialog(docId, symptoms), // Open dialog to edit symptoms
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, // Edit button color
                  ),
                  child: const Text('Edit Symptoms'),
                ),
                ElevatedButton(
                  onPressed: () => _showCancelConfirmationDialog(docId), // Open dialog to cancel the appointment
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Set cancel button color to red
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Function to show a dialog to edit symptoms
  Future<void> _showEditSymptomsDialog(String docId, String currentSymptoms) async {
    final TextEditingController _symptomsController = TextEditingController(text: currentSymptoms);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Symptoms'),
          content: TextField(
            controller: _symptomsController,
            maxLength: 200,
            decoration: const InputDecoration(hintText: 'Enter new symptoms'),
            maxLines: 3, // Multi-line input for symptoms
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog without saving
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateSymptoms(docId, _symptomsController.text); // Save updated symptoms
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Function to update symptoms in Firestore
  Future<void> _updateSymptoms(String docId, String newSymptoms) async {
    try {
      // Update the symptoms field in the appointment document
      await FirebaseFirestore.instance
          .collection('BookAppointments')
          .doc(docId)
          .update({'symptoms': newSymptoms});

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Symptoms updated successfully!')),
      );

      // Refresh the list of upcoming appointments
      await _fetchUpcomingAppointments();
    } catch (e) {
      // Show an error message if the update fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update symptoms: $e')),
      );
    }
  }

  // Function to build the list of appointments
  Widget _buildAppointmentList() {
    if (_upcomingAppointments.isEmpty) {
      return const Center(
        child: Text(
          'No upcoming appointments found.', // Display if no appointments are found
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _upcomingAppointments.length, // Number of appointments
      itemBuilder: (context, index) {
        return _buildAppointmentCard(_upcomingAppointments[index]); // Build each appointment card
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Upcoming Appointments', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF176139),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context), // Navigate back
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading spinner if data is still being fetched
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildAppointmentList(), // Display the appointment list
            ),
      // Floating button to create a new appointment
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the booking page and refresh appointments when returning
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BookAppointmentPage()),
          ).then((_) {
            _fetchUpcomingAppointments(); // Refresh the appointments after booking
          });
        },
        child: const Icon(Icons.add),
        tooltip: 'Create New Appointment', // Tooltip for the floating button
      ),
    );
  }
}
