import 'package:durpalla/screens/search_result_screen.dart';
import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  final String transportType;
  const BookingScreen({
    super.key,
    required this.transportType,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  // Put these in your State
  DateTime? departDate = DateTime.now();
  DateTime? returnDate;

  // final fromController = TextEditingController();
  // final toController = TextEditingController();

  void swapLocations() {
    final temp = fromController.text;
    fromController.text = toController.text;
    toController.text = temp;
  }


  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String formatDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";


  Future<void> _pickDepart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: departDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        departDate = picked;
        // keep return >= depart
        if (returnDate != null && returnDate!.isBefore(picked)) {
          returnDate = picked;
        }
      });
    }
  }

  Future<void> _pickReturn() async {
    final base = departDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: returnDate ?? base,
      firstDate: base, // cannot return before depart
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => returnDate = picked);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.transportType} booking')),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Search your trip',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
            ),
            const SizedBox(height: 15),

// FROM Field
            TextField(
              controller: fromController,
              decoration: const InputDecoration(
                labelText: 'From',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),

            SizedBox(height: 5,),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(50), // Rounded corners
                  border: Border.all(color: Colors.blue, width: 2), // Optional border
                ),
                child: IconButton(
                  icon: const Icon(Icons.swap_vert, color: Colors.white),
                  onPressed: swapLocations,
                ),
              ),
            ),

            SizedBox(height: 5,),

            TextField(
              controller: toController,
              decoration: const InputDecoration(
                labelText: 'To',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),

            const SizedBox(height: 16),

            // Replace your Row with this:
            Row(
              children: [
                // Depart Date
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    onTap: _pickDepart,
                    controller: TextEditingController(
                      text: departDate != null ? _fmt(departDate!) : '',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Depart Date',
                      prefixIcon: Icon(Icons.calendar_today),
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Return Date
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    onTap: departDate == null ? null : _pickReturn, // enable after depart
                    controller: TextEditingController(
                      text: returnDate != null ? _fmt(returnDate!) : '',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Return Date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      hintText: 'YYYY-MM-DD',
                      border: const OutlineInputBorder(),
                      // subtle cue if disabled until depart picked
                      enabled: departDate != null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (fromController.text.isNotEmpty &&
                      toController.text.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SearchResultScreen(
                          type: widget.transportType.toLowerCase(),
                          from: fromController.text,
                          to: toController.text,
                          date: formatDate(departDate ?? DateTime.now()),
                          return_date: returnDate != null
                          ? returnDate!.toIso8601String().split('T')[0]
                          : null,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please complete all fields'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600, // ✅ background color
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ), // ✅ inner padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // optional rounded corners
                  ),
                ),
                child: const Text(
                  'Search Trips',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}