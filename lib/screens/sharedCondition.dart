import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SharedConditionPage extends StatefulWidget {
  const SharedConditionPage({Key? key}) : super(key: key);

  @override
  _SharedConditionPageState createState() => _SharedConditionPageState();
}

class _SharedConditionPageState extends State<SharedConditionPage> {
  final TextEditingController _descriptionController = TextEditingController();
  List<Map<String, dynamic>> _symptoms = [];
  int? _selectedDuration;

  final List<int> _days = List.generate(30, (index) => index + 1); // Range of 1 to 30 days

  void _addSymptom() {
    final description = _descriptionController.text;
    final duration = _selectedDuration;

    if (description.isNotEmpty && duration != null) {
      setState(() {
        _symptoms.add({'description': description, 'duration': duration});
        _descriptionController.clear();
        _selectedDuration = null;
      });
    }
  }

void _saveConditions() async {
  if (_symptoms.isNotEmpty) {
    for (var symptom in _symptoms) {
      await FirebaseFirestore.instance.collection('conditions').add(symptom);
    }

    // Clear the symptoms list
    setState(() {
      _symptoms.clear();
    });

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Submission Successful"),
          content: const Text(
            "Your symptoms have been sent to your doctor. They will get back to you as soon as possible."
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Close the dialog and navigate back to home page
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Navigate back to the home page
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Share Your Symptoms"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "List your symptoms and specify their duration to share them with your doctor.",
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            // Symptom Description Text Field
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Symptom description',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 10),
            // Duration Dropdown
            DropdownButtonHideUnderline(
              child: DropdownButtonFormField<int>(
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
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                dropdownColor: Colors.white,
                items: _days.map((day) {
                  return DropdownMenuItem<int>(
                    value: day,
                    child: Text(
                      "$day days",
                      style: const TextStyle(color: Colors.black),
                    ),
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
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addSymptom,
              child: const Text('Add Symptom'),
            ),
            const SizedBox(height: 20),
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
                child: const Text('Submit Symptoms'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
