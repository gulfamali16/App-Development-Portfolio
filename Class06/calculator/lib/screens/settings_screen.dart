import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ---------------- Core: RESET ----------------
  Future<void> _confirmAndResetData() async {
    final bool? shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1231),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Data Reset', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to clear ALL saved GPA, CGPA, and semester data? This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ All application data has been reset!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // ---------------- Contact Dev (WhatsApp) ----------------
  Future<void> _launchWhatsApp() async {
    // NOTE: Pakistan code zyada common hota hai +92; aapka number Afghanistan code +93 me diya gaya hai.
    // Jo sahi ho, wahi rakho.
    const String phoneNumber = '+933280130155';
    final String message = Uri.encodeComponent("Hello Gulfam, I am using your COMSATS GPA App.");
    final Uri whatsappUrl = Uri.parse("https://wa.me/$phoneNumber?text=$message");

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open WhatsApp. Ensure the app is installed.")),
        );
      }
    }
  }

  // ---------------- Export PDF: Public entry ----------------
  Future<void> _exportPdf() async {
    // Bottom sheet: Share ya Save?
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1231),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 12),
            const Text("Export as PDF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            const Text("Choose what to do with your GPA/CGPA report", style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text("Share / Print", style: TextStyle(color: Colors.white)),
              subtitle: const Text("WhatsApp, Gmail, Drive or print", style: TextStyle(color: Colors.white54)),
              onTap: () async {
                Navigator.pop(context);
                await _sharePdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_alt, color: Colors.white),
              title: const Text("Save to device", style: TextStyle(color: Colors.white)),
              subtitle: const Text("Save in app Documents folder", style: TextStyle(color: Colors.white54)),
              onTap: () async {
                Navigator.pop(context);
                await _savePdfToDevice();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ---------------- Helpers: Gather data ----------------
  Future<Map<String, dynamic>> _loadPrefsForReport() async {
    final prefs = await SharedPreferences.getInstance();

    // Try multiple likely keys; keep graceful fallback
    double? getDouble(List<String> keys) {
      for (final k in keys) {
        final v = prefs.getDouble(k);
        if (v != null) return v;
      }
      return null;
    }

    String? getString(List<String> keys) {
      for (final k in keys) {
        final v = prefs.getString(k);
        if (v != null && v.trim().isNotEmpty) return v;
      }
      return null;
    }

    final now = DateTime.now();

    return {
      "generatedAt": now,
      "studentName": getString(["student_name", "name", "user_name"]) ?? "N/A",
      "regNo": getString(["reg_no", "roll_no", "registration"]) ?? "N/A",
      "campus": getString(["campus", "institute"]) ?? "COMSATS",
      "program": getString(["program", "degree"]) ?? "BS (CS)",
      "currentCGPA": getDouble(["lastCGPA", "currentCGPA"]) ?? 0.0,
      "pastCredits": getDouble(["past_credits", "completedCredits", "completed_credit_hours"]) ?? 0.0,
      "lastSGPA": getDouble(["lastSGPA", "sgpa", "latest_sgpa"]),
      "lastSemCredits": getDouble(["last_sem_credits", "current_semester_credits", "new_credits"]),
      "targetCGPA": getDouble(["targetCGPA", "target_cgpa"]),
    };
  }

  // ---------------- Build PDF bytes ----------------
  Future<Uint8List> _buildReportPdfBytes() async {
    final data = await _loadPrefsForReport();

    final themePurple = PdfColor.fromHex('#6C00F0');
    final darkBg = PdfColor.fromHex('#0B021B');
    final cardBg = PdfColor.fromHex('#1E1033');
    final textLight = PdfColor.fromHex('#FFFFFF');
    final textMuted = PdfColor.fromHex('#C7C7D1');

    final doc = pw.Document();

    pw.Widget statCard(String title, String value) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: cardBg,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: themePurple, width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style: pw.TextStyle(color: textMuted, fontSize: 10)),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style: pw.TextStyle(
                  color: textLight,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                )),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          buildBackground: (ctx) => pw.Container(color: darkBg),
          margin: const pw.EdgeInsets.all(24),
        ),
        build: (ctx) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: cardBg,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: themePurple, width: 1.2),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Sacreino • GPA/CGPA Report',
                          style: pw.TextStyle(
                              color: textLight,
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated: ${data["generatedAt"]}',
                        style: pw.TextStyle(color: textMuted, fontSize: 10),
                      ),
                    ]),
                pw.Container(
                  padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: themePurple,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text('COMSATS',
                      style: pw.TextStyle(
                        color: textLight,
                        fontWeight: pw.FontWeight.bold,
                      )),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Student block
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: cardBg,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: PdfColor.fromHex('#3B2A5B'), width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Student Details',
                    style: pw.TextStyle(
                        color: textLight,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColor.fromHex('#2A1E42')),
                pw.SizedBox(height: 8),
                pw.Row(children: [
                  pw.Expanded(child: statCard('Name', '${data["studentName"]}')),
                  pw.SizedBox(width: 10),
                  pw.Expanded(child: statCard('Reg No', '${data["regNo"]}')),
                  pw.SizedBox(width: 10),
                  pw.Expanded(child: statCard('Program', '${data["program"]}')),
                  pw.SizedBox(width: 10),
                  pw.Expanded(child: statCard('Campus', '${data["campus"]}')),
                ]),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Stats row
          pw.Row(children: [
            pw.Expanded(
              child: statCard(
                  'Current CGPA',
                  (data["currentCGPA"] as double).toStringAsFixed(2)),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: statCard(
                  'Completed Credits',
                  (data["pastCredits"] as double).toStringAsFixed(1)),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: statCard(
                  'Last SGPA',
                  data["lastSGPA"] == null
                      ? 'N/A'
                      : (data["lastSGPA"] as double).toStringAsFixed(2)),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: statCard(
                  'Last Sem Credits',
                  data["lastSemCredits"] == null
                      ? 'N/A'
                      : (data["lastSemCredits"] as double).toStringAsFixed(1)),
            ),
          ]),
          pw.SizedBox(height: 12),

          pw.Row(children: [
            pw.Expanded(
              child: statCard(
                'Target CGPA (if set)',
                data["targetCGPA"] == null
                    ? 'N/A'
                    : (data["targetCGPA"] as double).toStringAsFixed(2),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: cardBg,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: themePurple, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Notes',
                        style: pw.TextStyle(color: textMuted, fontSize: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'This report was generated from your local app data (SharedPreferences).',
                      style: pw.TextStyle(color: textLight, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ]),

          pw.SizedBox(height: 18),

          // Legend / Grading table (COMSATS)
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: cardBg,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: PdfColor.fromHex('#3B2A5B'), width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('COMSATS Grading (Reference)',
                    style: pw.TextStyle(
                        color: textLight,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColor.fromHex('#2A1E42')),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#2A1E42')),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Grade', style: pw.TextStyle(color: textLight, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Points', style: pw.TextStyle(color: textLight, fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...[
                      ['A', '4.00'],
                      ['A-', '3.67'],
                      ['B+', '3.33'],
                      ['B', '3.00'],
                      ['B-', '2.67'],
                      ['C+', '2.33'],
                      ['C', '2.00'],
                      ['D', '1.00'],
                      ['F', '0.00'],
                    ].map((r) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(r[0], style: pw.TextStyle(color: textLight)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(r[1], style: pw.TextStyle(color: textLight)),
                        ),
                      ],
                    )),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          pw.Center(
            child: pw.Text(
              '— End of Report —',
              style: pw.TextStyle(color: textMuted, fontSize: 10),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ---------------- Share PDF (Printing / share sheet) ----------------
  Future<void> _sharePdf() async {
    try {
      final bytes = await _buildReportPdfBytes();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Sacreino_GPA_Report.pdf',
      );
    } catch (e) {
      _toast("Failed to share PDF: $e");
    }
  }

  // ---------------- Save PDF to device (App Docs folder) ----------------
  Future<void> _savePdfToDevice() async {
    try {
      final bytes = await _buildReportPdfBytes();
      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/Sacreino_GPA_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final f = File(filePath);
      await f.writeAsBytes(bytes);

      _toast("Saved: $filePath");
    } catch (e) {
      _toast("Failed to save PDF: $e");
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B021B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Settings & Tools', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _settingTile(
            Icons.restore,
            "Reset All Data",
            "Clear all saved GPA, CGPA, and semester data permanently.",
            _confirmAndResetData,
          ),
          _settingTile(
            Icons.picture_as_pdf,
            "Export Report as PDF",
            "Generate your GPA/CGPA summary report and share or save.",
            _exportPdf,
          ),
          _developerTile(
            Icons.developer_mode,
            "Gulfam Ali (Developer)",
            "+933280130155",
            _launchWhatsApp,
          ),
        ],
      ),
    );
  }

  // Generic Setting Tile
  Widget _settingTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      color: const Color(0xFF1E1033),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF6C00F0)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        onTap: onTap,
      ),
    );
  }

  // Dedicated Developer Tile with WhatsApp Icon
  Widget _developerTile(IconData icon, String title, String number, VoidCallback onTap) {
    return Card(
      color: const Color(0xFF1E1033),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.amberAccent),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(number, style: const TextStyle(color: Colors.white70)),
        onTap: onTap,
      ),
    );
  }
}
