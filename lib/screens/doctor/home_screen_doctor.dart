import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyHomePageDoctor extends StatefulWidget {
  @override
  MyHomePageDoctorState createState() => MyHomePageDoctorState();
}

class MyHomePageDoctorState extends State<MyHomePageDoctor> {
  String userName = '';

  @override
  void initState() {
    super.initState();
    _getUserName();
  }

  Future<void> _getUserName() async {
      final user = FirebaseAuth.instance.currentUser;
    if(user != null) {
      final userId = user.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if(userDoc.exists){
        setState(() {
          userName = userDoc.data()?['firstName'];
        });
      }
    }
  }



  final List categoriesNames = [
    "Patient",
    "Patient Reports",
    "Appointments",
    "History prescription"
  ];

  final List<Icon> categoriesIcons = [
    const Icon(
      Icons.person,
      color: Color(0xFF008000),
      size: 80
    ),
    const Icon(
      Icons.medical_services_sharp,
      color: Color(0xFF008000),
      size: 80
    ),
    const Icon(
      Icons.calendar_month_sharp,
      color: Color(0xFF008000),
      size: 80
    ),
    const Icon(
      Icons.history,
      color: Color(0xFF008000),
      size: 80
    )
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Container(
            padding: EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 10),
            decoration: const BoxDecoration(
                color: Color(0xFF008000),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                )),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.dashboard, size: 30, color: Color(0xFFFFFFFF)),
                    InkWell(
                      onTap: () {
                         Navigator.pushNamed(
                                    context, '/doctor profile');
                      },
                      child: const Icon(Icons.account_circle_sharp, size: 30, color: Color(0xFFFFFFFF)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.only(left: 3, bottom: 15),
                  child: Text("Dr $userName,",
                      style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          wordSpacing: 2,
                          color: Color(0xFFFFFFFF))),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: 20, left: 15, right: 15),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text(
                      "Home page",
                      style:
                          TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GridView.builder(
                    itemCount: categoriesNames.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio:
                            (MediaQuery.of(context).size.height) / (4 * 240),
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20),
                    itemBuilder: (context, index) {
                      return InkWell(
                          onTap: () {
                            switch (index) {
                              case 0:
                                Navigator.pushNamed(context, '/patients list');
                                print("Open Patient page");
                                break;
                              case 1:
                              Navigator.pushNamed(context, '/patients conditions');
                                print("Open Patient page");
                                break;
                              case 2:
                               Navigator.pushNamed(context, '/viewDoctorAppointment');
                                print("Open Appointments page");
                                break;
                              case 3:
                                Navigator.pushNamed(context, '/doctor prescriptions list');
                                print("Open History prescription page");
                                break;
                              default:
                                print("default");
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 20, horizontal: 10),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: const Color(0xFFFFFFFF),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0x339E9E9E),
                                      spreadRadius: 5,
                                      blurRadius: 7,
                                      offset: Offset(0, 3))
                                ]),
                            child: Column(
                              children: [
                                Padding(
                                    padding: EdgeInsets.all(10),
                                    child: categoriesIcons[index]),
                                const SizedBox(height: 10),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    categoriesNames[index],
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF000000)
                                    ),
                                  )
                                ),
                              ],
                            ),
                          ));
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
