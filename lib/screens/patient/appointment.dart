import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class AppointmentPage extends StatefulWidget {
  final String userId;

  const AppointmentPage({super.key, required this.userId});

  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTime;
  bool _isSaving = false;
  bool _isLoading = true;
  final Map<DateTime, List<Map<String, dynamic>>> _availableTimes = {};
  final TextEditingController _symptomsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAvailableTimes();
  }

Future<void> _fetchAvailableTimes() async {
  setState(() => _isLoading = true);
  try {
    final appointmentsSnapshot = await FirebaseFirestore.instance
        .collection('BookAppointments')
        .get();

    for (var doc in appointmentsSnapshot.docs) {
      final data = doc.data();
      final appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
      final isBooked = data['status'] == true; // Use status directly as boolean

      final appointmentDateUTC = DateTime.utc(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
      );

      final appointmentTime =
          "${appointmentDate.hour}:${appointmentDate.minute.toString().padLeft(2, '0')}";

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
      SnackBar(content: Text("Error fetching appointments: $e")),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}


Future<void> _saveAppointment(String symptoms) async {
  try {
    DateTime appointmentDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      int.parse(_selectedTime!.split(':')[0]),
      int.parse(_selectedTime!.split(':')[1]),
    );

    // Add new appointment to the database
    await FirebaseFirestore.instance.collection('BookAppointments').add({
      'appointmentDate': Timestamp.fromDate(appointmentDateTime),
      'status': true,  // Marking as booked
      'symptoms': symptoms,
      'patientId': widget.userId,
      'createdTime': Timestamp.now(),
    });

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment saved and marked as booked!')),
    );

    // Refresh the available times to reflect the newly booked appointment
    await _fetchAvailableTimes();

    setState(() {
      _isSaving = false;
    });

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error saving appointment: $e")),
    );
  }
}


List<Map<String, dynamic>> _generateTimeSlots(DateTime day) {
  DateTime now = DateTime.now();
  DateTime fourWeeksLater = now.add(const Duration(days: 28));

  // Ensure the day is within the next 4 weeks
  if (day.isBefore(now) || day.isAfter(fourWeeksLater)) {
    return []; // Return an empty list if the date is outside the 4-week window
  }

  List<Map<String, dynamic>> timeSlots = [];
  DateTime start = DateTime(day.year, day.month, day.day, 9, 0);
  DateTime end = DateTime(day.year, day.month, day.day, 17, 30);

  while (start.isBefore(end)) {
    final timeString =
        "${start.hour}:${start.minute.toString().padLeft(2, '0')}";

    // Check if this specific time slot is already booked using the 'isBooked' field
    bool isBooked = _availableTimes[DateTime.utc(day.year, day.month, day.day)]?.any((time) {
          return time['time'] == timeString && time['isBooked'] == true;
        }) ?? false;

    timeSlots.add({'time': timeString, 'isBooked': isBooked});
    start = start.add(const Duration(minutes: 30));
  }
  return timeSlots;
}




  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedTime = null;
      _isSaving = false;
    });
  }

  void _onTimeSlotSelected(Map<String, dynamic> timeData) {
    if (!timeData['isBooked']) {
      setState(() {
        _selectedTime = timeData['time'];
        _isSaving = true;
      });
    }
  }

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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveAppointment(_symptomsController.text);
                _symptomsController.clear();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvailableTimesGrid() {
    if (_selectedDay == null) return const Center(child: Text('No day selected'));

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
