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
import 'package:firebase_core/firebase_core.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyAkgqV7qTBF-Fh7ZgT2Sponbbs2yJ-OvdI",
      authDomain: "healthsyncycare.firebaseapp.com",
      projectId: "healthsyncycare",
      storageBucket: "healthsyncycare.appspot.com",
      messagingSenderId: "679874674301",
      appId: "1:679874674301:web:bf07bbfce91a715c697b14",
      measurementId: "G-7LEGTKC5N0",
    ),
  );
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
          '/patient condition details': (context) => PatientConditionDetails(),
          '/doctor': (context) => MyHomePageDoctor(),
          '/login': (context) => LoginPage()
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {}
