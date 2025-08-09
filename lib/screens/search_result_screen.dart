import 'package:durpalla/screens/trip_details_screen.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SearchResultScreen extends StatefulWidget {
  final String type;
  final String from;
  final String to;
  final String date;
  final String? return_date;

  const SearchResultScreen({
    super.key,
    required this.type,
    required this.from,
    required this.to,
    required this.date,
    this.return_date,
  });

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  late Future<List<dynamic>> _searchResults;

  @override
  void initState() {
    super.initState();
    _searchResults = fetchResults();
  }

  Future<List<dynamic>> fetchResults() async {
    final query = Uri.encodeFull(
      'search?trip_from=${widget.from}&trip_to=${widget.to}&trip_date=${widget.date}',
    );

    final response = await ApiService.get(query);

    return response['data'] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Trips'),
        backgroundColor: const Color(0xFF0061A8),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _searchResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final results = snapshot.data!;
          if (results.isEmpty) {
            return const Center(child: Text('No trips found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final trip = results[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Text('${trip['vehicle_name']}'),
                  // title: Text('${trip['from']} → ${trip['to']}'),
                  subtitle: Text('Trip: ${trip['route_name']}'),
                  trailing: Text('${trip['price']} BDT'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripDetailsScreen(tripId: trip['trip_id']),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
