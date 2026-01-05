import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../../../core/constants/colors.dart';
import '../../viewModels/map_bloc.dart';
import '../widgets/user_movement_map.dart';
import '../../../data/services/api.dart';

class TrackTrip extends StatefulWidget {
  const TrackTrip({super.key});

  @override
  State<TrackTrip> createState() => _TrackTripState();
}

class _TrackTripState extends State<TrackTrip> {
  latlng.LatLng? currentLocation;
  latlng.LatLng? destination;
  bool _isLoading = true;
  String? _errorMessage;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    ScaffoldMessenger.of(context).clearSnackBars();
    setState(() {
      _isLoading = true;
    });
    try {
      _errorMessage = null;
      await _checkLocationPermissions();
      await _getCurrentLocation();
      await _loadDestination();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _showErrorSnackbar(_errorMessage!);
    }
  }

  Future<void> _checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      bool enabled = await Geolocator.openLocationSettings();
      if (!enabled) {
        throw Exception('Please enable location services to continue');
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw Exception('Location permissions are required');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied. Please enable them in app settings.');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          currentLocation =
              latlng.LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      throw Exception('Failed to get current location: ${e.toString()}');
    }
  }

  Future<void> _loadDestination() async {
    try {
      final geoPoint = await addressToGeoPoint("Pan-Atlantic University");
      if (mounted) {
        setState(() {
          destination = latlng.LatLng(geoPoint.latitude, geoPoint.longitude);
          _isLoading = false;
        });
      }
    } catch (e) {
      throw Exception('Failed to load destination: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: _initializeData,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: const Text('Track My Trip')),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              icon: const Icon(
                Icons.refresh,
                color: StragColor.primary,
                size: 24,
              ),
              label: Text(
                'Try Again',
                style: TextStyle(
                  color: StragColor.primary,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _initializeData();
                });
              },
            ),
          ],
        ),
      );
    }

    if (_isLoading || currentLocation == null || destination == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting your location...'),
          ],
        ),
      );
    }

    return BlocProvider(
      create: (_) => MapBloc(),
      child: UserMovementMap(
        currentLocation: currentLocation!,
        destination: destination!,
        iconPath: 'assets/images/car.png',
      ),
    );
  }
}
