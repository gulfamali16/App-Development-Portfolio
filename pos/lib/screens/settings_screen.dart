import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../services/database_service.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  StoreInfo _store = const StoreInfo(
      name: 'Green Fresh Grocer',
      phone: '+1 234 567 890',
      address: '123 Fresh St, Green Valley');
  DateTime? _lastBackup;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await SettingsService.loadStore();
    final last = await SettingsService.loadLastBackup();
    setState(() {
      _store = s;
      _lastBackup = last;
      _loading = false;
    });
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Never';
    final d = dt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _editStore() async {
    final nameCtrl = TextEditingController(text: _store.name);
    final phoneCtrl = TextEditingController(text: _store.phone);
    final addressCtrl = TextEditingController(text: _store.address);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Row(
                children: [
                  const Text('Edit Store Info',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                decoration:
                const InputDecoration(labelText: 'Store Name', filled: true),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration:
                const InputDecoration(labelText: 'Phone', filled: true),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                decoration:
                const InputDecoration(labelText: 'Address', filled: true),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final updated = _store.copyWith(
                      name: nameCtrl.text.trim().isEmpty
                          ? _store.name
                          : nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim().isEmpty
                          ? _store.phone
                          : phoneCtrl.text.trim(),
                      address: addressCtrl.text.trim().isEmpty
                          ? _store.address
                          : addressCtrl.text.trim(),
                    );
                    await SettingsService.saveStore(updated);
                    if (mounted) {
                      setState(() => _store = updated);
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Save',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (saved == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Store info updated')));
    }
  }

  Future<void> _changePin() async {
    final pinCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Login PIN'),
        content: TextField(
          controller: pinCtrl,
          decoration: const InputDecoration(
            labelText: 'New PIN',
            hintText: 'e.g., 3030',
          ),
          keyboardType: TextInputType.number,
          obscureText: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final newPin = pinCtrl.text.trim();
      if (newPin.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN cannot be empty')));
        return;
      }
      try {
        final db = await DatabaseService.database;
        await db.update('user', {'pin': newPin},
            where: 'id = ?', whereArgs: [1]);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('PIN updated')));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to update PIN: $e')));
      }
    }
  }

  Future<void> _exportBackup() async {
    try {
      final dbPath = p.join(await getDatabasesPath(), 'pos_app.db');
      final srcFile = File(dbPath);
      if (!await srcFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Database file not found')));
        return;
      }

      final docs = await getApplicationDocumentsDirectory();
      final stamp = DateTime.now();
      final outName =
          'pos_backup_${stamp.year}${stamp.month.toString().padLeft(2, '0')}${stamp.day.toString().padLeft(2, '0')}_${stamp.hour.toString().padLeft(2, '0')}${stamp.minute.toString().padLeft(2, '0')}${stamp.second.toString().padLeft(2, '0')}.db';
      final outPath = p.join(docs.path, outName);

      await srcFile.copy(outPath);

      await SettingsService.saveLastBackup(stamp);
      setState(() => _lastBackup = stamp);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Backup saved: $outName'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111812),
        elevation: 0.5,
        automaticallyImplyLeading: canPop,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (canPop) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          },
        ),
        title: const Text('Settings & Profile',
            style: TextStyle(
                color: Color(0xFF111812), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // 🔐 Security Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    offset: Offset(0, 1))
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Security',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 6),
                _rowTile(
                  icon: Icons.key,
                  title: 'Change Login PIN',
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 18, color: Colors.black45),
                  onTap: _changePin,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 👨‍💻 About Developer Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    offset: Offset(0, 1))
              ],
            ),
            padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'About Developer',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text('👤 Gulfam Ali',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('📧 gulfamoffi62@gmail.com',
                    style:
                    TextStyle(fontSize: 14, color: Colors.black54)),
                SizedBox(height: 8),
                Text(
                  'Thank you for using Green Fresh POS!',
                  style:
                  TextStyle(fontSize: 13, color: Colors.black45),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 💾 Data Management
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    offset: Offset(0, 1))
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Data Management',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _exportBackup,
                      icon: const Icon(Icons.backup, color: Colors.white),
                      label: const Text('Export Data (Backup)',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: Column(
                    children: [
                      Text('Last Backup: ${_formatDate(_lastBackup)}',
                          style:
                          const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 4),
                      const Text(
                        'This creates a local SQLite copy inside app documents.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.black45),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _rowTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF2E7D32)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15, color: Color(0xFF111812))),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
