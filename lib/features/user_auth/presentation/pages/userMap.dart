import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_maps_webservice/places.dart' as Places;
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String googleApiKey = "";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const GoogleMapPage(),
    );
  }
}

class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage({Key? key}) : super(key: key);

  @override
  State<GoogleMapPage> createState() => GoogleMapPageState();
}

class GoogleMapPageState extends State<GoogleMapPage> {
  final loc.Location _location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;
  final Completer<GoogleMapController> _controller = Completer();
  final SpeechToText _speech = SpeechToText();
  final TextEditingController _searchController = TextEditingController();
  late GoogleMapController _googleMapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};
  loc.LocationData? currentLocation;
  int _selectedIndex = 0;
  bool _isListening = false;
  bool _isDanger = false;
  bool isDanger = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final user = FirebaseAuth.instance.currentUser;

  FlutterTts flutterTts = FlutterTts();
  Timer? _sosTimer;
  double _sosProgress = 0.0;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    _requestPermission();
    _initializeNotifications();
    _listenToDangerChanges();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _sosTimer?.cancel();
    super.dispose();
  }

  void _requestPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _startLocationSharing();
    } else if (status.isDenied) {
      _requestPermission();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _startLocationSharing() async {
    _locationSubscription = _location.onLocationChanged.handleError((onError) {
      print(onError);
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((loc.LocationData currentlocation) async {
      print(user?.uid);
      await FirebaseFirestore.instance
          .collection('location')
          .doc(user?.uid)
          .set({
        'latitude': currentlocation.latitude,
        'longitude': currentlocation.longitude,
        'name': 'Current Location',
      }, SetOptions(merge: true));
      _updateMap(currentlocation.latitude!, currentlocation.longitude!);
    });
  }

  void _updateMap(double lat, double lng) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(lat, lng),
        zoom: 15.0,
      ),
    ));
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: LatLng(lat, lng),
          infoWindow: const InfoWindow(title: 'Current Location'),
        ),
      );
    });
  }

  void getCurrentLocation() async {
    loc.Location location = loc.Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    loc.PermissionStatus permissionStatus = await location.hasPermission();
    if (permissionStatus == loc.PermissionStatus.denied) {
      permissionStatus = await location.requestPermission();
      if (permissionStatus != loc.PermissionStatus.granted) {
        return;
      }
    }

    loc.LocationData locationData = await location.getLocation();
    setState(() {
      currentLocation = locationData;
    });

    GoogleMapController googleMapController = await _controller.future;

    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          zoom: 13.5,
          target: LatLng(
            currentLocation!.latitude!,
            currentLocation!.longitude!,
          ),
        ),
      ),
    );

    _addCurrentLocationCircle(
        currentLocation!.latitude!, currentLocation!.longitude!);
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {},
      onError: (error) => print('$error'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          print('${result.recognizedWords}');
          _searchController.text = result.recognizedWords;
          _searchLocation(result.recognizedWords);
        },
        listenFor: const Duration(seconds: 10),
      );
    } else {
      print('The user has denied the use of speech recognition.');
    }
  }

  Future<void> _stopListening() async {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _searchLocation(String query) async {
    final places = Places.GoogleMapsPlaces(apiKey: googleApiKey);
    Places.PlacesSearchResponse response = await places.searchByText(query);

    if (response.isOkay && response.results.isNotEmpty) {
      final place = response.results.first;
      final location = place.geometry!.location;

      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: MarkerId(place.id ?? 'default_id'),
            position: LatLng(location.lat, location.lng),
            infoWindow: InfoWindow(title: place.name ?? ''),
          ),
        );

        _drawPath(currentLocation!.latitude!, currentLocation!.longitude!,
            location.lat, location.lng);
      });
    } else {
      print('No results found for the search query.');
    }
  }

  Future<void> _drawPath(double sourceLat, double sourceLng, double destLat,
      double destLng) async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$sourceLat,$sourceLng&destination=$destLat,$destLng&key=$googleApiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      final routes = decodedResponse['routes'];

      if (routes != null && routes.isNotEmpty) {
        final points = routes[0]['overview_polyline']['points'];
        final List<PointLatLng> polylineCoordinates =
            PolylinePoints().decodePolyline(points);

        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: PolylineId('poly'),
              color: Colors.blue,
              points: polylineCoordinates
                  .map((point) => LatLng(point.latitude, point.longitude))
                  .toList(),
              width: 5,
            ),
          );

          for (var step in routes[0]['legs'][0]['steps']) {
            String instruction = step['html_instructions']
                .replaceAll(RegExp(r'<[^>]*>'), '');
            speakInstruction(instruction);
          }
        });
      } else {
        print('No routes found in the response.');
      }
    } else {
      throw Exception('Failed to load directions');
    }
  }

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _addCurrentLocationCircle(double lat, double lng) {
    _circles.add(
      Circle(
        circleId: CircleId('current_location'),
        center: LatLng(lat, lng),
        radius: 50,
        fillColor: Colors.blue.withOpacity(0.3),
        strokeWidth: 0,
      ),
    );
  }

  Future<void> speakInstruction(String instruction) async {
    await flutterTts.speak(instruction);
  }

  void _toggleDanger() {
    setState(() {
      isDanger = !isDanger;
      _isDanger = isDanger;
    });
    _updateFirestoreWithDangerStatus(isDanger);
  }

  void _updateFirestoreWithDangerStatus(bool dangerStatus) async {
    await FirebaseFirestore.instance.collection('sos').doc(user?.uid).set({
      'isDanger': dangerStatus,
    }, SetOptions(merge: true));
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

Future<void> _showNotification() async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your_channel_id',
    'your channel name',
    importance: Importance.max,
    priority: Priority.high,
    sound: RawResourceAndroidNotificationSound('user_notification'),
    // Specify the custom sound here
    playSound: true,
    showWhen: false,
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    'Danger Alert',
    'You announced you are in danger!!',
    platformChannelSpecifics,
  );
}

  void _listenToDangerChanges() {
    FirebaseFirestore.instance
        .collection('sos')
        .doc(user?.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          isDanger = snapshot['isDanger'] ?? false;
        });
        if (isDanger) {
          _showNotification();
        }
      }
    });
  }

  void _onSOSLongPressStart(LongPressStartDetails details) {
    _sosProgress = 0.0;
    _sosTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _sosProgress += 0.01;
      });

      if (_sosProgress >= 1.0) {
        _toggleDanger();
        _sosTimer?.cancel();
      }
    });
  }

  void _onSOSLongPressEnd(LongPressEndDetails details) {
    if (_sosTimer?.isActive ?? false) {
      _sosTimer?.cancel();
      setState(() {
        _sosProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            "Navigation",
            style: TextStyle(
                color: Colors.black, fontSize: 25, fontWeight: FontWeight.bold),
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
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a location...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    String searchQuery = _searchController.text.trim();
                    if (searchQuery.isNotEmpty) {
                      _searchLocation(searchQuery);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a location')),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: _selectedIndex == 0
                ? currentLocation == null
                    ? const Center(child: Text("Loading"))
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            currentLocation!.latitude!,
                            currentLocation!.longitude!,
                          ),
                          zoom: 13.5,
                        ),
                        markers: _markers,
                        polylines: _polylines,
                        circles: _circles,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        onMapCreated: (mapController) {
                          _googleMapController = mapController;
                        },
                      )
                : SizedBox(),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                onLongPressStart: (_) => _startListening(),
                onLongPressEnd: (_) => _stopListening(),
                child: Icon(
                  Icons.mic,
                  size: 55,
                  color: _isListening ? Colors.red : Colors.grey,
                ),
              ),
            ),
            VerticalDivider(
              color: Colors.grey,
              thickness: 1,
            ),
            Expanded(
              child: GestureDetector(
                onLongPressStart: _onSOSLongPressStart,
                onLongPressEnd: _onSOSLongPressEnd,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 70, // Adjust the width as needed
                      height: 70, // Adjust the height as needed
                      child: CircularProgressIndicator(
                        value: _sosProgress,
                        strokeWidth: 6.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            isDanger ? Colors.red : Colors.green),
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                    Icon(
                      Icons.warning,
                      size: 55,
                      color: isDanger ? Colors.red : Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
