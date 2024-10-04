import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  // Current format of the calendar (month, week, or two weeks)
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // The currently focused day displayed in the calendar
  DateTime _focusedDay = DateTime.now();

  // The day selected by the user
  DateTime? _selectedDay;

  // The time slot selected by the user
  String? _selectedTime;

  // Flag to indicate if the appointment is in the process of being saved
  bool _isSaving = false;

  // Mock available times with their booked status for demonstration purposes (Later replaced by data from database)
  final Map<DateTime, List<Map<String, dynamic>>> _availableTimes = {
    DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day):
        [
      {'time': '10:00', 'isBooked': false},
      {'time': '11:30', 'isBooked': true},
      {'time': '14:00', 'isBooked': false},
      {'time': '15:30', 'isBooked': false},
      {'time': '16:30', 'isBooked': false},
      {'time': '17:30', 'isBooked': false},
    ],
    DateTime.utc(
        DateTime.now().year, DateTime.now().month, DateTime.now().day + 1): [
      {'time': '9:00', 'isBooked': false},
      {'time': '13:00', 'isBooked': true},
    ],
  };

  // Retrieves the available times for a selected day
  List<Map<String, dynamic>> _getAvailableTimesForDay(DateTime day) {
    return _availableTimes[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  // Handles the selection of a day in the calendar
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay; // Update selected day
      _focusedDay = focusedDay; // Update focused day
      _selectedTime = null; // Reset selected time
      _isSaving = false; // Reset saving flag
    });
  }

  // Handles the selection of a time slot
  void _onTimeSlotSelected(Map<String, dynamic> timeData) {
    if (!timeData['isBooked']) {
      // Only proceed if the time is not booked
      setState(() {
        _selectedTime = timeData['time']; // Set the selected time
        _isSaving = true; // Set saving flag to true
      });
    }
  }

  // Displays a confirmation dialog before saving the appointment
  void _confirmAppointment(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Appointment'),
          content:
              const Text('Are you sure you want to save this appointment?'),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(), // Close dialog without saving
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Mark the selected time as booked in the available times
                  final timesForDay = _availableTimes[DateTime.utc(
                      _selectedDay!.year,
                      _selectedDay!.month,
                      _selectedDay!.day)];
                  final timeIndex = timesForDay!
                      .indexWhere((time) => time['time'] == _selectedTime);
                  if (timeIndex != -1) {
                    timesForDay[timeIndex]['isBooked'] =
                        true; // Update booked status
                  }
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('Appointment saved and marked as booked!')));
                  _isSaving = false; // Hide the Save Appointment button
                });
                Navigator.of(context).pop(); // Close confirmation dialog
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Confirm'),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          }, 
        ),
        title: const Text('Appointment'),
      ),
      body: Column(
        children: [
          // Display the calendar widget
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime(2022),
            lastDay: DateTime(2030),
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) =>
                setState(() => _calendarFormat = format),
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
          ),
          const SizedBox(height: 16.0),
          // Show available times for the selected date
          Expanded(
            child: _selectedDay == null
                ? const Center(
                    child: Text(
                        'Please select a day')) // Prompt user to select a day
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Available times for ${_selectedDay!.toLocal().day}-${_selectedDay!.toLocal().month}-${_selectedDay!.toLocal().year}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3, childAspectRatio: 2),
                          itemCount:
                              _getAvailableTimesForDay(_selectedDay!).length,
                          itemBuilder: (context, index) {
                            final timeData =
                                _getAvailableTimesForDay(_selectedDay!)[index];

                            return GestureDetector(
                              onTap: () => _onTimeSlotSelected(
                                  timeData), // Select the time slot
                              child: Container(
                                padding: const EdgeInsets.all(1),
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: timeData['isBooked']
                                      ? Colors.redAccent
                                      : Colors
                                          .lightGreen, // Color indicates booked status
                                  border: Border.all(
                                    color: _selectedTime == timeData['time'] &&
                                            !timeData['isBooked']
                                        ? Colors.green.shade900
                                        : Colors.transparent,
                                    width: 4,
                                  ),
                                  boxShadow: _selectedTime == timeData['time']
                                      ? [
                                          const BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 6)
                                        ]
                                      : [],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                          timeData['isBooked']
                                              ? Icons.lock
                                              : Icons.access_time,
                                          color: Colors
                                              .white), // Icon indicates booked status
                                      const SizedBox(width: 8),
                                      Text(timeData['time'],
                                          style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.white),
                                          textAlign: TextAlign.center),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          // Display the Save button if a time slot is selected
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () =>
                      _confirmAppointment(context), // Confirm the appointment
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 120, 74, 195),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Appointment',
                      style: TextStyle(fontSize: 24, color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
