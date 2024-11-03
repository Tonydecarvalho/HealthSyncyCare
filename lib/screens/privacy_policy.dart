import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyPolicyPage extends StatefulWidget {
  @override
  _PrivacyPolicyPageState createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  Map<String, dynamic>? privacyPolicyData;

  @override
  void initState() {
    super.initState();
    _loadPrivacyPolicy();
  }

  // Function to load privacy policy JSON data
  Future<void> _loadPrivacyPolicy() async {
    final String response =
        await rootBundle.loadString('assets/privacy_policy.json');
    final data = await json.decode(response);
    setState(() {
      privacyPolicyData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Color(0xFF176139), // Use the green color for the app bar
        title: Text('Privacy Policy'),
      ),
      body: privacyPolicyData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF176139), // Green accent for heading
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Last Updated: ${privacyPolicyData?['last_updated'] ?? ''}',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 20),
                  ..._buildPrivacyPolicyContent(), // Load and display the policy content
                ],
              ),
            ),
    );
  }

  List<Widget> _buildPrivacyPolicyContent() {
    return privacyPolicyData?['content']
            ?.map<Widget>(
              (paragraph) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  paragraph,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5, // Line height for better readability
                    color: Colors.black87,
                  ),
                ),
              ),
            )
            .toList() ??
        [];
  }
}
