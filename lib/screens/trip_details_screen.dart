import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../helpers/expiry_count_down.dart';
import '../services/api_service.dart';

class TripDetailsScreen extends StatefulWidget {
  final int tripId;

  const TripDetailsScreen({super.key, required this.tripId});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  Map<String, dynamic>? tripDetails;
  bool loading = true;
  bool _isCartSheetOpen = false;
  static const double _tileHeight = 84;
  static const double _tilePad = 10.0;

  late final ApiService api; // add this

  // UI state
  String selectedTab = 'cabin';
  int selectedFloor = 1;
  final List<Map<String, dynamic>> cartItems = [];

  int _priceOf(Map<String, dynamic> item) =>
      int.tryParse(item['fare']?.toString() ?? '0') ?? 0;
  int get _cartTotal => cartItems.fold(0, (sum, it) => sum + _priceOf(it));

  final Map<String, Timer> _expiryTimers = {}; // key: lock_id

  String _idempotencyKey() =>
      DateTime.now().microsecondsSinceEpoch.toString(); // or a UUID


  @override
  void initState() {
    super.initState();
    api = ApiService();
    _fetchTripDetails();
  }

  Future<void> _fetchTripDetails() async {
    setState(() => loading = true);
    final response = await ApiService.get('trip/${widget.tripId}');
    if (response['success'] == true) {
      final data = Map<String, dynamic>.from(response['data']);
      setState(() {
        tripDetails = data;
        selectedFloor = (data['default_floor'] as int?) ?? 1;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  void _startExpiryTimer(Map<String, dynamic> item) {
    // item must contain 'lock_id' and 'expires_at' (ISO string)
    final lockId = item['lock_id']?.toString();
    final expiresAtStr = item['expires_at']?.toString();
    if (lockId == null || expiresAtStr == null) return;

    final expiresAt = DateTime.parse(expiresAtStr).toUtc();
    final ms = expiresAt.difference(DateTime.now().toUtc()).inMilliseconds;

    // if already expired, drop immediately
    if (ms <= 0) {
      setState(() => cartItems.removeWhere((e) => e['lock_id'] == lockId));
      return;
    }

    // cancel any old timer
    _expiryTimers[lockId]?.cancel();
    _expiryTimers[lockId] = Timer(Duration(milliseconds: ms), () {
      // auto remove locally on expiry (server will also release)
      setState(() => cartItems.removeWhere((e) => e['lock_id'] == lockId));
      _expiryTimers.remove(lockId);
      // Optionally: show a toast "Item expired"
    });
  }

  Future<void> _releaseIfLocked(Map<String, dynamic> item) async {
    final lockId = item['lock_id']?.toString();
    if (lockId == null) return;
    try {
      await api.releaseLock(lockId);
    } catch (_) {
      // ignore; server may have already expired it
    } finally {
      _expiryTimers.remove(lockId)?.cancel();
    }
  }

  // ---- Utils ----------------------------------------------------------------

  String get vehicleImageUrl {
    final raw = tripDetails?['vehicle_photo'] as String? ?? 'default/launch.png';

    if (raw.startsWith('http')) {
      if (kDebugMode) print('Vehicle image URL (from API): $raw');
      return raw;
    }
    const fileBaseUrl = 'https://apigw.durpalla.com';
    final normalized = raw.startsWith('/') ? raw : '/$raw';
    final finalUrl = '$fileBaseUrl$normalized';
    if (kDebugMode) print('Vehicle image URL (constructed): $finalUrl');
    return finalUrl;
  }

  bool isInCart(Map<String, dynamic> item) =>
      cartItems.any((i) => i['item_id'] == item['item_id']);

  Future<void> toggleCartItem(Map<String, dynamic> item) async {
    final existsIdx = cartItems.indexWhere((i) => i['item_id'] == item['item_id']);
    if (existsIdx >= 0) {
      // remove -> release backend lock
      final existing = cartItems[existsIdx];
      await _releaseIfLocked(existing);
      setState(() => cartItems.removeAt(existsIdx));
      return;
    }

    // add -> request lock from backend
    final itemType = (selectedTab == 'cabin') ? 'cabin' : 'seat';
    try {
      final payload = await api.lockItem(
        tripId: widget.tripId,
        itemType: (selectedTab == 'cabin') ? 'cabin' : 'seat',
        itemId: int.parse(item['item_id'].toString()),
        idempotencyKey: _idempotencyKey(),
      );

      // merge UI fields you already use (vehicle_name, cabin_no, route_name, fare)
      final merged = {
        ...item,
        ...payload,
        // normalize meta fields if backend returned under meta
        'vehicle_name': payload['meta']?['vehicle_name'] ?? item['vehicle_name'] ?? tripDetails?['vehicle_name'],
        'cabin_no': payload['meta']?['cabin_no'] ?? item['cabin_no'],
        'route_name': payload['meta']?['route_name'] ?? tripDetails?['route_name'],
        'fare': payload['price'] ?? item['fare'],
      };

      setState(() => cartItems.add(merged));
      _startExpiryTimer(merged);

      // ensure bar visible (you already open on tap/swipe)
    } catch (e) {
      // show a small error—409/423 means unavailable
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unavailable or already locked. Please pick another.')),
        );
      }
    }
  }

  String _floorKey(int floor) {
    switch (floor) {
      case 1:
        return 'first_floor';
      case 2:
        return 'second_floor';
      case 3:
        return 'third_floor';
      case 4:
        return 'fourth_floor';
      default:
        return 'first_floor';
    }
  }

  // ---- UI Pieces ------------------------------------------------------------

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(vehicleImageUrl),
              fit: BoxFit.cover,
              onError: (_, __) => {},
            ),
          ),
          child: Image.network(
            vehicleImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Image.asset('assets/default/launch.png', fit: BoxFit.cover),
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.blueAccent.withOpacity(0.5),
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Route: ${tripDetails!['route_name']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Vehicle: ${tripDetails!['vehicle_name']}',
                    style: const TextStyle(color: Colors.white)),
                Text('Departure: ${tripDetails!['schedule_date']}',
                    style: const TextStyle(color: Colors.white)),
                Text('Service Type: ${tripDetails!['service_type']}',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildFloorDropdown() {
    final floors = (tripDetails?['floors'] as List?) ?? [];
    if (floors.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<int>(
        value: selectedFloor,
        decoration: const InputDecoration(
          labelText: 'Select Floor',
          border: OutlineInputBorder(),
        ),
        items: floors.map<DropdownMenuItem<int>>((f) {
          final m = Map<String, dynamic>.from(f);
          return DropdownMenuItem<int>(
            value: m['value'] as int,
            child: Text(m['label'].toString()),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => selectedFloor = value);
            // If you actually need to refetch per-floor from backend, call _fetchTripDetails() here.
            // For now, we use the already-loaded data per your payload.
          }
        },
      ),
    );
  }

  Widget _buildTabs() {
    final hasSeats = tripDetails?['seats'] != null;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.blue, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = 'cabin'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                      selectedTab == 'cabin' ? Colors.blue : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Cabin',
                  style: TextStyle(
                    color:
                    selectedTab == 'cabin' ? Colors.blue : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          if (hasSeats)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedTab = 'seat'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selectedTab == 'seat'
                            ? Colors.blue
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Seat',
                    style: TextStyle(
                      color:
                      selectedTab == 'seat' ? Colors.blue : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemGrid({required String kind}) {
    // kind: 'cabin' or 'seat'
    final dataKey = kind == 'seat' ? 'seats' : 'cabins';
    final itemsMap = tripDetails?[dataKey] as Map<String, dynamic>?;
    if (itemsMap == null) return Text('No $dataKey');

    final key = _floorKey(selectedFloor);
    final floorData = itemsMap[key];

    // Must be like {"1":[...], "2":[...]} for rows
    if (floorData is! Map || floorData.isEmpty) {
      return Text('No $dataKey');
    }

    final List<int> sortedRows = floorData.keys
        .map((k) => int.tryParse(k.toString()) ?? 0)
        .toList()
      ..sort();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedRows.map((rowNum) {
        final rowItems = List<Map<String, dynamic>>.from(
          (floorData['$rowNum'] as List).map((e) => Map<String, dynamic>.from(e)),
        );

        return Expanded(
          child: Column(
            children: rowItems.map<Widget>((item) {
              // handle "empty" slots for either kind
              final typeVal = item['${kind}_type'] ?? item['type'];
              if (typeVal == 'empty') return const SizedBox(height: 60);

              final isSelected = isInCart(item);

              final isDisabled =
                  (item['status']?.toString() == '0') ||
                      (item['${kind}_class'] == '$kind-disable') ||
                      (item['cabin_class'] == 'cabin-disable') || // fallback if server uses cabin_* for both
                      (item['seat_class'] == 'seat-disable');

              // display helpers
              final number = (item['${kind}_no'] ??
                  item['cabin_no'] ??
                  item['seat_no'] ??
                  '')
                  .toString();

              final isAC = (item['${kind}_is_ac'] ??
                  item['is_ac'] ??
                  item['cabin_is_ac'] ??
                  0) ==
                  1;

              final fare = item['fare'];

              return Opacity(
                opacity: isDisabled ? 0.3 : 1,
                child: IgnorePointer(
                  ignoring: isDisabled,
                  child: GestureDetector(
                    onTap: () async => await toggleCartItem(item),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.green : Colors.grey,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isAC)
                            const Align(
                              alignment: Alignment.topRight,
                              child: Text(
                                'AC',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          Text(
                            number,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (fare != null) Text('৳$fare'),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }


  Future<void> _openCartSheet() {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void removeAt(int index) async {
              final item = cartItems[index];
              await _releaseIfLocked(item);
              setState(() => cartItems.removeAt(index)); // update page
              setModalState(() {});                      // refresh sheet
              if (cartItems.isEmpty) Navigator.pop(context); // close only if empty
            }


            // ... your DraggableScrollableSheet + ListView
            //   Use removeAt(index) for delete actions
            //   Keep sticky footer with total & checkout
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (_, controller) {
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your Cart',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        controller: controller,
                        itemCount: cartItems.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          final vehicle = item['vehicle_name'] ?? tripDetails?['vehicle_name'] ?? '';
                          final cabinNo = item['cabin_no'] ?? 'Cabin';
                          final route = item['route_name'] ?? tripDetails?['route_name'] ?? '';
                          final price = _priceOf(item);

                          return Dismissible(
                            key: ValueKey('cart_${item['item_id']}_${item['cabin_no']}'),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => removeAt(index),
                            background: Container(
                              color: Colors.red.shade100,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: const Icon(Icons.delete, color: Colors.red),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(cabinNo, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('৳$price',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700, color: Colors.green)),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.directions_boat_outlined, size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(vehicle, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.alt_route, size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(route, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                  if (item['expires_at'] != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.timer_outlined, size: 16),
                                        const SizedBox(width: 6),
                                        ExpiryCountdown(expiresAtIso: item['expires_at'].toString()),
                                      ],
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => removeAt(index), // <-- no pop here
                                tooltip: 'Remove',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Sticky footer with total + checkout
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Subtotal',
                                    style: TextStyle(color: Colors.black54)),
                                Text(
                                  '৳$_cartTotal',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: Navigate to checkout screen
                            },
                            icon: const Icon(Icons.lock_outline),
                            label: const Text('Checkout'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item, {required String kind}) {
    final typeVal = (item['${kind}_type'] ?? item['type'] ?? '').toString();
    final isEmpty = typeVal == 'empty';

    // keep alignment for walkways/empty slots, no UI/price
    if (isEmpty) return const SizedBox(height: _tileHeight);

    final isSelected = isInCart(item);
    final isDisabled =
        item['status']?.toString() == '0' ||
            item['${kind}_class'] == '$kind-disable' ||
            item['cabin_class'] == 'cabin-disable' ||
            item['seat_class'] == 'seat-disable';

    final number = (item['${kind}_no'] ?? item['cabin_no'] ?? item['seat_no'] ?? '').toString();

    final isAC = (item['${kind}_is_ac'] ??
        item['is_ac'] ??
        item['cabin_is_ac'] ?? 0) == 1;

    final num? fareNum = (item['fare'] is String)
        ? num.tryParse(item['fare'])
        : item['fare'] as num?;

    return Opacity(
      opacity: isDisabled ? 0.35 : 1,
      child: IgnorePointer(
        ignoring: isDisabled,
        child: GestureDetector(
          onTap: () async => await toggleCartItem(item),
          child: SizedBox(
            height: _tileHeight,
            child: Stack(
              children: [
                // Card
                Container(
                  margin: const EdgeInsets.all(6),
                  padding: const EdgeInsets.all(_tilePad),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (number.isNotEmpty)
                        Text(
                          number,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      if (fareNum != null && fareNum > 0)
                        Text(
                          '৳${fareNum.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),

                // AC badge (overlaps; doesn't change height)
                if (isAC)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
                        ],
                      ),
                      child: const Text(
                        'AC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // ---- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    const double _tileHeight = 84;
    const double _tilePad = 10;
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Details')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : (tripDetails == null)
          ? const Center(child: Text('Trip details not found'))
          : SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFloorDropdown(),
            const SizedBox(height: 16),
            _buildTabs(),
            const SizedBox(height: 16),
            if (selectedTab == 'cabin' || selectedTab == 'seat')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _buildItemGrid(kind: selectedTab), // 👈 one builder for both
              ),
          ],
        ),
      ),

      // ✅ No empty space when cart is empty. Shows fixed-height bar when items exist.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Material(
          elevation: 10,
          color: Colors.white,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              if (_isCartSheetOpen) return;
              _isCartSheetOpen = true;
              await _openCartSheet();
              _isCartSheetOpen = false;
            },
            onVerticalDragUpdate: (details) async {
              // swipe up to open (negative delta)
              if (details.primaryDelta != null && details.primaryDelta! < -6) {
                if (_isCartSheetOpen) return;
                _isCartSheetOpen = true;
                await _openCartSheet();
                _isCartSheetOpen = false;
              }
            },
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cartItems.isEmpty
                              ? 'Your cart is empty'
                              : '${cartItems.length} item${cartItems.length > 1 ? 's' : ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text('Subtotal: ৳$_cartTotal',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            )),
                      ],
                    ),
                  ),
                  const Row(
                    children: [
                      Text('Swipe up or tap'),
                      SizedBox(width: 6),
                      Icon(Icons.expand_less),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

    );
  }
}