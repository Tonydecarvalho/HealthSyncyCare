import 'package:flutter/material.dart'; // Flutter framework for UI components
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore for cloud-based database
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication for user management
import 'package:table_calendar/table_calendar.dart'; // Calendar package to display date selector
import '../email_service.dart'; // Custom service to send emails

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  CalendarFormat _calendarFormat =
      CalendarFormat.month; // Format of the calendar view
  DateTime _focusedDay =
      DateTime.now(); // Currently focused day on the calendar
  DateTime? _selectedDay; // Selected day on the calendar
  String? _selectedTime; // Selected time slot for the appointment
  bool _isSaving = false; // Flag to indicate if appointment is being saved
  bool _isLoading = true; // Flag to indicate loading state for available times
  String? _userId; // For storing the fetched userId
  final Map<DateTime, List<Map<String, dynamic>>> _availableTimes =
      {}; // Store available times
  final TextEditingController _symptomsController =
      TextEditingController(); // Controller for symptoms input

  @override
  void initState() {
    super.initState();
    _fetchUserId(); // Fetch the user ID when the page loads
  }

  // Function to fetch the logged-in user's ID
  Future<void> _fetchUserId() async {
    try {
      setState(() => _isLoading = true);
      // Get the current user from Firebase Auth
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        _userId = user.uid; // Set the user ID
        await _fetchAvailableTimes(); // Fetch available times after userId is loaded
      } else {
        throw Exception(
            'No user logged in'); // Handle case where no user is logged in
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Error fetching user ID: $e")), // Show error message if failed
      );
    } finally {
      setState(() => _isLoading = false); // Stop loading state
    }
  }

  // Function to fetch available times from Firestore
  Future<void> _fetchAvailableTimes() async {
    setState(() => _isLoading = true);
    try {
      final appointmentsSnapshot = await FirebaseFirestore.instance
          .collection('BookAppointments')
          .get(); // Fetch all appointments from Firestore

      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data(); // Get appointment data
        final appointmentDate = (data['appointmentDate'] as Timestamp)
            .toDate(); // Convert Firestore timestamp to DateTime
        final isBooked =
            data['status'] == true; // Use status directly as boolean

        final appointmentDateUTC = DateTime.utc(
          appointmentDate.year,
          appointmentDate.month,
          appointmentDate.day,
        ); // Convert appointment date to UTC format

        final appointmentTime =
            "${appointmentDate.hour}:${appointmentDate.minute.toString().padLeft(2, '0')}"; // Format appointment time

        // Add appointment to the available times map
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
            content: Text(
                "Error fetching appointments: $e")), // Show error if fetching times fails
      );
    } finally {
      setState(() => _isLoading = false); // Stop loading state
    }
  }

  // Function to save the selected appointment to Firestore
  Future<void> _saveAppointment(String symptoms) async {
    try {
      if (_userId == null)
        throw Exception('User ID not found'); // Ensure user ID is present

      DateTime appointmentDateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        int.parse(_selectedTime!
            .split(':')[0]), // Parse selected time for the appointment
        int.parse(_selectedTime!.split(':')[1]),
      );

      // Add new appointment to the database
      await FirebaseFirestore.instance.collection('BookAppointments').add({
        'appointmentDate':
            Timestamp.fromDate(appointmentDateTime), // Store appointment date
        'status': true, // Marking as booked
        'symptoms': symptoms, // Store patient's symptoms
        'patientId': _userId, // Associate appointment with logged-in user
        'createdTime': Timestamp.now(), // Store appointment creation time
      });

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Appointment saved and marked as booked!')), // Success message
      );

      // Send confirmation email to the user
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();
      final userName = userDoc['name']; // Get user's name
      final userEmail = userDoc['email']; // Get user's email

      await sendConfirmationEmail(
          userEmail, userName, appointmentDateTime); // Send confirmation email

      // Refresh the available times to reflect the newly booked appointment
      await _fetchAvailableTimes();

      setState(() {
        _isSaving = false; // Reset saving state
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Error saving appointment: $e")), // Show error if saving fails
      );
    }
  }

  // Function to generate available time slots for the selected day
  List<Map<String, dynamic>> _generateTimeSlots(DateTime day) {
    DateTime now = DateTime.now();
    DateTime fourWeeksLater =
        now.add(const Duration(days: 28)); // Restrict booking to within 4 weeks

    // Ensure the day is within the next 4 weeks
    if (day.isBefore(now) || day.isAfter(fourWeeksLater)) {
      return []; // Return an empty list if the date is outside the 4-week window
    }

    List<Map<String, dynamic>> timeSlots = [];
    DateTime start =
        DateTime(day.year, day.month, day.day, 9, 0); // Start at 9:00 AM
    DateTime end =
        DateTime(day.year, day.month, day.day, 17, 30); // End at 5:30 PM

    while (start.isBefore(end)) {
      final timeString =
          "${start.hour}:${start.minute.toString().padLeft(2, '0')}"; // Format time slot string

      // Check if this specific time slot is already booked using the 'isBooked' field
      bool isBooked =
          _availableTimes[DateTime.utc(day.year, day.month, day.day)]
                  ?.any((time) {
                return time['time'] == timeString &&
                    time['isBooked'] ==
                        true; // Check if the time slot is booked
              }) ??
              false;

      timeSlots.add({
        'time': timeString,
        'isBooked': isBooked
      }); // Add time slot to the list
      start = start.add(const Duration(minutes: 30)); // Increment by 30 minutes
    }
    return timeSlots;
  }

  // Function to handle day selection on the calendar
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay; // Update selected day
      _focusedDay = focusedDay; // Update focused day on the calendar
      _selectedTime = null; // Reset selected time
      _isSaving = false; // Reset saving state
    });
  }

  // Function to handle time slot selection
  void _onTimeSlotSelected(Map<String, dynamic> timeData) {
    if (!timeData['isBooked']) {
      setState(() {
        _selectedTime = timeData['time']; // Update selected time
        _isSaving = true; // Enable save button
      });
    }
  }

  // Function to confirm the appointment with a dialog box for symptoms
  void _confirmAppointment(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Appointment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your symptoms:'), // Prompt for symptoms
              TextField(
                controller: _symptomsController, // Symptoms text field
                maxLength: 200,
                decoration: const InputDecoration(hintText: 'Symptoms...'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close the dialog
              child: const Text('Cancel'), // Cancel button
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _saveAppointment(
                    _symptomsController.text); // Save the appointment
                _symptomsController.clear(); // Clear the symptoms input field
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green), // Confirm button style
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  // Function to build the grid of available times
  Widget _buildAvailableTimesGrid() {
    if (_selectedDay == null)
      return const Center(
          child: Text('No day selected')); // Show message if no day is selected

    List<Map<String, dynamic>> timeSlots = _generateTimeSlots(
        _selectedDay!); // Generate time slots for selected day

    if (timeSlots.isEmpty) {
      return const Center(
          child: Text(
              'No available times for this day.')); // Show message if no times available
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Available times for ${_selectedDay!.day}-${_selectedDay!.month}-${_selectedDay!.year}', // Display selected date
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2), // 3 columns for time slots
            itemCount: timeSlots.length, // Number of available time slots
            itemBuilder: (context, index) {
              final timeData = timeSlots[index]; // Get time data for each slot

              return GestureDetector(
                onTap: () =>
                    _onTimeSlotSelected(timeData), // Handle time slot selection
                child: Container(
                  padding: const EdgeInsets.all(1),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: timeData['isBooked']
                        ? Colors.redAccent
                        : Colors.lightGreen, // Color based on booking status
                    border: Border.all(
                      color: _selectedTime == timeData['time'] &&
                              !timeData['isBooked']
                          ? Colors.green.shade900
                          : Colors.transparent, // Highlight selected time
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(
                        12), // Rounded corners for time slots
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          timeData['isBooked']
                              ? Icons.lock
                              : Icons
                                  .access_time, // Icon based on booking status
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeData['time'], // Display time
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

  // Function to build the save button for confirming the appointment
  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity, // Full-width button
        height: 60,
        child: ElevatedButton(
          onPressed: () => _confirmAppointment(
              context), // Confirm appointment on button press
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
          onPressed: () => Navigator.pop(
              context), // Back button to navigate to the previous screen
        ),
        title: const Text('Appointment'), // Page title
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator()) // Show loading spinner while data is being fetched
          : Column(
              children: [
                TableCalendar(
                  focusedDay: _focusedDay, // Focused day on the calendar
                  firstDay: DateTime(2022), // Earliest selectable date
                  lastDay: DateTime(2030), // Latest selectable date
                  calendarFormat:
                      _calendarFormat, // Calendar format (e.g., month)
                  selectedDayPredicate: (day) => isSameDay(
                      _selectedDay, day), // Highlight the selected day
                  onDaySelected: _onDaySelected, // Handle day selection
                  onFormatChanged: (format) {
                    setState(() =>
                        _calendarFormat = format); // Change calendar format
                  },
                  onPageChanged: (focusedDay) {
                    setState(() => _focusedDay =
                        focusedDay); // Update focused day when calendar page is changed
                  },
                ),
                Expanded(
                    child:
                        _buildAvailableTimesGrid()), // Display available time slots
                _isSaving
                    ? _buildSaveButton()
                    : Container(), // Display save button only if saving is allowed
              ],
            ),
    );
  }
}
