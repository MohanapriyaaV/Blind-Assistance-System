import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // Switched to geolocator

class LiveLocationMapScreen extends StatefulWidget {
  final double? targetLatitude;
  final double? targetLongitude;

  const LiveLocationMapScreen({
    Key? key,
    this.targetLatitude,
    this.targetLongitude,
  }) : super(key: key);

  @override
  _LiveLocationMapScreenState createState() => _LiveLocationMapScreenState();
}

class _LiveLocationMapScreenState extends State<LiveLocationMapScreen> {
  Position? currentLocation;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _locationSubscription;
  bool _isLoading = true;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    if (widget.targetLatitude != null && widget.targetLongitude != null) {
      setState(() {
        currentLocation = Position(
          longitude: widget.targetLongitude!,
          latitude: widget.targetLatitude!,
          timestamp: DateTime.now(),
          accuracy: 100.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
        _isLoading = false;
      });
    } else {
      _initLocationService();
    }
  }

  Future<void> _initLocationService() async {
    bool serviceEnabled;
    LocationPermission permissionGranted;

    try {
      // 1. Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMsg = 'Location services are disabled.';
          _isLoading = false;
        });
        return;
      }

      // 2. Check for permissions
      permissionGranted = await Geolocator.checkPermission();
      if (permissionGranted == LocationPermission.denied) {
        permissionGranted = await Geolocator.requestPermission();
        if (permissionGranted == LocationPermission.denied) {
          setState(() {
            _errorMsg = 'Location permission denied.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permissionGranted == LocationPermission.deniedForever) {
        setState(() {
          _errorMsg = 'Location permissions are permanently denied.';
          _isLoading = false;
        });
        return;
      }

      // 3. Get the initial location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        currentLocation = position;
        _isLoading = false;
      });

      // 4. Continuously listen to location updates
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((Position newLocation) {
        if (mounted) {
          setState(() {
            currentLocation = newLocation;
          });

          // Smoothly move/animate the map to follow the user location
          _mapController.move(
            LatLng(newLocation.latitude, newLocation.longitude),
            16.0, // Zoom level
          );
        }
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Error obtaining location: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStatic = widget.targetLatitude != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isStatic ? 'Alert Location Map' : 'Live Location Navigation'),
        backgroundColor: isStatic ? Colors.redAccent : Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _buildMapBody(),
    );
  }

  Widget _buildMapBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fetching location...'),
          ],
        ),
      );
    }

    if (_errorMsg.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMsg,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (currentLocation == null ||
        currentLocation!.latitude == null ||
        currentLocation!.longitude == null) {
      return const Center(child: Text('Waiting for GPS signal...'));
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
        initialZoom: 16.0,
      ),
      children: [
        // OpenStreetMap Layer (No API key needed)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.blind_assist_app', 
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
              width: 50.0,
              height: 50.0,
              child: const Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 50.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
