import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/cart_line.dart';

class ReceiptScreen extends StatelessWidget {
  final String customerName;
  final String? customerPhone;
  final DateTime dateTime;
  final List<CartLine> lines;
  final double subtotal;
  final double tax;
  final double total;
  final bool isCredit;

  const ReceiptScreen({
    super.key,
    required this.customerName,
    this.customerPhone,
    required this.dateTime,
    required this.lines,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.isCredit,
  });

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF2E7D32);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        title: const Text('Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false),
          tooltip: 'Close & Go to Dashboard',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _receiptCard(context, primary),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Print coming soon...')),
                      );
                    },
                    icon: const Icon(Icons.print, color: Colors.white),
                    label: const Text('Print', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primary),
                      foregroundColor: primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await _generateAndSharePDF(context);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share PDF'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primary),
                foregroundColor: primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false),
              child: const Text('Finish & Go to Dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptCard(BuildContext context, Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: primary.withOpacity(.15),
                child: const Icon(Icons.shopping_basket, color: Color(0xFF2E7D32), size: 32),
              ),
              const SizedBox(height: 8),
              const Text('Green Fresh', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: Color(0xFF2E7D32))),
              const SizedBox(height: 4),
              const Text('123 Main Street, Anytown', style: TextStyle(color: Colors.black54)),
              const Text('(555) 555-5555', style: TextStyle(color: Colors.black54)),
            ],
          ),
          const Divider(height: 24, color: Colors.black12),

          // Customer Info
          Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Customer:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(customerName),
                  if (customerPhone != null && customerPhone!.isNotEmpty)
                    Text(customerPhone!, style: const TextStyle(color: Colors.black54)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('Date:', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(_fmtDate(dateTime)),
                Text(_fmtTime(dateTime), style: const TextStyle(color: Colors.black54)),
              ]),
            ],
          ),

          const Divider(height: 24, color: Colors.black12),

          // Items
          Row(
            children: const [
              Expanded(child: Text('Item', style: TextStyle(fontWeight: FontWeight.w700))),
              SizedBox(width: 60, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700))),
              SizedBox(width: 80, child: Text('Price', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 8),
          for (final line in lines) ...[
            Row(
              children: [
                Expanded(child: Text(line.product.name)),
                SizedBox(width: 60, child: Text('${line.qty}', textAlign: TextAlign.center)),
                SizedBox(width: 80, child: Text('Rs ${(line.product.price * line.qty).toStringAsFixed(2)}', textAlign: TextAlign.end)),
              ],
            ),
            const SizedBox(height: 6),
          ],
          const Divider(height: 24, color: Colors.black12),

          _totalRow('Subtotal', subtotal),
          _totalRow('Tax (8%)', tax),
          const Divider(height: 24, color: Colors.black12),
          _totalRow('Total', total, bold: true, color: primary),

          if (isCredit)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text('Pay Later sale (added to customer’s due).', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
            ),

          const SizedBox(height: 12),
          const Text('Thank you for shopping with us!', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Future<void> _generateAndSharePDF(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(children: [
                  pw.Text('Green Fresh', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                  pw.Text('123 Main Street, Anytown'),
                  pw.Text('(555) 555-5555'),
                  pw.SizedBox(height: 12),
                ]),
              ),
              pw.Divider(),
              pw.Text('Customer: $customerName'),
              if (customerPhone != null && customerPhone!.isNotEmpty) pw.Text('Phone: $customerPhone'),
              pw.Text('Date: ${_fmtDate(dateTime)} ${_fmtTime(dateTime)}'),
              pw.Divider(),

              pw.Table.fromTextArray(
                headers: ['Item', 'Qty', 'Price'],
                data: lines.map((l) => [l.product.name, '${l.qty}', 'Rs ${(l.product.price * l.qty).toStringAsFixed(2)}']).toList(),
              ),

              pw.Divider(),
              pw.Text('Subtotal: Rs ${subtotal.toStringAsFixed(2)}'),
              pw.Text('Tax (8%): Rs ${tax.toStringAsFixed(2)}'),
              pw.Text('Total: Rs ${total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              if (isCredit)
                pw.Text('Note: Pay Later sale', style: pw.TextStyle(color: PdfColors.red)),
              pw.SizedBox(height: 16),
              pw.Center(child: pw.Text('Thank you for shopping with us!')),
            ],
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'Green Fresh Receipt');
  }

  Widget _totalRow(String label, double value, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black87)),
        Text(
          'Rs ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? Colors.black87,
            fontSize: bold ? 16 : 14,
          ),
        ),
      ],
    );
  }

  String _fmtDate(DateTime dt) => '${dt.year}-${_2(dt.month)}-${_2(dt.day)}';
  String _fmtTime(DateTime dt) => '${_2(dt.hour)}:${_2(dt.minute)}';
  String _2(int n) => n.toString().padLeft(2, '0');
}
