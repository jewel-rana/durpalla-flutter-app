import 'package:flutter/material.dart';

import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> cartItems = [
      {'title': 'Ticket: Dhaka to Barisal', 'quantity': 2, 'price': 1200},
      {'title': 'Ticket: Khulna to Dhaka', 'quantity': 1, 'price': 700},
    ];

    double total = cartItems.fold(
        0, (sum, item) => sum + (item['quantity'] * item['price']));

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Cart',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(item['title']),
                      subtitle: Text('Quantity: ${item['quantity']}'),
                      trailing: Text('${item['quantity'] * item['price']} BDT'),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 32),
            Text('Total: $total BDT',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                  );
                },
                child: const Text('Proceed to Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
