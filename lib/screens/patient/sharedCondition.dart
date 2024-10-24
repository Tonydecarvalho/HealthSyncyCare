import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SharedConditionPage extends StatefulWidget {
  const SharedConditionPage({Key? key}) : super(key: key);

  @override
  _SharedConditionPageState createState() => _SharedConditionPageState();
}

class _SharedConditionPageState extends State<SharedConditionPage> {
  final TextEditingController _descriptionController = TextEditingController();
  List<Map<String, dynamic>> _symptoms = [];
  int? _selectedDuration;
  final List<int> _days = List.generate(30, (index) => index + 1); // 1 to 30 days

  void _addSymptom() {
    final description = _descriptionController.text;
    final duration = _selectedDuration;
    final timestamp = Timestamp.now(); // Current date and time

    if (description.isNotEmpty && duration != null) {
      setState(() {
        _symptoms.add({
          'description': description,
          'duration': duration,
          'timestamp': timestamp,
        });
        _descriptionController.clear();
        _selectedDuration = null;
      });
    }
  }

  Future<void> _saveConditions() async {
    if (_symptoms.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: User not logged in.')),
      );
      return;
    }

    final patientId = user.uid;
    final conditionRef = FirebaseFirestore.instance.collection('conditions').doc();
    final timestamp = Timestamp.now();

    await conditionRef.set({
      'patientId': patientId,
      'timestamp': timestamp,
      'hasPrescription': false, // Initialement sans prescription
    });

    for (var symptom in _symptoms) {
      await conditionRef.collection('symptoms').add(symptom);
    }

    setState(() {
      _symptoms.clear();
    });

    _showSubmissionSuccessDialog();
  }

  void _showSubmissionSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Submission Successful"),
          content: Text("Your symptoms have been sent to your doctor."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Navigate back to the home page
              },
              child: Text("OK"),
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
        title: Text("Share Your Symptoms"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "List your symptoms and specify their duration to share them with your doctor.",
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 20),
            // Symptom Description Text Form Field (Multi-line input)
            TextFormField(
              controller: _descriptionController,
              maxLines: 5, // Allow up to 5 lines for long text input
              decoration: InputDecoration(
                labelText: 'Symptom description',
                alignLabelWithHint: true, // Aligns label with the top of the box
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            SizedBox(height: 10),
            // Duration Dropdown
            DropdownButtonFormField<int>(
              value: _selectedDuration,
              decoration: InputDecoration(
                labelText: 'Duration in days',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
              style: TextStyle(color: Colors.black87, fontSize: 16),
              dropdownColor: Colors.white,
              items: _days.map((day) {
                return DropdownMenuItem<int>(
                  value: day,
                  child: Text("$day days", style: TextStyle(color: Colors.black)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDuration = value;
                });
              },
              isExpanded: false,
              menuMaxHeight: 200,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addSymptom,
              child: Text('Add Symptom'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _symptoms.length,
                itemBuilder: (context, index) {
                  final symptom = _symptoms[index];
                  return ListTile(
                    title: Text(symptom['description']),
                    subtitle: Text("Duration: ${symptom['duration']} days"),
                  );
                },
              ),
            ),
            if (_symptoms.isNotEmpty)
              ElevatedButton(
                onPressed: _saveConditions,
                child: Text('Submit Symptoms'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size.fromHeight(50),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
