import 'package:flutter/material.dart';

class TripSummaryScreen extends StatefulWidget {
  const TripSummaryScreen({super.key});

  @override
  State<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends State<TripSummaryScreen> {
  int selectedRating = 0;
  final TextEditingController feedbackController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Summary"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 70),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                "Trip Completed!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),

            _buildTripDetails(),
            const SizedBox(height: 24),

            _buildDriverCard(),
            const SizedBox(height: 24),

            _buildRatingStars(),
            const SizedBox(height: 16),

            _buildFeedbackInput(),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                print("Submitted rating: $selectedRating");
                print("Feedback: ${feedbackController.text}");
              },
              child: const Text("Submit Rating", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text("Trip Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Distance"),
            Text("8.2 km"),
          ],
        ),
        SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Duration"),
            Text("18 mins"),
          ],
        ),
        SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Total Fare"),
            Text("₦1,200"),
          ],
        ),
      ],
    );
  }

  Widget _buildDriverCard() {
    return Row(
      children: [
        const CircleAvatar(
          backgroundImage: NetworkImage("https://i.pravatar.cc/300"),
          radius: 30,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Emmanuel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Toyota Corolla • KJA-123XY", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Icon(Icons.verified, color: Colors.green.shade400),
      ],
    );
  }

  Widget _buildRatingStars() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Rate Your Driver", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              iconSize: 36,
              icon: Icon(
                index < selectedRating ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: () {
                setState(() {
                  selectedRating = index + 1;
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFeedbackInput() {
    return TextField(
      controller: feedbackController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: "Leave a comment (optional)",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
