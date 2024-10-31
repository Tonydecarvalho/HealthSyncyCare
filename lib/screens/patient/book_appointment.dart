import 'package:flutter/material.dart'; // Flutter framework for UI components
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore for cloud-based database
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication for user management
import 'package:table_calendar/table_calendar.dart'; // Calendar package to display date selector
import '../../email_service.dart'; // Custom service to send emails

/// Page where patients can book appointments by selecting a date and time.
class BookAppointmentPage extends StatefulWidget {
  const BookAppointmentPage({super.key});

  @override
  _BookAppointmentPageState createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  CalendarFormat _calendarFormat =
      CalendarFormat.month; // Format of the calendar view
  DateTime _focusedDay =
      DateTime.now(); // Currently focused day on the calendar
  DateTime? _selectedDay; // Selected day on the calendar
  String? _selectedTime; // Selected time slot for the appointment
  bool _isSaving = false; // Flag to indicate if the appointment is being saved
  bool _isLoading = true; // Flag to indicate loading state for available times
  String? _userId; // Stores the user ID of the logged-in user
  final Map<DateTime, List<Map<String, dynamic>>> _availableTimes =
      {}; // Map to store available times for appointments
  final TextEditingController _symptomsController =
      TextEditingController(); // Controller for the symptoms input

  @override
  void initState() {
    super.initState();
    _fetchUserId(); // Fetch the user ID when the page loads
  }

  /// Fetches the logged-in user's ID from Firebase Auth and loads available times from Firestore.
  Future<void> _fetchUserId() async {
    try {
      setState(() => _isLoading = true); // Set loading state to true
      User? user = FirebaseAuth.instance.currentUser; // Get the current user

      if (user != null) {
        _userId = user.uid; // Set the user ID
        await _fetchAvailableTimes(); // Fetch available appointment times
      } else {
        throw Exception(
            'No user logged in'); // Handle case where no user is logged in
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error fetching user ID: $e")), // Show error message
      );
    } finally {
      setState(() => _isLoading = false); // Set loading state to false
    }
  }

  /// Fetches available appointment times from Firestore and populates the _availableTimes map.
  Future<void> _fetchAvailableTimes() async {
    setState(() => _isLoading = true); // Set loading state to true
    try {
      final appointmentsSnapshot = await FirebaseFirestore.instance
          .collection('BookAppointments')
          .get(); // Fetch all appointments

      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        final appointmentDate = (data['appointmentDate'] as Timestamp)
            .toDate(); // Convert to DateTime
        final isBooked =
            data['status'] == true; // Check if the appointment is booked

        final appointmentDateUTC = DateTime.utc(
          appointmentDate.year,
          appointmentDate.month,
          appointmentDate.day,
        ); // Convert date to UTC format

        final appointmentTime =
            "${appointmentDate.hour}:${appointmentDate.minute.toString().padLeft(2, '0')}"; // Format time string

        // Add the appointment time to the map, creating a new entry if necessary
        if (!_availableTimes.containsKey(appointmentDateUTC)) {
          _availableTimes[appointmentDateUTC] = [];
        }
        _availableTimes[appointmentDateUTC]!.add({
          'time': appointmentTime,
          'isBooked': isBooked,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Error fetching appointments: $e")), // Show error message
      );
    } finally {
      setState(() => _isLoading = false); // Set loading state to false
    }
  }

  /// Saves the selected appointment to Firestore and sends a confirmation email.
  Future<void> _saveAppointment(String symptoms) async {
    try {
      if (_userId == null)
        throw Exception('User ID not found'); // Ensure the user ID is present

      DateTime appointmentDateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        int.parse(
            _selectedTime!.split(':')[0]), // Parse hour from selected time
        int.parse(
            _selectedTime!.split(':')[1]), // Parse minute from selected time
      );

      // Fetch user document to get the assigned doctorId
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();
      String? doctorId = userDoc['doctorId'];

      if (doctorId == null || doctorId.isEmpty) {
        throw Exception('No doctorId assigned to this user.');
      }

      // Add new appointment to Firestore
      await FirebaseFirestore.instance.collection('BookAppointments').add({
        'appointmentDate': Timestamp.fromDate(appointmentDateTime),
        'status': true, // Mark as booked
        'symptoms': symptoms, // Patient symptoms
        'patientId': _userId, // Associate with user ID
        'doctorId': doctorId, // Associated doctor ID
        'createdTime': Timestamp.now(), // Timestamp of creation
        'reminderSent': false, // Initial state for reminder
      });

      // Update user document with doctorId
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'doctorId': doctorId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Appointment saved and marked as booked!')), // Success message
      );

      // Fetch doctor details for the email
      final doctorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .get();
      final doctorFirstName = doctorDoc['firstName'];
      final doctorLastName = doctorDoc['lastName'];
      final doctorEmail = doctorDoc['email'];

      // Get patient details for the email
      final firstName = userDoc['firstName'];
      final lastName = userDoc['lastName'];
      final userEmail = userDoc['email'];

      // Send a confirmation email
      await sendConfirmationEmail(
        userEmail,
        '$firstName $lastName',
        doctorEmail,
        '$doctorFirstName $doctorLastName',
        appointmentDateTime,
      );

      // Refresh available times to show the updated slots
      await _fetchAvailableTimes();

      setState(() {
        _isSaving = false; // Reset saving state
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Error saving appointment: $e")), // Show error message
      );
    }
  }

  /// Generates available time slots for the selected day.
  List<Map<String, dynamic>> _generateTimeSlots(DateTime day) {
    DateTime now = DateTime.now();
    DateTime fourWeeksLater =
        now.add(const Duration(days: 28)); // Restrict to the next 4 weeks

    if (day.isBefore(now) || day.isAfter(fourWeeksLater)) {
      return []; // Return empty list if date is outside the allowed range
    }

    List<Map<String, dynamic>> timeSlots = [];
    DateTime start =
        DateTime(day.year, day.month, day.day, 9, 0); // Start at 9:00 AM
    DateTime end =
        DateTime(day.year, day.month, day.day, 17, 30); // End at 5:30 PM

    while (start.isBefore(end)) {
      final timeString =
          "${start.hour}:${start.minute.toString().padLeft(2, '0')}";

      // Check if the time slot is already booked
      bool isBooked =
          _availableTimes[DateTime.utc(day.year, day.month, day.day)]?.any(
                  (time) =>
                      time['time'] == timeString && time['isBooked'] == true) ??
              false;

      timeSlots.add({
        'time': timeString,
        'isBooked': isBooked,
      });
      start = start.add(const Duration(minutes: 30)); // Increment by 30 minutes
    }
    return timeSlots;
  }

  /// Handles day selection on the calendar.
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay; // Update selected day
      _focusedDay = focusedDay; // Update focused day
      _selectedTime = null; // Reset selected time
      _isSaving = false; // Reset saving state
    });
  }

  /// Handles time slot selection.
  void _onTimeSlotSelected(Map<String, dynamic> timeData) {
    if (!timeData['isBooked']) {
      setState(() {
        _selectedTime = timeData['time']; // Update selected time
        _isSaving = true; // Enable saving
      });
    }
  }

  /// Shows a confirmation dialog to enter symptoms and confirm the appointment.
  void _confirmAppointment(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Appointment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your symptoms:'),
              TextField(
                controller: _symptomsController,
                maxLength: 200,
                decoration: const InputDecoration(hintText: 'Symptoms...'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel button
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _saveAppointment(
                    _symptomsController.text); // Save the appointment
                _symptomsController.clear(); // Clear input
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green), // Button style
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  /// Builds a grid of available times for the selected day.
  Widget _buildAvailableTimesGrid() {
    if (_selectedDay == null)
      return const Center(child: Text('No day selected'));

    List<Map<String, dynamic>> timeSlots = _generateTimeSlots(_selectedDay!);

    if (timeSlots.isEmpty) {
      return const Center(child: Text('No available times for this day.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Available times for ${_selectedDay!.day}-${_selectedDay!.month}-${_selectedDay!.year}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, childAspectRatio: 2),
            itemCount: timeSlots.length,
            itemBuilder: (context, index) {
              final timeData = timeSlots[index];

              return GestureDetector(
                onTap: () => _onTimeSlotSelected(timeData),
                child: Container(
                  padding: const EdgeInsets.all(1),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: timeData['isBooked']
                        ? Colors.redAccent
                        : Colors.lightGreen,
                    border: Border.all(
                      color: _selectedTime == timeData['time'] &&
                              !timeData['isBooked']
                          ? Colors.green.shade900
                          : Colors.transparent,
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          timeData['isBooked'] ? Icons.lock : Icons.access_time,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeData['time'],
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds a button to save the selected appointment.
  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: () => _confirmAppointment(context),
          child: const Text('Save Appointment'),
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Appointment'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  focusedDay: _focusedDay,
                  firstDay: DateTime(2022),
                  lastDay: DateTime(2030),
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: _onDaySelected,
                  onFormatChanged: (format) {
                    setState(() => _calendarFormat = format);
                  },
                  onPageChanged: (focusedDay) {
                    setState(() => _focusedDay = focusedDay);
                  },
                ),
                Expanded(child: _buildAvailableTimesGrid()),
                _isSaving ? _buildSaveButton() : Container(),
              ],
            ),
    );
  }
}
