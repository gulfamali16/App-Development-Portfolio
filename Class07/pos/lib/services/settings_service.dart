import 'package:shared_preferences/shared_preferences.dart';

class StoreInfo {
  final String name;
  final String phone;
  final String address;

  const StoreInfo({required this.name, required this.phone, required this.address});

  StoreInfo copyWith({String? name, String? phone, String? address}) {
    return StoreInfo(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }
}

class SettingsService {
  static const _kStoreName = 'store_name';
  static const _kStorePhone = 'store_phone';
  static const _kStoreAddress = 'store_address';
  static const _kLastBackupIso = 'last_backup_iso';

  static Future<StoreInfo> loadStore() async {
    final sp = await SharedPreferences.getInstance();
    return StoreInfo(
      name: sp.getString(_kStoreName) ?? 'Green Fresh Grocer',
      phone: sp.getString(_kStorePhone) ?? '+1 234 567 890',
      address: sp.getString(_kStoreAddress) ?? '123 Fresh St, Green Valley',
    );
  }

  static Future<void> saveStore(StoreInfo info) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kStoreName, info.name);
    await sp.setString(_kStorePhone, info.phone);
    await sp.setString(_kStoreAddress, info.address);
  }

  static Future<DateTime?> loadLastBackup() async {
    final sp = await SharedPreferences.getInstance();
    final iso = sp.getString(_kLastBackupIso);
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  static Future<void> saveLastBackup(DateTime dt) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kLastBackupIso, dt.toIso8601String());
  }
}
