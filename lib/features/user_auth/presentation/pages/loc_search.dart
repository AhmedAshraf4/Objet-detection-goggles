import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_maps_webservice/directions.dart' as google_directions;
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_tts/flutter_tts.dart';


class LocationResult {
  static const String apiKey =
      'AIzaSyBHUHiMgQO6m2gWxl2UsGssY7TivMAbYOY'; // Replace with your API key
  late GoogleMapController _mapController;
  FlutterTts flutterTts = FlutterTts();

  late LatLng _currentPosition =
      LatLng(31.2062, 29.9248); // Defaulted to Alexandria, Egypt
  LatLng? _searchedPosition; // Change to nullable LatLng
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  Future<LatLng> searchLocationAndDrawRoute({
    required String query,
    required LatLng currentLocation,
    required GoogleMapController mapController,
    required Set<Polyline> polylines,
    required Set<Marker> markers,
  }) async {
    if (mapController == null) {
      throw Exception('Map controller is not initialized');
    }
    _mapController = mapController;

    final places = GoogleMapsPlaces(apiKey: apiKey);
    PlacesSearchResponse response = await places.searchByText(query);
    if (response.isOkay && response.results.isNotEmpty) {
      final place = response.results.first;
      final destination = LatLng(
        place.geometry!.location.lat,
        place.geometry!.location.lng,
      );

      final directions =
          google_directions.GoogleMapsDirections(apiKey: apiKey);
      final directionsResponse = await directions.directions(
        google_directions.Location(
          lat: currentLocation.latitude,
          lng: currentLocation.longitude,
        ),
        google_directions.Location(
          lat: destination.latitude,
          lng: destination.longitude,
        ),
        travelMode: google_directions.TravelMode.walking,
      );

      if (directionsResponse.isOkay) {
        final routes = directionsResponse.routes;
        if (routes.isNotEmpty) {
          final route = routes.first;
          final polylinePoints = PolylinePoints();
          List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(
              route.overviewPolyline.points);
          List<LatLng> polylineCoordinates = decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          mapController.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(
                  min(currentLocation.latitude, destination.latitude),
                  min(currentLocation.longitude, destination.longitude),
                ),
                northeast: LatLng(
                  max(currentLocation.latitude, destination.latitude),
                  max(currentLocation.longitude, destination.longitude),
                ),
              ),
              50,
            ),
          );

          // Clear existing polylines and markers
          polylines.clear();
          markers.clear();

          // Add new polyline to the set
          polylines.add(
            Polyline(
              polylineId: PolylineId('route'),
              points: polylineCoordinates,
              width: 5,
              color: Colors.blue,
            ),
          );

          // Add marker for the searched location
          markers.add(
            Marker(
              markerId: MarkerId('destination'),
              position: destination,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );

          // Return destination
          return destination;
        }
      }
    }
    throw Exception('Failed to retrieve location information');
  }

  Future<void> handleVoiceInput(String input) async {
     _handleVoiceInput(input);
  }

  void _handleVoiceInput(String input) async {
    // Implement logic to handle voice input
    print('Voice input: $input');
    try {
      final LatLng searchResult = await searchLocationAndDrawRoute(
        query: input,
        currentLocation: _currentPosition,
        mapController: _mapController,
        polylines: _polylines,
        markers: _markers,
      );

      _searchedPosition = searchResult;
      final directions = await getDirections(_currentPosition, _searchedPosition!);

      speakInstructions(directions);
    

    } catch (e) {
      // Handle error
      print('Error: $e');
    }
    // Use the input for searching and marking on the map
  }
  Future<List<String>> getDirections(LatLng origin, LatLng destination) async {
    final directions = google_directions.GoogleMapsDirections(apiKey: apiKey);
    final directionsResponse = await directions.directions(
      google_directions.Location(lat: origin.latitude, lng: origin.longitude),
      google_directions.Location(lat: destination.latitude, lng: destination.longitude),
      travelMode: google_directions.TravelMode.walking, // Change to your desired travel mode
    );

    if (directionsResponse.isOkay) {
      final steps = directionsResponse.routes.first.legs.first.steps;
      List<String> instructions = [];
      for (final step in steps) {
        // Strip HTML tags from instructions
        final instruction = step.htmlInstructions.replaceAll(RegExp(r'<[^>]*>'), '');
        instructions.add(instruction);
      }
      return instructions;
    } else {
      throw Exception('Failed to retrieve directions');
    }
  }
  
  Future<void> speakInstructions(List<String> instructions) async {
    FlutterTts flutterTts = FlutterTts();
    for (final instruction in instructions) {
      await flutterTts.speak(instruction);
      print(instruction);
    }
  }

}
