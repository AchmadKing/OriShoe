import 'dart:convert';
import 'package:http/http.dart' as http;

class BankService {
  // GANTI URL INI dengan URL dari npoint.io yang Anda buat di Langkah 1
  static const String _apiUrl = 'https://api.npoint.io/739af9c5eae754e03cb6';

  Future<Map<String, dynamic>?> getBankInfo() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching bank info: $e");
      return null;
    }
  }
}