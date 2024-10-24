import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthsyncycare/screens/doctor/home_screen_doctor.dart';
import 'package:healthsyncycare/screens/login_screen.dart';
import 'package:healthsyncycare/screens/patient/home_screen.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;
  bool _isChecked = false;

  String? _selectedDoctorId; // Selected doctor id
  String? _selectedDoctorFirstName;
  String? _selectedDoctorLastName;
  String? _selectedDoctorAddress;
  String? _selectedDoctorPhoneNumber;

  List<Map<String, dynamic>> _doctors = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    // Fetch available doctors
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
        'name': _nameController.text,
        'gender': _genderController.text,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'dateOfBirth': _dateOfBirthController.text,
        'city': _cityController.text,
        'postalCode': _postalCodeController.text,
        'email': _emailController.text.trim(),
        'address': _addressController.text,
        'country': _countryController.text,
        'phone': _phoneController.text,
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
      _nameController.clear();
      _genderController.clear();
      _firstNameController.clear();
      _lastNameController.clear();
      _dateOfBirthController.clear();
      _cityController.clear();
      _postalCodeController.clear();
      _emailController.clear();
      _addressController.clear();
      _countryController.clear();
      _phoneController.clear();
      _passwordController.clear();
      _repeatPasswordController.clear();

      setState(() {
        _selectedDoctorId = null;
      });

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

  void _navigateToLogin() {
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Sign Up"),
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
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: _genderController,
              decoration: InputDecoration(labelText: "Gender"),
            ),
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(labelText: "First name"),
            ),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: "Last name"),
            ),
            TextField(
              controller: _dateOfBirthController,
              decoration: InputDecoration(labelText: "Date of birth"),
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
              decoration: InputDecoration(labelText: "Address"),
            ),
            TextField(
              controller: _countryController,
              decoration: InputDecoration(labelText: "Country"),
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: "Phone"),
            ),
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
    _nameController.dispose();
    _genderController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }
}
