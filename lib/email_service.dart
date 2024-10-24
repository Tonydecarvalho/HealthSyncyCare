import 'package:http/http.dart'
    as http; // Importing HTTP package for making network requests
import 'dart:convert'; // Importing JSON package for encoding and decoding data
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importing dotenv package to load environment variables

Future<void> sendConfirmationEmail(
    String patientEmail, String patientName, String doctorEmail, String doctorName, DateTime appointmentDate) async {
  String apiKey =
      "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"; // Your Brevo API key (should ideally be stored securely)
      
  final url = Uri.parse("https://api.brevo.com/v3/smtp/email");

  final headers = {
    "Content-Type": "application/json",
    "api-key": apiKey,
  };

  // Email body for the patient
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

  // Email body for the doctor
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
    // Send email to patient
    final patientResponse = await http.post(url, headers: headers, body: patientEmailBody);

    if (patientResponse.statusCode == 201) {
      print('Patient email sent successfully');
    } else {
      print('Failed to send patient email: ${patientResponse.statusCode}');
      print('Response body: ${patientResponse.body}');
    }

    // Send email to doctor
    final doctorResponse = await http.post(url, headers: headers, body: doctorEmailBody);

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
