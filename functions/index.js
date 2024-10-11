// Import Firebase Functions
const functions = require('firebase-functions');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');

// Import Firebase Admin to interact with Firestore
const admin = require('firebase-admin');
admin.initializeApp();

// Import SendGrid to send emails
const sgMail = require('@sendgrid/mail');
sgMail.setApiKey('YOUR_SENDGRID_API_KEY'); // Replace with your SendGrid API key

// Define a Firestore trigger to send email when a new booking is added
exports.sendConfirmationEmail = onDocumentCreated('BookAppointments/{appointmentId}', async (event) => {
  const appointmentData = event.data.data();

  if (!appointmentData) {
    console.error('No appointment data found');
    return null;
  }

  // Extract patientId from appointment data
  const patientId = appointmentData.patientId;
  const appointmentDate = appointmentData.appointmentDate.toDate();

  if (!patientId) {
    console.error('No patient ID found');
    return null;
  }

  try {
    // Retrieve patient email from users collection
    const userDoc = await admin.firestore().collection('users').doc(patientId).get();

    if (!userDoc.exists) {
      console.error('No user found for patient ID:', patientId);
      return null;
    }

    const patientEmail = userDoc.data().email;

    if (!patientEmail) {
      console.error('No email found for patient ID:', patientId);
      return null;
    }

    // Construct the email message
    const msg = {
      to: patientEmail, // Recipient email
      from: 'your_email@example.com', // Your verified SendGrid email
      subject: 'Appointment Confirmation',
      text: `Hello, your appointment is confirmed for ${appointmentDate}.`,
      html: `<strong>Hello, your appointment is confirmed for ${appointmentDate}.</strong>`,
    };

    // Send email using SendGrid
    await sgMail.send(msg);
    console.log('Confirmation email sent successfully');
  } catch (error) {
    console.error('Error sending confirmation email:', error);
  }

  return null;
});






/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
