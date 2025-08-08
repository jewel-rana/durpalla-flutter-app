import 'package:flutter/material.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> trips = [
      {'route': 'Dhaka to Barisal', 'date': '2025-07-05', 'status': 'Confirmed'},
      {'route': 'Khulna to Dhaka', 'date': '2025-07-07', 'status': 'Pending'},
      {'route': 'Chittagong to Barisal', 'date': '2025-07-10', 'status': 'Cancelled'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('My Trips')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(Icons.directions_boat, color: Colors.blue),
              title: Text(trip['route']!),
              subtitle: Text('Date: ${trip['date']}'),
              trailing: Chip(
                label: Text(trip['status']!),
                backgroundColor: trip['status'] == 'Confirmed'
                    ? Colors.green.shade100
                    : trip['status'] == 'Pending'
                    ? Colors.orange.shade100
                    : Colors.red.shade100,
              ),
            ),
          );
        },
      ),
    );
  }
}
