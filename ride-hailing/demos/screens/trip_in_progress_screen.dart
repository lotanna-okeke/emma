import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripInProgressScreen extends StatefulWidget {
  const TripInProgressScreen({super.key});

  @override
  State<TripInProgressScreen> createState() => _TripInProgressScreenState();
}

class _TripInProgressScreenState extends State<TripInProgressScreen> {
  late GoogleMapController mapController;

  final LatLng destination = const LatLng(6.5244, 3.3792); // Lagos
  final LatLng userLocation = const LatLng(6.6000, 3.3500); // Mock destination

  Set<Marker> _markers = {};
  BitmapDescriptor _userIcon = BitmapDescriptor.defaultMarker;

   @override
  void initState() {
    super.initState();
    _setMarkerIcons();
  }

  Future<void> _setMarkerIcons() async {
    final AssetMapBitmap carIcon = AssetMapBitmap('assets/images/car.png', width: 48, height: 48);
    setState(() {
      _userIcon = carIcon;
      _markers = {
        Marker(
          markerId: const MarkerId('userLocation'),
          position: userLocation,
          icon: _userIcon, // Use the car icon here
          infoWindow: const InfoWindow(title: 'My Location'),
        ),
        Marker(
          markerId: const MarkerId('destinationLocation'),
          position: destination,
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      };
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: userLocation,
              zoom: 12,
            ),
            onMapCreated: (controller) => mapController = controller,
            myLocationEnabled: true,
            polylines: {
              Polyline(
                polylineId: const PolylineId("route"),
                color: Colors.blue,
                width: 5,
                points: [
                  userLocation,
                  destination,
                ],
              ),
            },
            markers: _markers,
          ),

          // Trip Info card
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: _buildTripStatusCard(),
          ),

          // Driver Info Card
          Positioned(
            bottom: 60,
            left: 16,
            right: 16,
            child: _buildDriverInfoCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildTripStatusCard() {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Trip in Progress", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("ETA: 14 mins", style: TextStyle(color: Colors.grey)),
              ],
            ),
            Icon(Icons.navigation, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfoCard() {
    return Card(
      elevation: 6,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundImage: NetworkImage("https://i.pravatar.cc/300"),
              radius: 26,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Emmanuel (Toyota Corolla)", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text("Plate: KJA-123XY", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.call, color: Colors.green),
              onPressed: () {
                print("Calling driver...");
              },
            ),
            IconButton(
              icon: const Icon(Icons.chat, color: Colors.blue),
              onPressed: () {
                print("Messaging driver...");
              },
            ),
          ],
        ),
      ),
    );
  }
}
