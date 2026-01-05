import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverSearchingScreen extends StatefulWidget {
  const DriverSearchingScreen({Key? key}) : super(key: key);

  @override
  State<DriverSearchingScreen> createState() => _DriverSearchingScreenState();
}

class _DriverSearchingScreenState extends State<DriverSearchingScreen>
    with SingleTickerProviderStateMixin {
  late GoogleMapController mapController;
  final LatLng _mockLocation = const LatLng(6.5244, 3.3792); // Lagos

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);

    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map background
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _mockLocation,
              zoom: 14,
            ),
            onMapCreated: (controller) => mapController = controller,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // Dark overlay
          Container(
            color: Colors.black.withOpacity(0.5),
          ),

          // Center searching animation and text
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.local_taxi, size: 70, color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    "Searching for a driver...",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Cancel button
          Positioned(
            bottom: 60,
            left: 16,
            right: 16,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                // For now, just go back
                Navigator.pop(context);
              },
              child: const Text("Cancel Ride", style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
