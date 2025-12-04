import '../models/produk_model.dart';

final List<ProdukModel> initialProducts = [
  ProdukModel(
    nama: "Nike Air Force 1",
    harga: 1500000,
    deskripsi: "Sepatu klasik dengan desain elegan dan nyaman dipakai.",
    tipe: "Nike",
    size: ["39", "40", "41", "42"],
    imagePath: "assets/images/Nike_Air_Force_1.jpg",
  ),
  ProdukModel(
    nama: "Adidas Ultraboost",
    harga: 2200000,
    deskripsi: "Sepatu lari premium dengan bantalan boost untuk kenyamanan.",
    tipe: "Adidas",
    size: ["40", "41", "42", "43"],
    imagePath: "assets/images/Adidas_Ultraboost.jpg",
  ),
];
