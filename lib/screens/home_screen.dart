import 'package:flutter/material.dart';

import '../utils/banner_slider.dart';
import 'booking_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define your items list
    final List<Map<String, dynamic>> transportItems = [
      {'label': 'Launch', 'icon': Icons.directions_boat, 'color': Colors.blue.shade50},
      {'label': 'Bus', 'icon': Icons.directions_bus, 'color': Colors.blue.shade50},
      {'label': 'Boat', 'icon': Icons.sailing, 'color': Colors.blue.shade50}, // or a different boat icon
      {'label': 'Flight', 'icon': Icons.flight, 'color': Colors.blue.shade50},
      {'label': 'Train', 'icon': Icons.train, 'color': Colors.blue.shade50},
      {'label': 'Hotels', 'icon': Icons.hotel, 'color': Colors.blue.shade50},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to Durpalla',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          const BannerSlider(),
          const SizedBox(height: 24),
          const Text(
            'Services',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: transportItems.length,
            itemBuilder: (context, index) {
              final item = transportItems[index];
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingScreen(
                        transportType: item['label'], // pass type if needed
                      ),
                    ),
                  );
                },
                child: Card(
                  color: item['color'],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (item['icon'] is IconData)
                        Icon(item['icon'], size: 32, color: Colors.blue)
                      else
                        Image.asset(item['icon'], width: 32, height: 32),
                      const SizedBox(height: 8),
                      Text(item['label']),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
