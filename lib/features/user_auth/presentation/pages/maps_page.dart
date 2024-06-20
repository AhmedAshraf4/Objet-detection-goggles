import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'loc_search.dart';
import 'package:location/location.dart' as loc;
import 'package:geolocator/geolocator.dart'; // Import Geolocator package

class MapsPage extends StatefulWidget {
  const MapsPage({Key? key}) : super(key: key);

  @override
  _MapsPageState createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  final TextEditingController _searchController = TextEditingController();
  late GoogleMapController _mapController;
  LatLng? _currentPosition;
  LatLng? _searchedPosition; // Change to nullable LatLng
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  final LocationResult _locationResult = LocationResult();

  // initState() method
  @override
  void initState() {
    super.initState();
    _initPlatformState();
  }

  // build() method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Navigation & Location Tracking"),
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () {
              _moveToCurrentLocation();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Title bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a location...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    // Handle search logic here
                    _handleSearch();
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? LatLng(50, 50),
                zoom: 15,
              ),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) {
                _mapController = controller;
                _moveToCurrentLocation(); // Move to current location when map is created
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleSearch() async {
    try {
      final searchResult = await _locationResult.searchLocationAndDrawRoute(
        query: _searchController.text,
        currentLocation: _currentPosition!,
        mapController: _mapController,
        polylines: _polylines,
        markers: _markers,
      );
      setState(() {
        _searchedPosition = searchResult;
      });
      final directions = await _locationResult.getDirections(_currentPosition!, _searchedPosition!);
      await _locationResult.speakInstructions(directions);
    } catch (e) {
      // Handle error
      print('Error: $e');
    }
  }

  void _initPlatformState() async {
    await _getCurrentLocation(); // Fetch current location when the app starts
    _startListeningLocation(); // Start listening for location updates
  }

  void _startListeningLocation() {
    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    });
  }

  Future<void> _getCurrentLocation() async {
    Position? position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    if (position != null) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _markers.add(Marker(
          markerId: MarkerId("current_position"),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ));
        _updateMarker();
      });
    } else {
      // Handle the case when position is null
      print('Error: Unable to fetch current location');
    }
  }

void _updateMarker() {
    _markers.clear();
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: MarkerId("current_position"),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
  }

  void _moveToCurrentLocation() {
    if (_mapController != null && _currentPosition != null) {
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 15,
          ),
        ),
      );
    } else {
      print('Error: Map controller or current position is null');
    }
  }

  Future<void> _requestLocationPermission() async {
    var location = loc.Location();
    bool _serviceEnabled;
    loc.PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        // Handle the case when location services are not enabled by the user.
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != loc.PermissionStatus.granted) {
        // Handle the case when location permissions are not granted by the user.
        return;
      }
    }
  }
}
