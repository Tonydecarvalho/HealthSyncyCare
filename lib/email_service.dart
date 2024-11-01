import 'package:http/http.dart'
    as http; // HTTP package for sending network requests
import 'dart:convert'; // Package for encoding/decoding JSON data
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Package to load environment variables securely
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore for cloud-based database operations

/// Sends a confirmation email to both the patient and the doctor after an appointment is booked.
///
/// [patientEmail] - The email of the patient
/// [patientName] - The name of the patient
/// [doctorEmail] - The email of the doctor
/// [doctorName] - The name of the doctor
/// [appointmentDate] - The date and time of the appointment
Future<void> sendConfirmationEmail(String patientEmail, String patientName,
    String doctorEmail, String doctorName, DateTime appointmentDate) async {
  String apiKey = dotenv.env['BREVO_API_KEY'] ?? '';
  final url = Uri.parse("https://api.brevo.com/v3/smtp/email");

  // Define headers for the API request
  final headers = {
    "Content-Type": "application/json",
    "api-key": apiKey,
  };

  // Email content for the patient
  final patientEmailBody = jsonEncode({
    "sender": {"email": "bhe075@myy.haaga-helia.fi"},
    "to": [
      {"email": patientEmail, "name": patientName}
    ],
    "subject": "Appointment Confirmation",
    "htmlContent": """
      <h3>Dear $patientName,</h3>
      <p>Your appointment is successfully booked for ${appointmentDate.toLocal().toString()}.</p>
      <p>Thank you!</p>
    """
  });

  // Email content for the doctor
  final doctorEmailBody = jsonEncode({
    "sender": {"email": "bhe075@myy.haaga-helia.fi"},
    "to": [
      {"email": doctorEmail, "name": doctorName}
    ],
    "subject": "New Appointment Scheduled",
    "htmlContent": """
      <h3>Dear Dr. $doctorName,</h3>
      <p>An appointment has been scheduled with the following details:</p>
      <ul>
        <li><strong>Patient Name:</strong> $patientName</li>
        <li><strong>Appointment Date:</strong> ${appointmentDate.toLocal().toString()}</li>
      </ul>
      <p>Thank you!</p>
    """
  });

  try {
    // Send the email to the patient
    final patientResponse =
        await http.post(url, headers: headers, body: patientEmailBody);

    if (patientResponse.statusCode == 201) {
      print('Patient email sent successfully');
    } else {
      print('Failed to send patient email: ${patientResponse.statusCode}');
      print('Response body: ${patientResponse.body}');
    }

    // Send the email to the doctor
    final doctorResponse =
        await http.post(url, headers: headers, body: doctorEmailBody);

    if (doctorResponse.statusCode == 201) {
      print('Doctor email sent successfully');
    } else {
      print('Failed to send doctor email: ${doctorResponse.statusCode}');
      print('Response body: ${doctorResponse.body}');
    }
  } catch (e) {
    print('Error sending email: $e');
  }
}

/// Checks Firestore for upcoming appointments within the next week and sends reminder emails.
/// Marks reminders as sent in Firestore to avoid sending duplicates.
Future<void> checkAndSendReminders() async {
  final now = DateTime.now();
  final oneWeekFromNow = now.add(Duration(days: 7));
  print("Checking for reminders...");

  try {
    // Query Firestore for appointments within the next week that haven't had reminders sent
    final querySnapshot = await FirebaseFirestore.instance
        .collection('BookAppointments')
        .where('appointmentDate', isGreaterThanOrEqualTo: now)
        .where('appointmentDate', isLessThanOrEqualTo: oneWeekFromNow)
        .where('reminderSent', isEqualTo: false)
        .get();

    print("Found ${querySnapshot.docs.length} appointments needing reminders.");

    // Loop through each appointment and send reminders
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final DateTime appointmentDate =
          (data['appointmentDate'] as Timestamp).toDate();
      final patientId = data['patientId'];
      final doctorId = data['doctorId'];

      print("Sending reminder for appointment on $appointmentDate...");

      // Fetch patient and doctor details from Firestore
      final patientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get();
      final doctorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .get();

      final patientEmail = patientDoc['email'];
      final patientName =
          '${patientDoc['firstName']} ${patientDoc['lastName']}';
      final doctorName = '${doctorDoc['firstName']} ${doctorDoc['lastName']}';

      // Send reminder email to the patient
      await sendReminderEmail(
          patientEmail, patientName, doctorName, appointmentDate);

      // Update the Firestore document to mark the reminder as sent
      await doc.reference.update({'reminderSent': true});
      print(
          'Reminder sent to $patientName for appointment on $appointmentDate');
    }
  } catch (e) {
    print('Error checking and sending reminders: $e');
  }
}

/// Sends a reminder email to the patient about their upcoming appointment.
///
/// [patientEmail] - The email address of the patient
/// [patientName] - The name of the patient
/// [doctorName] - The name of the doctor
/// [appointmentDate] - The date and time of the appointment
Future<void> sendReminderEmail(String patientEmail, String patientName,
    String doctorName, DateTime appointmentDate) async {
  String apiKey = dotenv.env['BREVO_API_KEY'] ?? '';
  final url = Uri.parse("https://api.brevo.com/v3/smtp/email");

  // Define headers for the API request
  final headers = {
    "Content-Type": "application/json",
    "api-key": apiKey,
  };

  // Reminder email content
  final reminderEmailBody = jsonEncode({
    "sender": {"email": "bhe075@myy.haaga-helia.fi"},
    "to": [
      {"email": patientEmail, "name": patientName}
    ],
    "subject": "Upcoming Appointment Reminder",
    "htmlContent": """
      <h3>Dear $patientName,</h3>
      <p>This is a reminder of your upcoming appointment with Dr. $doctorName.</p>
      <p><strong>Appointment Date:</strong> ${appointmentDate.toLocal().toString()}</p>
      <p>Looking forward to seeing you then.</p>
      <p>Thank you!</p>
    """
  });

  try {
    // Send the reminder email
    final response =
        await http.post(url, headers: headers, body: reminderEmailBody);

    if (response.statusCode == 201) {
      print('Reminder email sent successfully to $patientName');
    } else {
      print('Failed to send reminder email: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (e) {
    print('Error sending reminder email: $e');
  }
}
