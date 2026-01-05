import 'package:flutter/material.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  bool isOnline = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Dashboard"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildAvailabilityToggle(),
            const SizedBox(height: 20),
            _buildNextRideCard(),
            const SizedBox(height: 20),
            _buildEarningsSummary(),
            const SizedBox(height: 20),
            _buildRecentTripsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage("https://i.pravatar.cc/300"),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome, Emmanuel",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: const [
                Icon(Icons.star, color: Colors.amber, size: 18),
                Icon(Icons.star, color: Colors.amber, size: 18),
                Icon(Icons.star, color: Colors.amber, size: 18),
                Icon(Icons.star, color: Colors.amber, size: 18),
                Icon(Icons.star_half, color: Colors.amber, size: 18),
                SizedBox(width: 6),
                Text("4.5", style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilityToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Availability: ${isOnline ? "Online" : "Offline"}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Switch(
          value: isOnline,
          activeColor: Colors.green,
          onChanged: (value) {
            setState(() {
              isOnline = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNextRideCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Next Ride", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Pickup: Allen Avenue"),
            Text("Destination: Victoria Island"),
            SizedBox(height: 8),
            Text("Scheduled: 10:30 AM"),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: const [
          Text("Earnings Today", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text("₦5,200", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecentTripsList() {
    final recentTrips = [
      {"from": "Ikeja", "to": "Yaba", "fare": "₦1,200"},
      {"from": "Ojota", "to": "Lekki", "fare": "₦2,000"},
      {"from": "Ikeja", "to": "Surulere", "fare": "₦1,600"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Recent Trips", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...recentTrips.map((trip) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.local_taxi),
              title: Text("${trip["from"]} → ${trip["to"]}"),
              trailing: Text(trip["fare"]!),
            ),
          );
        }).toList(),
      ],
    );
  }
}
