import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'mymap.dart';
import 'settings.dart'; 
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: MyApp2(),
    theme: ThemeData(
      fontFamily: 'Poppins',
    ),
  ));
}

class MyApp2 extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp2> {
  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;
  bool isSharingLocation = true;
  bool isDanger = true; // New boolean field for danger indication
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin(); // Initialize the FlutterLocalNotificationsPlugin
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _listenToDangerChanges(); // Listen to changes in Firestore danger status
    _initializeNotifications(); // Initialize local notifications
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            "Live tracking",
            style: TextStyle(
              color: Colors.black,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(Icons.more_horiz, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
          )
        ], // Add IconButton for settings
      ),
      body: Stack(
        children: [
          MyMap(user?.uid), // Display the map
          // Remove or comment out the following StreamBuilder and its children
          // Column(
          //   children: [
          //     Expanded(
          //       child: StreamBuilder<DocumentSnapshot>(
          //         stream: FirebaseFirestore.instance
          //             .collection('location')
          //             .doc(user?.uid)
          //             .snapshots(),
          //         builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          //           if (!snapshot.hasData) {
          //             return Center(child: CircularProgressIndicator());
          //           }
          //           final document = snapshot.data!;
          //           return Column(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             children: [
          //               Row(
          //                 // Display current location coordinates
          //                 children: [
          //                   Text('Latitude: ${document['latitude'].toString()}'),
          //                   SizedBox(width: 20),
          //                   Text('Longitude: ${document['longitude'].toString()}'),
          //                 ],
          //               ),
          //             ],
          //           );
          //         },
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: isDanger ? Colors.red : Colors.green, // Background color based on danger status
        child: Center(
          child: Text(
            isDanger ? 'Danger' : 'Safe', // Display 'Danger' if in danger, 'Safe' otherwise
            textAlign: TextAlign.center, // Align the text to the center
            style: TextStyle(
              color: Colors.white, // Text color is always white
              fontSize: 30.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  _getLocation() async {
    try {
      final loc.LocationData _locationResult = await location.getLocation();
      FirebaseFirestore.instance.collection('location').doc(user?.uid).set({
        'latitude': _locationResult.latitude,
        'longitude': _locationResult.longitude,
        'name': 'John',
        'isDanger': isDanger,
      }, SetOptions(merge: true));
    } catch (e) {
      print(e);
    }
  }

  Future<void> _listenLocation() async {
    _locationSubscription = location.onLocationChanged.handleError((onError) {
      print(onError);
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((loc.LocationData currentlocation) async {
      FirebaseFirestore.instance.collection('location').doc(user?.uid).set({
        'latitude': currentlocation.latitude,
        'longitude': currentlocation.longitude,
        'name': 'John',
        'isSharing': true,
        'isDanger': isDanger,
      }, SetOptions(merge: true));
    });
  }

  _stopListening() {
    _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
  }

  _requestPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      print('Permission granted.');
    } else if (status.isDenied) {
      _requestPermission();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  // Toggle the danger status
  void _toggleDanger() {
    setState(() {
      isDanger = !isDanger; // Toggle the danger status
    });
    _updateFirestoreWithDangerStatus(isDanger); // Update Firestore with new danger status
  }

  // Update Firestore with the new danger status
  void _updateFirestoreWithDangerStatus(bool dangerStatus) async {
    await FirebaseFirestore.instance.collection('sos').doc(user?.uid).set({
      'isDanger': dangerStatus,
    }, SetOptions(merge: true));
  }

  // Listen to changes in Firestore danger status
  void _listenToDangerChanges() {
    FirebaseFirestore.instance.collection('sos').doc(user?.uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          isDanger = snapshot['isDanger'] ?? true; // Update local danger status
        });
        if (isDanger) {
          _showNotification(); // Show local notification when danger status is true
        }
      }
    });
  }

  // Initialize local notifications
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Show local notification
  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your channel name',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('relative_notification'), // Specify custom sound here
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Danger Alert',
      'Check on your tracked individual immediately. They may be in danger!!',
      platformChannelSpecifics,
    );
  }


  // Function to navigate to settings page
  void _goToSettingsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage()), // Navigate to settings.dart
    );
  }
}
