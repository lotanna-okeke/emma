import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  final List<Map<String, dynamic>> allRides = [
    {
      "from": "Allen Avenue",
      "to": "Lekki Phase 1",
      "datetime": DateTime(2025, 6, 14, 8, 30),
      "fare": "₦1,800",
      "status": "Completed"
    },
    {
      "from": "Ikeja GRA",
      "to": "Victoria Island",
      "datetime": DateTime(2025, 6, 13, 17, 10),
      "fare": "₦2,300",
      "status": "Completed"
    },
    {
      "from": "Yaba",
      "to": "Ojuelegba",
      "datetime": DateTime(2025, 6, 13, 14, 45),
      "fare": "₦900",
      "status": "Cancelled"
    },
    {
      "from": "Ajah",
      "to": "Obalende",
      "datetime": DateTime(2025, 5, 20, 10, 0),
      "fare": "₦1,400",
      "status": "Completed"
    },
    {
      "from": "Ajah",
      "to": "Obalende",
      "datetime": DateTime(2025, 5, 20, 10, 0),
      "fare": "₦1,400",
      "status": "Cancelled"
    },
  ];

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredRides = allRides
    .where((dynamic ride) {
      final from = (ride["from"] as String).toLowerCase();
      final to = (ride["to"] as String).toLowerCase();
      final query = searchQuery.toLowerCase();
      return from.contains(query) || to.contains(query);
    })
    .toList();


    final groupedRides = _groupRidesByMonth(filteredRides);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ride History"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by pickup or destination",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
          ),
          Expanded(
            child: filteredRides.isEmpty
                ? const Center(child: Text("No rides found."))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: groupedRides.keys.length,
                    itemBuilder: (context, index) {
                      final month = groupedRides.keys.elementAt(index);
                      final rides = groupedRides[month]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            month,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...rides.map((ride) => _buildRideCard(context, ride)).toList(),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupRidesByMonth(List<Map<String, dynamic>> rides) {
  final Map<String, List<Map<String, dynamic>>> grouped = {};

  for (var ride in rides) {
    String key = DateFormat.yMMMM().format(ride['datetime'] as DateTime);
    grouped.putIfAbsent(key, () => []);
    grouped[key]!.add(ride);
  }

  return grouped;
}


  Widget _buildRideCard(BuildContext context, Map<String, dynamic> ride) {
    final date = DateFormat("MMM d, y").format(ride['datetime'] as DateTime);
    final time = DateFormat("h:mm a").format(ride['datetime'] as DateTime);
    final status = ride["status"];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: const Icon(Icons.local_taxi, color: Colors.blue),
        ),
        title: Text("${ride["from"]} → ${ride["to"]}"),
        subtitle: Text("$date • $time"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(ride['fare'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 4),
            Text(
              status as String,
              style: TextStyle(
                fontSize: 12,
                color: status == "Completed" ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        onTap: () => _showRideDetailsDialog(context, ride),
      ),
    );
  }

  void _showRideDetailsDialog(BuildContext context, Map<String, dynamic> ride) {
    final String dateTime = DateFormat("EEE, MMM d • h:mm a").format(ride['datetime'] as DateTime);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Ride Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow("From", ride['from'] as String),
            _detailRow("To", ride['to'] as String),
            _detailRow("Date & Time", dateTime),
            _detailRow("Fare", ride['fare'] as String),
            _detailRow("Status", ride['status'] as String),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
