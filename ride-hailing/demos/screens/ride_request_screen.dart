import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../widgets/ride_option_card.dart';

class RideRequestScreen extends StatefulWidget {
  const RideRequestScreen({Key? key}) : super(key: key);

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  late GoogleMapController mapController;
  final LatLng _mockLocation = const LatLng(6.5244, 3.3792); // Lagos

  final TextEditingController pickupController = TextEditingController(text: "Current Location");
  final TextEditingController destinationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _mockLocation,
              zoom: 14,
            ),
            onMapCreated: (controller) => mapController = controller,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // Top input fields
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Column(
              children: [
                _buildInputField(pickupController, Icons.my_location, "Pickup Location"),
                const SizedBox(height: 10),
                _buildInputField(destinationController, Icons.location_on, "Enter Destination"),
              ],
            ),
          ),

          // Ride options list
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  RideOptionCard(type: "Economy", price: "₦800"),
                  RideOptionCard(type: "Premium", price: "₦1500"),
                  RideOptionCard(type: "Bike", price: "₦500"),
                  RideOptionCard(type: "Bus", price: "₦200"),
                ],
              ),
            ),
          ),

          // Confirm button
          Positioned(
            bottom: 60,
            left: 16,
            right: 16,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                // Later: connect to Bloc or API
                print("Requesting ${destinationController.text} from ${pickupController.text}");
              },
              child: const Text("Confirm Ride", style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, IconData icon, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
