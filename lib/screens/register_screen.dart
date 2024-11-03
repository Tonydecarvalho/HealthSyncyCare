import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthsyncycare/screens/doctor/home_screen_doctor.dart';
import 'package:healthsyncycare/screens/login_screen.dart';
import 'package:healthsyncycare/screens/patient/home_screen.dart';
import 'package:healthsyncycare/screens/privacy_policy.dart';
import 'package:intl/intl.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  String? _selectedDoctorId;
  String? _selectedDoctorFirstName;
  String? _selectedDoctorLastName;
  String? _selectedDoctorAddress;
  String? _selectedDoctorPhoneNumber;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;
  bool _isChecked = false; // Est-ce un patient ?

  List<Map<String, dynamic>> _doctors = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctors(); // Récupérer les médecins
  }

  Future<void> _fetchDoctors() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();
      setState(() {
        _doctors = snapshot.docs.map((doc) => {
              'id': doc.id,
              'firstName': doc['firstName'],
              'lastName': doc['lastName'],
              'address': doc['address'],
              'phone': doc['phone']
            }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load doctors: $e')));
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

  Future<void> _signUp() async {
    // Validation du mot de passe
    if (_passwordController.text != _repeatPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Inscription avec Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
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

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set(userData);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User Registered Successfully")));

      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => _isChecked ? MyHomePage() : MyHomePageDoctor()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetDoctorSelection() {
    // Fonction pour réinitialiser la sélection du médecin
    setState(() {
      _selectedDoctorId = null;
      _selectedDoctorFirstName = null;
      _selectedDoctorLastName = null;
      _selectedDoctorAddress = null;
      _selectedDoctorPhoneNumber = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                Image.asset(
                  'assets/Healthsyncycare.png',
                  height: 100,
                ),
                SizedBox(height: 40),

                Text(
                  "Create Your Account",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                SizedBox(height: 8),
                Text(
                  "Fill out the form to get started",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 40),

                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("Gender"),
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
                SizedBox(height: 20),

                _buildTextField(_firstNameController, "First Name"),
                _buildTextField(_lastNameController, "Last Name"),
                TextFormField(
                  readOnly: true,
                  onTap: () => _selectDateOfBirth(context),
                  decoration: _inputDecoration(_selectedDateOfBirth == null ? 'Date of Birth' : 'Date of Birth: ${DateFormat.yMd().format(_selectedDateOfBirth!)}').copyWith(
                    suffixIcon: Icon(Icons.calendar_today, color: Colors.grey),
                  ),
                ),
                SizedBox(height: 20),

                _buildTextField(_emailController, "Email", TextInputType.emailAddress),
                _buildTextField(_phoneController, "Phone", TextInputType.phone),
                _buildTextField(_addressController, "Street Address"),
                _buildTextField(_cityController, "City"),
                _buildTextField(_postalCodeController, "Postal Code"),
                _buildTextField(_countryController, "Country"),

                _buildPasswordField(_passwordController, "Password", _obscurePassword, _togglePasswordVisibility),
                _buildPasswordField(_repeatPasswordController, "Repeat Password", _obscureRepeatPassword, _toggleRepeatPasswordVisibility),

                Row(
                  children: [
                    Checkbox(
                      value: _isChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          _isChecked = value!;
                          if (!_isChecked) _resetDoctorSelection();
                        });
                      },
                    ),
                    Text("Patient"),
                  ],
                ),

                if (_isChecked) ...[
                  DropdownButton<String>(
                    hint: Text("Select a Doctor"),
                    value: _selectedDoctorId,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDoctorId = newValue;
                        var selectedDoctor = _doctors.firstWhere((doctor) => doctor['id'] == newValue, orElse: () => {});
                        _selectedDoctorFirstName = selectedDoctor['firstName'];
                        _selectedDoctorLastName = selectedDoctor['lastName'];
                        _selectedDoctorAddress = selectedDoctor['address'];
                        _selectedDoctorPhoneNumber = selectedDoctor['phone'];
                      });
                    },
                    items: _doctors.map<DropdownMenuItem<String>>((Map<String, dynamic> doctor) {
                      String fullName = "${doctor['firstName']} ${doctor['lastName']}";
                      return DropdownMenuItem<String>(value: doctor['id'], child: Text(fullName));
                    }).toList(),
                  ),
                  if (_selectedDoctorFirstName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Column(
                        children: [
                          Divider(),
                          Text("Doctor Details:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("Name: $_selectedDoctorFirstName $_selectedDoctorLastName"),
                          Text("Address: $_selectedDoctorAddress"),
                          Text("Phone: $_selectedDoctorPhoneNumber"),
                        ],
                      ),
                    ),
                ],

                SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator()
                     : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account?", style: TextStyle(color: Colors.grey[700])),
                    TextButton(
                      onPressed: _navigateToLogin,
                      child: Text("Login", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _navigateToPrivacyPolicy,
                  child: Text("Privacy Policy", style: TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  Widget _buildTextField(TextEditingController controller, String label, [TextInputType keyboardType = TextInputType.text]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        controller: controller,
        decoration: _inputDecoration(label),
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, bool obscureText, void Function() toggleVisibility) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: _inputDecoration(label).copyWith(
          suffixIcon: IconButton(
            icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
            onPressed: toggleVisibility,
          ),
        ),
      ),
    );
  }
}
