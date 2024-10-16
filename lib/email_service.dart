import 'package:http/http.dart'
    as http; // Importing HTTP package for making network requests
import 'dart:convert'; // Importing JSON package for encoding and decoding data
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importing dotenv package to load environment variables

// Function to send a confirmation email using Brevo API
Future<void> sendConfirmationEmail(
    String email, String name, DateTime appointmentDate) async {
  String apiKey =
      "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"; // Your Brevo API key (should ideally be stored securely)

  final url = Uri.parse(
      "https://api.brevo.com/v3/smtp/email"); // Brevo API URL for sending SMTP emails

  final headers = {
    "Content-Type": "application/json", // Setting content type to JSON
    "api-key": apiKey, // Brevo API key in the header
  };

  final body = jsonEncode({
    "sender": {
      "email": "bhe075@myy.haaga-helia.fi"
    }, // The email address of the sender
    "to": [
      {"email": email, "name": name} // Recipient's email and name
    ],
    "subject": "Appointment Confirmation", // Email subject
    "htmlContent": """
      <h3>Dear $name,</h3>
      <p>Your appointment is successfully booked for ${appointmentDate.toLocal().toString()}.</p>
      <p>Thank you!</p>
    """
  });

  try {
    final response = await http.post(url,
        headers: headers, body: body); // Sending the POST request to Brevo API

    if (response.statusCode == 201) {
      print(
          'Email sent successfully'); // Success message on successful email send
    } else {
      print(
          'Failed to send email: ${response.body}'); // Error message with response body if sending fails
    }
  } catch (e) {
    print(
        'Error sending email: $e'); // Catching and printing any exceptions during the request
  }
}
