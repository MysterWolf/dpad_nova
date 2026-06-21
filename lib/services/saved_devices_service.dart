import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_device.dart';

class SavedDevicesService {
  static const _key = 'saved_devices';

  Future<List<SavedDevice>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>().map(SavedDevice.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist(List<SavedDevice> devices, SharedPreferences prefs) =>
      prefs.setString(_key, jsonEncode(devices.map((d) => d.toJson()).toList()));

  Future<List<SavedDevice>> add(List<SavedDevice> current, SavedDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = [...current.where((d) => d.ip != device.ip), device];
    await _persist(updated, prefs);
    return updated;
  }

  Future<List<SavedDevice>> remove(List<SavedDevice> current, String ip) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = current.where((d) => d.ip != ip).toList();
    await _persist(updated, prefs);
    return updated;
  }

  Future<List<SavedDevice>> rename(
      List<SavedDevice> current, String ip, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final updated =
        current.map((d) => d.ip == ip ? d.copyWith(name: name) : d).toList();
    await _persist(updated, prefs);
    return updated;
  }

  Future<List<SavedDevice>> updateLastSeen(
      List<SavedDevice> current, String ip) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = current
        .map((d) => d.ip == ip ? d.copyWith(lastSeen: DateTime.now()) : d)
        .toList();
    await _persist(updated, prefs);
    return updated;
  }
}
