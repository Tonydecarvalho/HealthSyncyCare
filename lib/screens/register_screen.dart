import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthsyncycare/screens/login_screen.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;
  bool _isChecked = false;

  String? _selectedDoctorId; // Selected doctor id
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
            .map((doc) => {'id': doc.id, 'name': doc['name']})
            .toList();
      });
    } catch (e) {
      // Fetch errors
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
        'email': _emailController.text.trim(),
        'address': _addressController.text,
        'role': _isChecked ? "patient" : "doctor",
        'createdAt': DateTime.now(),
      };

      if (_isChecked) {
        userData['doctorId'] = _selectedDoctorId;
      }

      // Add information
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User Registered Successfully")),
      );

      // Reset form
      _nameController.clear();
      _emailController.clear();
      _addressController.clear();
      _passwordController.clear();
      _repeatPasswordController.clear();
      setState(() {
        _selectedDoctorId = null;
      });
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
      body: Padding(
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
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(labelText: "Address"),
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
            Row(children: [
              Checkbox(
                value: _isChecked,
                onChanged: (bool? newValue) {
                  setState(() {
                    _isChecked = newValue!;
                  });
                },
              ),
              Text("Patient"),
            ]),
            if (_isChecked) ...[
              DropdownButton<String>(
                hint: Text("Select a Doctor"),
                value: _selectedDoctorId,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDoctorId = newValue;
                  });
                },
                items: _doctors.map<DropdownMenuItem<String>>(
                    (Map<String, dynamic> doctor) {
                  return DropdownMenuItem<String>(
                    value: doctor['id'],
                    child: Text(doctor['name']),
                  );
                }).toList(),
              ),
            ],
            SizedBox(height: 20),
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
    _emailController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }
}
