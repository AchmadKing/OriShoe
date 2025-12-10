import 'package:hive/hive.dart';
import 'cart_item_model.dart'; // Pastikan import ini sesuai

part 'transaction_model.g.dart';

@HiveType(typeId: 3) // ID 3 karena 0,1,2 sudah dipakai
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username; // Untuk mengaitkan transaksi dengan akun tertentu

  @HiveField(2)
  final List<CartItemModel> items; // Menyimpan snapshot barang yang dibeli

  @HiveField(3)
  final double totalAmount;

  @HiveField(4)
  final DateTime timestamp;

  TransactionModel({
    required this.id,
    required this.username,
    required this.items,
    required this.totalAmount,
    required this.timestamp,
  });
}