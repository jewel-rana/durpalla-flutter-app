import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/banner_slider.dart';
import 'booking_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define your items list
    final List<Map<String, dynamic>> transportItems = [
      {'label': 'Launch', 'icon': Icons.directions_boat, 'color': AppColors.darkTeal},
      {'label': 'Bus', 'icon': Icons.directions_bus, 'color': AppColors.lightSeafoam},
      {'label': 'Boat', 'icon': Icons.sailing, 'color': AppColors.lightSeafoam}, // or a different boat icon
      {'label': 'Flight', 'icon': Icons.flight, 'color': AppColors.lightSeafoam},
      {'label': 'Train', 'icon': Icons.train, 'color': AppColors.lightSeafoam},
      {'label': 'Hotels', 'icon': Icons.hotel, 'color': AppColors.lightSeafoam},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Services',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white70),
          ),
          const SizedBox(height: 15),
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
                  color: (Colors.white).withValues(alpha: 0.7),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (item['icon'] is IconData)
                        Icon(item['icon'], size: 32, color: Colors.white)
                      else
                        Image.asset(
                          item['icon'],
                          width: 32,
                          height: 32,
                          color: Colors.white,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        item['label'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )

              );
            },
          ),
          const SizedBox(height: 75),
          const Text(
            'Today\'s Trips',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          const BannerSlider(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
