import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class AppointmentPage extends StatefulWidget {
  final String userId; // User ID as a parameter

  const AppointmentPage({super.key, required this.userId}); // Constructor

  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTime;
  bool _isSaving = false;
  bool _isLoading = true; // Loading indicator
  final Map<DateTime, List<Map<String, dynamic>>> _availableTimes = {};

  @override
  void initState() {
    super.initState();
    _fetchAvailableTimes();
  }

  Future<void> _fetchAvailableTimes() async {
    setState(() => _isLoading = true); // Start loading
    try {
      final userDoc = FirebaseFirestore.instance.collection('User').doc(widget.userId);
      final appointmentsSnapshot = await userDoc.collection('appointment').get();

      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        final appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
        final isBooked = true;

        if (!_availableTimes.containsKey(appointmentDate)) {
          _availableTimes[appointmentDate] = [];
        }

        _availableTimes[appointmentDate]?.add({
          'time': appointmentDate.toLocal().toString().split(" ")[1].substring(0, 5),
          'isBooked': isBooked,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching appointments. Please try again later: $e")),
      );
    } finally {
      setState(() => _isLoading = false); // Stop loading
    }
  }

  Future<void> _saveAppointment() async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('User').doc(widget.userId);

      await userDoc.collection('appointment').add({
        'appointmentDate': Timestamp.fromDate(_selectedDay!),
        'time': _selectedTime,
        'status': 'booked',
      });

      final timesForDay = _availableTimes[DateTime.utc(
          _selectedDay!.year,
          _selectedDay!.month,
          _selectedDay!.day)];
      final timeIndex = timesForDay!
          .indexWhere((time) => time['time'] == _selectedTime);
      if (timeIndex != -1) {
        timesForDay[timeIndex]['isBooked'] = true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment saved and marked as booked!')),
      );

      setState(() {
        _isSaving = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving appointment. Please try again later: $e")),
      );
    }
  }

  List<Map<String, dynamic>> _getAvailableTimesForDay(DateTime day) {
    return _availableTimes[DateTime.utc(day.year, day.month, day.day)] ?? [];
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
          content: const Text('Are you sure you want to save this appointment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveAppointment();
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
    if (_getAvailableTimesForDay(_selectedDay!).isEmpty) {
      return const Center(child: Text('No available times for this day.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Available times for ${_selectedDay!.toLocal().day}-${_selectedDay!.toLocal().month}-${_selectedDay!.toLocal().year}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, childAspectRatio: 2),
            itemCount: _getAvailableTimesForDay(_selectedDay!).length,
            itemBuilder: (context, index) {
              final timeData = _getAvailableTimesForDay(_selectedDay!)[index];

              return GestureDetector(
                onTap: () => _onTimeSlotSelected(timeData),
                child: Container(
                  padding: const EdgeInsets.all(1),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: timeData['isBooked'] ? Colors.redAccent : Colors.lightGreen,
                    border: Border.all(
                      color: _selectedTime == timeData['time'] && !timeData['isBooked']
                          ? Colors.green.shade900
                          : Colors.transparent,
                      width: 4,
                    ),
                    boxShadow: _selectedTime == timeData['time']
                        ? [const BoxShadow(color: Colors.black26, blurRadius: 6)]
                        : [],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(timeData['isBooked'] ? Icons.lock : Icons.access_time, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(timeData['time'], style: const TextStyle(fontSize: 18, color: Colors.white), textAlign: TextAlign.center),
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
            iconColor: Colors.green,
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
          onPressed: () {}, // Add navigation logic if needed
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
                  onFormatChanged: (format) => setState(() => _calendarFormat = format),
                  onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: _selectedDay == null
                      ? const Center(child: Text('Please select a day'))
                      : _buildAvailableTimesGrid(),
                ),
                if (_isSaving) _buildSaveButton(),
              ],
            ),
    );
  }
}
