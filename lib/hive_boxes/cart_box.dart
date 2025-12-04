import 'package:hive/hive.dart';
import 'package:sepatu/models/cart_item_model.dart';

class CartBox {
  static Box<CartItemModel> getCartItems() =>
      Hive.box<CartItemModel>('cartBox'); // disamakan dengan main.dart
}
