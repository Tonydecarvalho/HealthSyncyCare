import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PatientConditionDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final DocumentSnapshot conditionData =
        ModalRoute.of(context)!.settings.arguments as DocumentSnapshot;

    final String description = conditionData['description'];
    final Timestamp timestamp = conditionData['timestamp'];
    final int duration = conditionData['duration'];

    final String formattedDate =
        DateFormat('yyyy.MM.dd - kk:mm').format(timestamp.toDate());

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF008000),
        title: const Text(
          'Patient condition details',
          style: TextStyle(
            fontSize: 23.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24.0),
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 11.0, horizontal: 12.0),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Color(0xFFFFFFFF),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0x339E9E9E),
                        spreadRadius: 4,
                        blurRadius: 4,
                        offset: Offset(0.0, 4.0))
                  ]),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Color(0xFF008000)),
                  const SizedBox(width: 8.0),
                  Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF000000),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14.0),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 20.0,
                  color: Color(0xFF008000),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 11.0, horizontal: 12.0),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Color(0xFFFFFFFF),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0x339E9E9E),
                        spreadRadius: 4,
                        blurRadius: 4,
                        offset: Offset(0.0, 4.0))
                  ]),
              child: Row(
                children: [
                  Icon(Icons.medical_services, color: Color(0xFF008000)),
                  const SizedBox(width: 8.0),
                  Text(
                    'Condition',
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF000000),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14.0),
            Padding(
              padding: const EdgeInsets.only(left: 25.0),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Color(0xFF008000), width: 1.7),
                ),
                child: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 18.0,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 11.0, horizontal: 12.0),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Color(0xFFFFFFFF),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0x339E9E9E),
                        spreadRadius: 4,
                        blurRadius: 44,
                        offset: Offset(0.0, 4.0))
                  ]),
              child: Row(
                children: [
                  Icon(Icons.timer, color: Color(0xFF008000)),
                  const SizedBox(width: 8.0),
                  Text(
                    'Duration',
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF000000),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14.0),
            Padding(
              padding: const EdgeInsets.only(left: 25.0),
              child: Text(
                '$duration days',
                style: const TextStyle(
                  fontSize: 20.0,
                  color: Color(0xFF008000),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            print("Open prescription page");
          },
          backgroundColor: const Color(0xFF008000),
          icon: const Icon(
            Icons.local_pharmacy,
            size: 30.0,
            color: Color(0XFFFFFFFF),
          ),
          label: const Text(
            'Prescription',
            style: TextStyle(fontSize: 18.0, color: Color(0xFFFFFFFF)),
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
