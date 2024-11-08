import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:healthsyncycare/screens/patient/home_screen.dart';
import 'package:healthsyncycare/screens/patient/book_appointment.dart';
import 'package:healthsyncycare/screens/patient/view_appointment.dart';
import 'package:healthsyncycare/screens/doctor/view_appointment.dart';
import 'package:healthsyncycare/screens/doctor/home_screen_doctor.dart';
import 'package:healthsyncycare/screens/login_screen.dart';
import 'package:healthsyncycare/screens/doctor/condition_details.dart';
import 'package:healthsyncycare/screens/doctor/condition_list.dart';
import 'package:healthsyncycare/screens/patient/sharedCondition.dart';
import 'package:healthsyncycare/screens/doctor/create_prescription.dart';
import 'package:healthsyncycare/screens/patient/condition_list.dart';
import 'package:healthsyncycare/screens/patient/condition_details.dart';
import 'package:healthsyncycare/screens/patient/prescriptions_details.dart';
import 'package:healthsyncycare/screens/patient/prescriptions_list.dart';
import 'package:healthsyncycare/screens/doctor/prescription_list.dart';
import 'package:healthsyncycare/screens/patient/profile.dart';
import 'package:healthsyncycare/screens/doctor/profile.dart';
import 'package:healthsyncycare/screens/doctor/prescription_details.dart';
import 'package:healthsyncycare/screens/doctor/patient_list.dart';
import 'package:healthsyncycare/screens/doctor/patient_details.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Ensure Firebase is initialized
  
  // Load the .env file before running the app
  try {
    await dotenv.load(fileName: ".env");
    print("Environment variables loaded successfully");
  } catch (e) {
    print("Error loading .env file: $e");
  }

  runApp(MyApp()); // Replace with your main app widget
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
        initialRoute: '/login', // Initial route set to login page
        // Add the routes for the different pages here 
        routes: {
          '/login': (context) => LoginPage(), 
          '/home': (context) => MyHomePage(),
          '/bookAppointment': (context) => BookAppointmentPage(),
          '/viewPatientAppointment': (context) => ViewPatientAppointmentPage(),
          '/viewDoctorAppointment': (context) => ViewDoctorAppointmentPage(),
          '/sharedCondition': (context) => SharedConditionPage(),
          '/patients conditions': (context) => PatientsConditions(),
          '/patient condition details': (context) => PatientConditionDetails(),
          '/doctor': (context) => MyHomePageDoctor(),
          '/patients conditions patient': (context) => PatientsConditionsPatient(),
          '/patient condition details patient': (context) => PatientConditionDetailsPatient(),
          '/prescriptions list': (context) => PatientPrescriptionsPage(),
          '/prescriptions details': (context) => PrescriptionDetailsPage(),
          '/doctor prescriptions': (context) => DoctorPrescriptionsPage(),
          '/doctor prescriptions list': (context) => DoctorPrescriptionsHistoryPage(),
          '/profile': (context) => ProfilePage(),
          '/doctor profile': (context) => DoctorProfilePage(),
          '/patients list': (context) => DoctorPatientListPage(),
          '/patient details': (context) => PatientDetailsPage(patientId: ''),
          
        },
        // Add the onGenerateRoute property to handle named routes with arguments
        onGenerateRoute: (settings) {
          if (settings.name == '/create prescription') {
            final args = settings.arguments as Map<String, String>;

            return MaterialPageRoute(
              builder: (context) => CreatePrescriptionPage(
                patientId: args['patientId']!,
                conditionId: args['conditionId']!,
              ),
            );
          }
          return null;
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// Create a class to hold the state of the app
class MyAppState extends ChangeNotifier {
}
