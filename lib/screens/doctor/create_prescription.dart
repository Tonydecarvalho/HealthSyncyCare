import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePrescriptionPage extends StatefulWidget {
  final String patientId;
  final String conditionId;

  // Constructor for initializing the widget with patient and condition identifiers.
  CreatePrescriptionPage({required this.patientId, required this.conditionId});

  @override
  _CreatePrescriptionPageState createState() => _CreatePrescriptionPageState();
}

class _CreatePrescriptionPageState extends State<CreatePrescriptionPage> {
  // Form key to manage form state.
  final _formKey = GlobalKey<FormState>();
  // Text editing controllers to control text fields.
  final _quantityController = TextEditingController();
  final _noticeController = TextEditingController();

  // List to store names of drugs fetched from Firestore.
  List<String> _drugNames = [];
  // Currently selected drug in the dropdown.
  String? _selectedDrug;
  // List to store drugs added to the prescription.
  List<Map<String, dynamic>> _prescriptionDrugs = [];
  // Current doctor's user ID.
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _fetchDrugs();
    _fetchDoctorId();
  }

  // Fetches drug names from Firestore to populate the dropdown menu.
  Future<void> _fetchDrugs() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('drugs').get();
    final drugs =
        querySnapshot.docs.map((doc) => doc['name'].toString()).toList();
    setState(() {
      _drugNames = drugs;
    });
  }

  // Retrieves the current user's ID from FirebaseAuth.
  Future<void> _fetchDoctorId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _doctorId = user.uid;
      });
    }
  }

  // Adds a drug with its details to the prescription list.
  void _addDrugToPrescription() {
    if (_selectedDrug != null && _formKey.currentState!.validate()) {
      setState(() {
        _prescriptionDrugs.add({
          'drug': _selectedDrug,
          'quantity': _quantityController.text,
          'notice': _noticeController.text,
        });
        _quantityController.clear();
        _noticeController.clear();
        _selectedDrug = null;
      });
    }
  }

  // Saves the prescription to Firestore using a batch operation.
  Future<void> _savePrescription() async {
    if (_doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Doctor ID is missing.')),
      );
      return;
    }

    final prescriptionRef = FirebaseFirestore.instance.collection('prescriptions').doc();
    final conditionRef = FirebaseFirestore.instance.collection('conditions').doc(widget.conditionId);
    final batch = FirebaseFirestore.instance.batch();

    batch.set(prescriptionRef, {
      'patientId': widget.patientId,
      'doctorId': _doctorId,
      'conditionId': widget.conditionId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    for (var drug in _prescriptionDrugs) {
      final drugRef = prescriptionRef.collection('drug').doc();
      batch.set(drugRef, {
        'drug': drug['drug'],
    'quantity': drug['quantity'].toString(), 
        'notice': drug['notice'],
      });
    }

    batch.update(conditionRef, {
      'hasPrescription': true,
    });

    await batch.commit();

    setState(() {
      _prescriptionDrugs.clear();
      _selectedDrug = null;
    });

    _showConfirmationDialog();
  }

  // Shows a confirmation dialog after saving a prescription.
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Prescription Saved'),
          content: Text('The prescription has been successfully saved.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Closes the dialog.
                Navigator.of(context).popUntil((route) => route.settings.name == '/patients conditions'); // Returns to the patient conditions page.
              },
              child: Text('OK'),
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
        title: Text('Create Prescription', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: const Color(0xFF176139),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedDrug,
                hint: Text('Select a drug'),
                items: _drugNames.map((drug) {
                  return DropdownMenuItem(
                    value: drug,
                    child: Text(drug),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDrug = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a drug' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a quantity'
                    : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _noticeController,
                decoration: InputDecoration(labelText: 'Notice'),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a notice'
                    : null,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addDrugToPrescription,
                child: Text('Add Drug to Prescription'),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _prescriptionDrugs.length,
                  itemBuilder: (context, index) {
                    final drug = _prescriptionDrugs[index];
                    return ListTile(
                      title: Text(drug['drug']),
                      subtitle: Text(
                          'Quantity: ${drug['quantity']}, Notice: ${drug['notice']}'),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                    _prescriptionDrugs.isNotEmpty ? _savePrescription : null,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Color(0xFF176139),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save Prescription', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 10.0),
            ],
          ),
        ),
      ),
    );
  }
}
