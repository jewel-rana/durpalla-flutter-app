import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class BookingInvoiceScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingInvoiceScreen({super.key, required this.booking});

  Future<void> _downloadPDF(BuildContext context) async {
    final invoiceNo = booking['invoice_no'];
    final response = await http.get(Uri.parse('http://your-backend-url/api/invoice-pdf/$invoiceNo'));

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$invoiceNo.pdf');
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF downloaded to ${file.path}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to download PDF')),
      );
    }
  }

  Future<void> _shareInvoice(BuildContext context) async {
    final invoiceNo = booking['invoice_no'];
    final response = await http.get(Uri.parse('http://your-backend-url/api/invoice-pdf/$invoiceNo'));

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$invoiceNo.pdf');
      await file.writeAsBytes(bytes);

      Share.shareXFiles([XFile(file.path)], text: 'Invoice: $invoiceNo');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to share invoice')),
      );
    }
  }

  Future<void> _printInvoice(BuildContext context) async {
    final invoiceNo = booking['invoice_no'];
    final response = await http.get(Uri.parse('http://your-backend-url/api/invoice-pdf/$invoiceNo'));

    if (response.statusCode == 200) {
      final Uint8List pdfBytes = response.bodyBytes;
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch PDF for printing')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = booking['trip'];
    final passenger = booking['passenger'];
    final invoiceNo = booking['invoice_no'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        title: const Text('Invoice'),
        backgroundColor: const Color(0xFF0061A8),
        elevation: 4,
        actions: [
          IconButton(icon: const Icon(Icons.download), tooltip: 'Download PDF', onPressed: () => _downloadPDF(context)),
          IconButton(icon: const Icon(Icons.share), tooltip: 'Share', onPressed: () => _shareInvoice(context)),
          IconButton(icon: const Icon(Icons.print), tooltip: 'Print', onPressed: () => _printInvoice(context)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Booking Confirmed 🎉',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0061A8)),
                    ),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: "Test",
                      size: 120,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text('Invoice #$invoiceNo', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _sectionCard(
              title: 'Trip Info',
              color: Colors.indigo.shade50,
              children: [
                _infoRow('From → To:', '${trip['starting_point']} → ${trip['ending_point']}', highlight: false),
                _infoRow('Date:', trip['schedule_date'], highlight: false),
                _infoRow('Departure:', trip['leaving_at'], highlight: false),
                _infoRow('Launch:', trip['vehicle_name'], highlight: false),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Passenger Info',
              color: Colors.green.shade50,
              children: [
                _infoRow('Name:', passenger['name'], highlight: false),
                _infoRow('Mobile:', passenger['mobile'], highlight: false),
                _infoRow('NID:', passenger['nid'], highlight: false),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Ticket Details',
              color: Colors.orange.shade50,
              children: [
                _infoRow('Ticket Type:', booking['ticket_type'], highlight: false),
                _infoRow('Quantity:', booking['quantity'].toString(), highlight: false),
                _infoRow('Amount:', '৳ ${booking['amount']}', highlight: true),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('Go to Home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0061A8),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _infoRow(String label, String? value, {required bool highlight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(flex: 3, child: Text(value ?? '-')),
        ],
      ),
    );
  }
}

Widget _sectionCard({required String title, required List<Widget> children, required Color color}) {
  return Card(
    color: color,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}

Widget _infoRow(String label, String? value, {bool highlight = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(flex: 2, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
        Expanded(
          flex: 3,
          child: Text(
            value ?? '-',
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              fontSize: highlight ? 16 : 14,
              color: highlight ? Colors.deepOrange : Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}
