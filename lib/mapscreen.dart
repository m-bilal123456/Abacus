// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'cache.dart';
import 'productscreen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Position? _currentPosition;
  bool _loading = true;
  String? _error;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadCachedOrGpsLocation();
  }

  // ------------------------------------------------------------
  // LOAD LOCATION (CACHE FIRST → GPS FALLBACK)
  // ------------------------------------------------------------
  Future<void> _loadCachedOrGpsLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1️⃣ Try cache first
      final lat = await readData('latitude');
      final lng = await readData('longitude');

      if (lat != null && lng != null) {
        _currentPosition = Position(
          latitude: double.parse(lat),
          longitude: double.parse(lng),
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );

        setState(() => _loading = false);
        return;
      }

      // 2️⃣ Fallback to GPS
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Enable GPS');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.best),
      );

      // ✅ Save to cache
      await saveData('latitude', position.latitude.toString());
      await saveData('longitude', position.longitude.toString());

      setState(() {
        _currentPosition = position;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ------------------------------------------------------------
  // UPDATE EXISTING USER ONLY (NO CREATION)
  // ------------------------------------------------------------
  Future<void> _updateExistingUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final name = await readData('name');
    final phone = await readData('phoneno');
    final shopName = await readData('shopname');
    final latitude = await readData('latitude');
    final longitude = await readData('longitude');

    if (name == null || phone == null || shopName == null) {
      throw Exception('Missing cached user data');
    }

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final snapshot = await userDoc.get();
    if (!snapshot.exists) {
      throw Exception('User document does not exist');
    }

    final data = snapshot.data()!;
    final Map<String, dynamic> updateData = {};

    // ---- BASIC INFO (NO OVERWRITE) ----
    if (!data.containsKey('name')) {
      updateData['name'] = name;
    }
    if (!data.containsKey('phone')) {
      updateData['phone'] = phone;
    }
    if (!data.containsKey('shopName')) {
      updateData['shopName'] = shopName;
    }

    // ---- LOCATION (NO OVERWRITE) ----
    if (!data.containsKey('location') && latitude != null && longitude != null) {
      updateData['location'] = {
        'latitude': double.parse(latitude),
        'longitude': double.parse(longitude),
      };
    }

    if (updateData.isNotEmpty) {
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      await userDoc.update(updateData);
    }
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Map")),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.abacus',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await _updateExistingUser();
                  await saveData('login', 'yes');

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductScreen(),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Update failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.green.shade600,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                "Next",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
