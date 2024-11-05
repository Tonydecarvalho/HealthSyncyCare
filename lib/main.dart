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
import 'package:healthsyncycare/screens/register_screen.dart';
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
        initialRoute: '/login', // Initial route set to login page
        routes: {
          '/login': (context) => LoginPage(), // Add the login page route here
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

// Définition de MyAppState pour la gestion d'état
class MyAppState extends ChangeNotifier {
  // Ajoutez les propriétés et méthodes nécessaires ici
}
