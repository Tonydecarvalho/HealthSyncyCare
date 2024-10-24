import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthsyncycare/screens/doctor/home_screen_doctor.dart';
import 'package:healthsyncycare/screens/login_screen.dart';
import 'package:healthsyncycare/screens/patient/home_screen.dart';
import 'package:healthsyncycare/screens/privacy_policy.dart'; // Import the Privacy Policy screen
import 'package:intl/intl.dart'; // Import the intl package for DateFormat

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDateOfBirth;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;
  bool _isChecked = false; // Is user a patient?

  String? _selectedDoctorId; // Selected doctor id
  String? _selectedDoctorFirstName;
  String? _selectedDoctorLastName;
  String? _selectedDoctorAddress;
  String? _selectedDoctorPhoneNumber;

  List<Map<String, dynamic>> _doctors = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctors(); // Fetch available doctors
  }

  Future<void> _fetchDoctors() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();
      setState(() {
        _doctors = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'firstName': doc['firstName'],
                  'lastName': doc['lastName'],
                  'address': doc['address'],
                  'phone': doc['phone']
                })
            .toList();
      });
    } catch (e) {
      // Errors
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load doctors: $e')));
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleRepeatPasswordVisibility() {
    setState(() {
      _obscureRepeatPassword = !_obscureRepeatPassword;
    });
  }

  Future<void> _signUp() async {
    if (_passwordController.text != _repeatPasswordController.text) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      Map<String, dynamic> userData = {
        'gender': _selectedGender,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'dateOfBirth': _selectedDateOfBirth?.toIso8601String(),
        'city': _cityController.text,
        'postalCode': _postalCodeController.text,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text,
        'address': _addressController.text,
        'country': _countryController.text,
        'role': _isChecked ? "patient" : "doctor",
        'createdAt': DateTime.now(),
      };

      if (_isChecked) {
        userData['doctorId'] = _selectedDoctorId;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User Registered Successfully")),
      );

      // Reset form
      _clearFields();

      if (_isChecked) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MyHomePage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MyHomePageDoctor()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      } else {
        errorMessage = e.message ?? 'An error occurred';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearFields() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _cityController.clear();
    _postalCodeController.clear();
    _countryController.clear();
    _passwordController.clear();
    _repeatPasswordController.clear();
    setState(() {
      _selectedDoctorId = null;
      _selectedDateOfBirth = null;
      _selectedGender = null;
    });
  }

  void _navigateToLogin() {
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
  }

  void _navigateToPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
    );
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Sign Up"),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(26.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Already have an account?"),
                TextButton(
                  onPressed: _navigateToLogin,
                  child: Text(
                    "Login",
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: "Gender"),
              value: _selectedGender,
              items: ['Male', 'Female', 'Other'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue;
                });
              },
            ),
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(labelText: "First name"),
            ),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: "Last name"),
            ),
            TextFormField(
              readOnly: true,
              onTap: () => _selectDateOfBirth(context),
              decoration: InputDecoration(
                labelText: _selectedDateOfBirth == null
                    ? 'Date of Birth'
                    : 'Date of Birth: ${DateFormat.yMd().format(_selectedDateOfBirth!)}',
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(labelText: "City"),
            ),
            TextField(
              controller: _postalCodeController,
              decoration: InputDecoration(labelText: "Postal code"),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(labelText: "Street Address"),
            ),
            TextField(
              controller: _countryController,
              decoration: InputDecoration(labelText: "Country"),
            ),
            TextField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: "Phone"),
                keyboardType: TextInputType.phone),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
            ),
            TextField(
              controller: _repeatPasswordController,
              obscureText: _obscureRepeatPassword,
              decoration: InputDecoration(
                labelText: "Repeat Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureRepeatPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: _toggleRepeatPasswordVisibility,
                ),
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: _isChecked,
                  onChanged: (bool? newValue) {
                    setState(() {
                      _isChecked = newValue!;
                      // Reset selected doctor
                      if (!_isChecked) {
                        _selectedDoctorId = null;
                        _selectedDoctorFirstName = null;
                        _selectedDoctorLastName = null;
                        _selectedDoctorAddress = null;
                        _selectedDoctorPhoneNumber = null;
                      }
                    });
                  },
                ),
                Text("Patient"),
              ],
            ),

// Display DropdownButton if true
            if (_isChecked) ...[
              DropdownButton<String>(
                hint: Text("Select a Doctor"),
                value: _selectedDoctorId,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDoctorId = newValue;

                    // Update selected doctor information
                    var selectedDoctor = _doctors.firstWhere(
                      (doctor) => doctor['id'] == newValue,
                      orElse: () => {},
                    );

                    _selectedDoctorFirstName = selectedDoctor['firstName'];
                    _selectedDoctorLastName = selectedDoctor['lastName'];
                    _selectedDoctorAddress = selectedDoctor['address'];
                    _selectedDoctorPhoneNumber = selectedDoctor['phone'];
                  });
                },
                items: _doctors.map<DropdownMenuItem<String>>(
                    (Map<String, dynamic> doctor) {
                  return DropdownMenuItem<String>(
                    value: doctor['id'],
                    child: Text(doctor['firstName']),
                  );
                }).toList(),
              ),

              // Display selected doctor information
              if (_selectedDoctorFirstName != null) ...[
                SizedBox(height: 10.0),
                Text(
                  "Last name : $_selectedDoctorLastName",
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                Text(
                  "First name : $_selectedDoctorFirstName",
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Address : $_selectedDoctorAddress",
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Phone number : $_selectedDoctorPhoneNumber",
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
              ],
            ],
            SizedBox(height: 20.0),
            // Add Privacy Policy link here
            TextButton(
              onPressed: _navigateToPrivacyPolicy,
              child: Text(
                "Privacy Policy",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _signUp,
                    child: Text("Sign Up"),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }
}
