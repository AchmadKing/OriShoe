import 'package:hive/hive.dart';

class SessionBox {
  static const String _boxName = 'sessionBox';
  static const String _keyCurrentUser = 'currentUser';

  // Membuka box session
  static Future<Box> _openBox() async {
    return await Hive.openBox(_boxName);
  }

  // Simpan username yang sedang login
  static Future<void> login(String username) async {
    final box = await _openBox();
    await box.put(_keyCurrentUser, username);
  }

  // Ambil username yang sedang login
  static Future<String?> getCurrentUser() async {
    final box = await _openBox();
    return box.get(_keyCurrentUser);
  }

  // Logout / hapus session
  static Future<void> logout() async {
    final box = await _openBox();
    await box.delete(_keyCurrentUser);
  }
}
