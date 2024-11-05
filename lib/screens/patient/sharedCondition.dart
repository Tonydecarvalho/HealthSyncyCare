import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SharedConditionPage extends StatefulWidget {
  const SharedConditionPage({Key? key}) : super(key: key);
  @override
  _SharedConditionPageState createState() => _SharedConditionPageState();
}

class _SharedConditionPageState extends State<SharedConditionPage> {
  final TextEditingController _descriptionController = TextEditingController(); // Text controller for symptom description
  List<Map<String, dynamic>> _symptoms = []; // List of symptoms
  int? _selectedDuration; // Duration of the symptom
  final List<int> _days = List.generate(30, (index) => index + 1); // 1 to 30 days

  void _addSymptom() {
    final description = _descriptionController.text; // Get the symptom description
    final duration = _selectedDuration; // Get the duration
    final timestamp = Timestamp.now(); // Current date and time

    // Check if the description is not empty and the duration is selected
    if (description.isNotEmpty && duration != null) {
      // Add the symptom to the list
      setState(() {
        _symptoms.add({
          'description': description,
          'duration': duration,
          'timestamp': timestamp,
        });
        // Clear the text field and reset the duration
        _descriptionController.clear();
        _selectedDuration = null;
      });
    }
  }

  // Save the symptoms to the database
  Future<void> _saveConditions() async {
    if (_symptoms.isEmpty) return;
    // Get the current user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: User not logged in.')),
      );
      return;
    }
    // Get the patient ID, create a new condition document, and add the symptoms
    final patientId = user.uid;
    final conditionRef = FirebaseFirestore.instance.collection('conditions').doc();
    final timestamp = Timestamp.now();
    // Set the condition document with the patient ID, timestamp, and no prescription
    await conditionRef.set({
      'patientId': patientId,
      'timestamp': timestamp,
      'hasPrescription': false, // Initialement sans prescription
    });
    // Add each symptom to the condition document
    for (var symptom in _symptoms) {
      await conditionRef.collection('symptoms').add(symptom);
    }
    // Clear the symptoms list
    setState(() {
      _symptoms.clear();
    });

    _showSubmissionSuccessDialog();
  }

  // Show a dialog to confirm the submission
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

  // Build the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Share Your Symptoms", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF176139),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
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
            // Duration Dropdown for selecting the number of days
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
            // Add Symptom Button
            ElevatedButton(
              onPressed: _addSymptom,
              child: Text('Add Symptom'),
            ),
            SizedBox(height: 20),
            // List of Symptoms added by the user (ListView)
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
            // Submit Symptoms Button (Enabled only if symptoms are added)
            if (_symptoms.isNotEmpty)
              ElevatedButton(
                onPressed: _saveConditions,
                style: ElevatedButton.styleFrom(
                   backgroundColor: Color(0xFF176139),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              child: const Text('Submit Symptoms', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}
