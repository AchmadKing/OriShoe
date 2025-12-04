import 'package:hive/hive.dart';

part 'cart_item_model.g.dart';

@HiveType(typeId: 1)
class CartItemModel extends HiveObject {
  @HiveField(0)
  String nama;

  @HiveField(1)
  double harga;

  @HiveField(2)
  String size;

  @HiveField(3)
  String imagePath;

  @HiveField(4)
  int quantity;

  CartItemModel({
    required this.nama,
    required this.harga,
    required this.size,
    required this.imagePath,
    required this.quantity,
  });
}
