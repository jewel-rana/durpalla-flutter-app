import 'package:flutter/material.dart';

import 'booking_invoice.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9FDF0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 24),
              const Text('Payment Successful!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Thank you for your purchase.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingInvoiceScreen(booking: {
                        "invoice_no": "INV-00123",
                        "ticket_type": "Cabin A1",
                        "quantity": 1,
                        "amount": 1200,
                        "trip": {
                          "starting_point": "Dhaka",
                          "ending_point": "Barisal",
                          "schedule_date": "2025-07-10",
                          "leaving_at": "16:25",
                          "vehicle_name": "MV SUROVI 7"
                        },
                        "passenger": {
                          "name": "Jewel Rana",
                          "mobile": "017xxxxxxxx",
                          "nid": "123456789"
                        }
                      }
                      ),
                    ),
                  );
                },
                child: const Text('Back to Home'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
