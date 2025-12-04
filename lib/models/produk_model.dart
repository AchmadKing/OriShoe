import 'package:hive/hive.dart';

part 'produk_model.g.dart';

@HiveType(typeId: 0)
class ProdukModel {
  @HiveField(0)
  String nama;

  @HiveField(1)
  double harga;

  @HiveField(2)
  String tipe;

  @HiveField(3)
  List<String> size; // ubah dari String ke List<String>

  @HiveField(4)
  String imagePath;

  @HiveField(5)
  String deskripsi;

  ProdukModel({
    required this.nama,
    required this.harga,
    required this.tipe,
    required this.size,
    required this.imagePath,
    required this.deskripsi,
  });
}
