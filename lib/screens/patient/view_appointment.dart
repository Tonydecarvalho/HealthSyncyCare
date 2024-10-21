import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting
import 'book_appointment.dart'; // Import your booking page

class ViewAppointmentPage extends StatefulWidget {
  const ViewAppointmentPage({super.key});

  @override
  _ViewAppointmentPageState createState() => _ViewAppointmentPageState();
}

class _ViewAppointmentPageState extends State<ViewAppointmentPage> {
  bool _isLoading = true;
  String? _userId;
  List<Map<String, dynamic>> _upcomingAppointments = [];

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  // Function to fetch the logged-in user's ID
  Future<void> _fetchUserId() async {
    try {
      setState(() => _isLoading = true);
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        _userId = user.uid;
        await _fetchUpcomingAppointments();
      } else {
        throw Exception('No user logged in');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching user ID: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

// Fetch upcoming appointments only for the logged-in user and with status == true
Future<void> _fetchUpcomingAppointments() async {
  setState(() => _isLoading = true);
  try {
    final now = DateTime.now();
    final appointmentsSnapshot = await FirebaseFirestore.instance
        .collection('BookAppointments')
        .where('patientId', isEqualTo: _userId)
        .where('status', isEqualTo: true) // Filter for confirmed appointments
        .where('appointmentDate', isGreaterThanOrEqualTo: now) // Only upcoming appointments
        .orderBy('appointmentDate', descending: false) // Sort by date
        .get();

    List<Map<String, dynamic>> appointments = [];

    for (var doc in appointmentsSnapshot.docs) {
      final data = doc.data();
      final appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
      final status = 'Confirmed'; // Since we filter for true, status is always confirmed
      final doctorId = data['doctorId']; // Get doctorId from the appointment

      // Fetch doctor's details using the doctorId
      final doctorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .get();
      final doctorFirstName = doctorDoc['firstName'];
      final doctorLastName = doctorDoc['lastName'];
      final doctorName = '$doctorFirstName $doctorLastName'; // Full name of the doctor

      appointments.add({
        'docId': doc.id, // Store document ID for cancellation
        'date': appointmentDate,
        'status': status,
        'symptoms': data['symptoms'],
        'doctorName': doctorName, // Add doctor's name to the appointment data
      });
    }

    setState(() {
      _upcomingAppointments = appointments;
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error fetching appointments: $e")),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}


  // Function to format the date with the month name
  String formatDate(DateTime date) {
    return DateFormat('d MMMM y').format(date); // e.g., "18 October 2024"
  }

  // Function to cancel the appointment
  Future<void> _cancelAppointment(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('BookAppointments')
          .doc(docId)
          .update({'status': false}); // Mark as vacant, remove patientId

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment successfully canceled')),
      );

      // Refresh the appointments list
      await _fetchUpcomingAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel appointment: $e')),
      );
    }
  }

  // Show a confirmation dialog before canceling
  Future<void> _showCancelConfirmationDialog(String docId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _cancelAppointment(docId); // Proceed with canceling the appointment
              },
            ),
          ],
        );
      },
    );
  }

  // Function to build each appointment card with an edit symptoms button
  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final DateTime appointmentDate = appointment['date'];
    final String status = appointment['status'];
    final String symptoms = appointment['symptoms'] ?? 'No symptoms provided';
    final String docId = appointment['docId']; // Document ID for updating
    final String doctorName = appointment['doctorName']; // Doctor's name

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatDate(appointmentDate), // Format the date with month name
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Time: ${appointmentDate.hour}:${appointmentDate.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Doctor: $doctorName', // Display the doctor's name
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Symptoms: $symptoms',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Status: $status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: status == 'Confirmed' ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () => _showEditSymptomsDialog(docId, symptoms),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, // Edit button color
                  ),
                  child: const Text('Edit Symptoms'),
                ),
                ElevatedButton(
                  onPressed: () => _showCancelConfirmationDialog(docId),
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

  // Function to show dialog to edit symptoms
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
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without saving
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateSymptoms(docId, _symptomsController.text); // Save the updated symptoms
                Navigator.of(context).pop(); // Close the dialog after saving
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
      await FirebaseFirestore.instance
          .collection('BookAppointments')
          .doc(docId)
          .update({'symptoms': newSymptoms}); // Update symptoms field in Firestore

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Symptoms updated successfully!')),
      );

      // Refresh the appointments list
      await _fetchUpcomingAppointments();
    } catch (e) {
      // Show error message
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
          'No upcoming appointments found.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _upcomingAppointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(_upcomingAppointments[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Upcoming Appointments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildAppointmentList(),
            ),
      // Floating button to create a new appointment
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the book appointment page and refresh when returning
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BookAppointmentPage()),
          ).then((_) {
            // Refresh the appointments after returning from the booking page
            _fetchUpcomingAppointments();
          });
        },
        child: const Icon(Icons.add),
        tooltip: 'Create New Appointment',
      ),
    );
  }
}
