import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// CurrencyService:
/// - Mengambil data kurs real dari API (base USD)
/// - Bisa konversi dan format angka otomatis
/// - Bisa sinkron antar halaman lewat listener
class CurrencyService {
  CurrencyService._internal();
  static final CurrencyService instance = CurrencyService._internal();

  // API sumber kurs (base USD)
  final String _apiUrl =
      'https://v6.exchangerate-api.com/v6/30cf6d55f5de9fe0fdee058e/latest/USD';

  Map<String, double> _rates = {};
  DateTime? _lastFetch;
  Duration cacheDuration = const Duration(minutes: 60);

  // ==== Tambahan: state sinkronisasi ====
  String _selectedCurrency = 'IDR';
  final StreamController<String> _currencyController = StreamController.broadcast();

  String get selectedCurrency => _selectedCurrency;
  Stream<String> get currencyStream => _currencyController.stream;

  void setCurrency(String newCurrency) {
    if (_selectedCurrency != newCurrency) {
      _selectedCurrency = newCurrency;
      _currencyController.add(newCurrency);
    }
  }

  void addListener(void Function(String) listener) {
    _currencyController.stream.listen(listener);
  }

  // =====================================================

  bool get hasRates => _rates.isNotEmpty;

  /// Pastikan kurs sudah tersedia (ambil API jika cache habis)
  Future<void> ensureRates() async {
    if (_rates.isEmpty ||
        _lastFetch == null ||
        DateTime.now().difference(_lastFetch!) > cacheDuration) {
      await _fetchRates();
    }
  }

  Future<void> _fetchRates() async {
    try {
      final resp =
          await http.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final Map<String, dynamic> jsonBody = json.decode(resp.body);
        final Map<String, dynamic>? rates =
            jsonBody['conversion_rates'] as Map<String, dynamic>?;
        if (rates != null) {
          _rates = rates
              .map((k, v) => MapEntry(k.toUpperCase(), (v as num).toDouble()));
          _lastFetch = DateTime.now();
          return;
        }
      }
      throw Exception('Failed to fetch rates, status: ${resp.statusCode}');
    } catch (e) {
      // kalau gagal, tetap jalan pakai default agar UI tidak error
      if (_rates.isEmpty) {
        _rates = {'USD': 1.0, 'IDR': 16000.0, 'JPY': 150.0, 'EUR': 0.9};
      }
    }
  }

  /// Ambil rate per kode (misal 'IDR', 'USD', dll)
  double getRate(String code) {
    final c = code.toUpperCase();
    return _rates[c] ?? 1.0;
  }

  /// Konversi nilai antar mata uang
  double convert(double amount, String fromCode, String toCode) {
    final from = fromCode.toUpperCase();
    final to = toCode.toUpperCase();

    final rateFrom = getRate(from);
    final rateTo = getRate(to);
    if (rateFrom == 0) return 0.0;

    final amountUsd = (from == 'USD') ? amount : (amount / rateFrom);
    final amountTo = (to == 'USD') ? amountUsd : (amountUsd * rateTo);
    return amountTo;
  }

  /// Konversi dan format langsung
  Future<String> convertAndFormat(
      double amount, String fromCode, String toCode) async {
    await ensureRates();
    final converted = convert(amount, fromCode, toCode);
    return formatCurrency(converted, toCode);
  }

  /// Format angka sesuai kode wilayah
  String formatCurrency(double amount, String regionCode) {
    final code = regionCode.toUpperCase();

    switch (code) {
      case 'USD':
        return NumberFormat.currency(
                locale: 'en_US', symbol: '\$', decimalDigits: 2)
            .format(amount);
      case 'JPY':
        return NumberFormat.currency(
                locale: 'ja_JP', symbol: '¥', decimalDigits: 0)
            .format(amount);
      case 'EUR':
        return NumberFormat.currency(
                locale: 'de_DE', symbol: '€', decimalDigits: 2)
            .format(amount);
      case 'IDR':
      default:
        return NumberFormat.currency(
                locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
            .format(amount);
    }
  }

  /// Dapatkan simbol tampilan
  String symbolFor(String regionCode) {
    switch (regionCode.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'JPY':
        return '¥';
      case 'EUR':
        return '€';
      case 'IDR':
      default:
        return 'Rp';
    }
  }
}
