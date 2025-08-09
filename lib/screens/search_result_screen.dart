import 'dart:convert';
import 'package:durpalla/screens/trip_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart'; // <- has ApiService.buildUri

class SearchResultScreen extends StatefulWidget {
  final String type;       // "launch" | "bus" | "train" | "flight"
  final String from;
  final String to;
  final String date;       // "YYYY-MM-DD"
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
  late DateTime selectedDate;
  bool loading = false;
  String? error;
  List<dynamic> trips = [];

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.tryParse(widget.date) ?? DateTime.now();
    _load();
  }

  String _d(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  IconData _iconFor(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'launch':
        return Icons.directions_boat_filled_outlined;
      case 'bus':
        return Icons.directions_bus_filled_outlined;
      case 'train':
        return Icons.train_outlined;
      case 'flight':
      case 'air':
      case 'airline':
        return Icons.flight_takeoff_outlined;
      default:
        return Icons.directions_transit_filled_outlined;
    }
  }

  void _goToDetails(Map<String, dynamic> item) {
    // pull safe values with fallbacks
    final tripId       = item['trip_id'] as int;
    final routeId      = item['route_id'] as int?;
    final vehicleId    = item['vehicle_id'] as int?;
    final serviceType  = (item['service_type'] ?? widget.type).toString();
    final scheduleDate = (item['schedule_date'] ?? _d(selectedDate)).toString();
    final defaultTab   = (item['default_tab'] ?? 'cabin').toString();      // "cabin" | "seat"
    final defaultFloor = (item['default_floor'] ?? 1) as int;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripDetailsScreen(
          tripId: tripId
        ),
      ),
    );
  }


  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final uri = ApiService.buildUri('search', {
        'type': widget.type,
        'trip_from': widget.from,
        'trip_to': widget.to,
        'trip_date': _d(selectedDate)
      });

      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      print('URL: ${res.request?.url}');
      print('STATUS: ${res.statusCode}');
      print('BODY: ${res.body}');
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final json = jsonDecode(res.body);
        if (json is Map && json['success'] == true) {
          setState(() => trips = (json['data'] as List?) ?? []);
        } else {
          setState(() => error = 'Unexpected response.');
        }
      } else {
        setState(() => error = 'Network error: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _prevDay() {
    setState(() => selectedDate = selectedDate.subtract(const Duration(days: 1)));
    _load();
  }

  void _nextDay() {
    setState(() => selectedDate = selectedDate.add(const Duration(days: 1)));
    _load();
  }

  String _hm(String leavingAt) {
    // leavingAt like "2025-08-10 08:31:00"
    try {
      final t = DateTime.parse(leavingAt.replaceFirst(' ', 'T'));
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    } catch (_) {
      return leavingAt;
    }
  }

  Widget _dateSwitcher() {
    return Container(
      width: double.infinity, // ✅ stretch full width
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(.08),
        borderRadius: BorderRadius.zero, // ✅ remove rounded edges if you want
        border: Border.all(color: Colors.blue.withOpacity(.15)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous day',
            onPressed: _prevDay,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${widget.from} → ${widget.to}',
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  _d(selectedDate),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Next day',
            onPressed: _nextDay,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }


  Widget _itemCard(Map item) {
    final serviceType = (item['service_type'] ?? widget.type).toString();
    final icon = _iconFor(serviceType);

    final vehicle = (item['vehicle_name'] ?? '').toString();
    final route = (item['route_name'] ?? '').toString();
    final time = _hm((item['leaving_at'] ?? '').toString());
    final isAc = (item['is_ac'] ?? 0) == 1;
    final tab = (item['default_tab'] ?? 'cabin').toString();

    final hasSeats = (item['total_seats'] ?? 0) > 0;
    final seatAvail = (item['seat_available'] ?? 0) as int;
    final cabinAvail = (item['cabin_available'] ?? 0) as int;
    final availability = hasSeats ? seatAvail : cabinAvail;
    final label = hasSeats ? 'Seats' : 'Cabins';

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50, // blue-ish background
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: Colors.blue.withOpacity(.15)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Left icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withOpacity(.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 26, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 12),

          // Middle info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vehicle.isEmpty ? 'Unnamed Vehicle' : vehicle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  route,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade700),
                ),
                const SizedBox(height: 4),
                Wrap( // more flexible than Row on tiny widths
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.blueGrey.shade700),
                        const SizedBox(width: 4),
                        Text('Departure $time', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700)),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.route, size: 14, color: Colors.blueGrey.shade700),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            (item['stoppages'] as List<dynamic>?)
                                ?.map((stop) => stop['name'].toString())
                                .join(' • ') ??
                                '',
                            style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  ],
                ),
              ],
            ),
          ),

          // Right availability
          // Right availability with icon + count
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                hasSeats ? Icons.event_seat : Icons.bed, // ✅ seat or bed icon
                size: 28,
                color: availability > 0
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
              const SizedBox(height: 4),
              Text(
                '$availability',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: availability > 0
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ],
          )

        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.type[0].toUpperCase()}${widget.type.substring(1)} trips',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(0, 0, 0, 16 + top),
          itemBuilder: (context, index) {
            if (index == 0) {
              // ✅ Full width, no side margins
              return Padding(
                padding: EdgeInsets.zero,
                child: _dateSwitcher(),
              );
            }

            if (loading && trips.isEmpty) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Loading results…'),
                  ],
                ),
              );
            }

            if (error != null && trips.isEmpty) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(child: Text(error!)),
                    TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (trips.isEmpty) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: Text('No trips found for this date.'),
                ),
              );
            }

            final item = trips[index - 1] as Map<String, dynamic>;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _goToDetails(item),
              child: _itemCard(item),
            );
          },
          separatorBuilder: (context, index) {
            // Line separator between cards
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Colors.blue.withOpacity(.15),
              ),
            );
          },
          itemCount: 1 + (trips.isEmpty ? 1 : trips.length),
        ),
      ),
    );
  }
}
