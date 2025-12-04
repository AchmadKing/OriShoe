import 'package:hive/hive.dart';
import '../models/user_model.dart';

class UserBox {
  static Box<UserModel> getUserBox() => Hive.box<UserModel>('userBox');

  static Box getSessionBox() => Hive.box('sessionBox');

  // Simpan user yang sedang login
  static Future<void> saveSession(UserModel user) async {
    final sessionBox = getSessionBox();
    await sessionBox.put('currentUser', {
      'username': user.username,
      'email': user.email,
      'password': user.password,
    });
    await sessionBox.flush(); // pastikan tersimpan ke disk
  }

  // Ambil user yang sedang login (kalau ada)
  static UserModel? getCurrentUser() {
    final sessionBox = getSessionBox();
    final data = sessionBox.get('currentUser');
    if (data != null) {
      return UserModel(
        username: data['username'],
        email: data['email'],
        password: data['password'],
      );
    }
    return null;
  }

  // Hapus session saat logout
  static Future<void> clearSession() async {
    final sessionBox = getSessionBox();
    await sessionBox.delete('currentUser');
    await sessionBox.flush();
  }
}
