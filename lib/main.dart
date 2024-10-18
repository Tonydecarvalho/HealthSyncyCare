import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:healthsyncycare/screens/home_screen.dart';
import 'package:healthsyncycare/screens/appointment.dart';
import 'package:healthsyncycare/screens/home_screen_doctor.dart';
import 'package:healthsyncycare/screens/login_screen.dart';
import 'package:healthsyncycare/screens/patient_condition_details.dart';
import 'package:healthsyncycare/screens/patients_conditions_doctor.dart';
import 'package:healthsyncycare/screens/sharedCondition.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Healthsyncycare',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        ),
        home: LoginPage(),
        routes: {
          '/home': (context) => MyHomePage(),
          '/appointment': (context) => AppointmentPage(
                userId: 'user1',
              ),
          '/sharedCondition': (context) => SharedConditionPage(),
          '/patients conditions': (context) => PatientsConditions(),
          '/patient condition details': (context) => PatientConditionDetails()
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {}
