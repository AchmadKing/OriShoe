import '../models/produk_model.dart';

final List<ProdukModel> initialProducts = [
  // ================= NIKE =================
  ProdukModel(
    nama: "Nike Air Force 1 '07",
    harga: 1549000,
    deskripsi: "Ikon klasik yang memulai debutnya pada tahun 1982. Air Force 1 '07 menghadirkan fitur-fitur favorit: overlay yang dijahit rapi, sentuhan akhir yang berani, dan bantalan Nike Air yang memberikan kenyamanan sepanjang hari.",
    tipe: "Nike",
    size: ["39", "40", "41", "42", "43"],
    imagePath: "assets/images/Nike_Air_Force_1.jpg", // Pastikan file ini ada
  ),
  ProdukModel(
    nama: "Nike Zoom Vomero 5",
    harga: 2489000,
    deskripsi: "Desain kompleks dan praktis untuk lari maupun gaya sehari-hari. Menggabungkan tekstil, kulit, dan aksen plastik dengan bantalan Zoom Air untuk langkah yang responsif dan mulus.",
    tipe: "Nike",
    size: ["40", "41", "42", "43", "44"],
    imagePath: "assets/images/nike_vomero_5.jpeg",
  ),
  ProdukModel(
    nama: "Nike Dunk Low Retro",
    harga: 1549000,
    deskripsi: "Didesain untuk lapangan namun dibawa ke jalanan, ikon basket tahun 80-an ini kembali dengan detail klasik dan gaya hoops retro. Kerah low-cut yang empuk memungkinkan Anda membawa permainan ke mana saja dengan nyaman.",
    tipe: "Nike",
    size: ["38", "39", "40", "41", "42", "43"],
    imagePath: "assets/images/nike_dunk_low.jpeg",
  ),

  // ================= ADIDAS =================
  ProdukModel(
    nama: "Adidas Samba OG",
    harga: 2200000,
    deskripsi: "Lahir di lapangan sepak bola, Samba adalah ikon gaya jalanan yang tak lekang oleh waktu. Menampilkan upper kulit full-grain yang lembut, overlay suede T-toe, dan outsole gum karet yang autentik.",
    tipe: "Adidas",
    size: ["39", "40", "41", "42", "43", "44"],
    imagePath: "assets/images/adidas_samba.jpeg",
  ),
  ProdukModel(
    nama: "Adidas Ultraboost 5",
    harga: 3000000,
    deskripsi: "Rasakan energi tak terbatas dengan Ultraboost 5. Dilengkapi teknologi Light BOOST V2 yang lebih ringan dan responsif, serta upper Primeknit+ yang adaptif memeluk kaki Anda.",
    tipe: "Adidas",
    size: ["40", "41", "42", "43", "44"],
    // [FIXED] Mengubah nama file agar sesuai dengan file asli (kapital A dan U)
    imagePath: "assets/images/Adidas_Ultraboost_5.jpg", 
  ),
  ProdukModel(
    nama: "Adidas Gazelle",
    harga: 1700000,
    deskripsi: "Simbol gaya klasik yang tak pernah pudar. Sepatu low-profile ini menampilkan upper nubuck premium dan detail 3-Stripes yang kontras, menawarkan kestabilan fashion streetwear sejak tahun 60-an.",
    tipe: "Adidas",
    size: ["36", "37", "38", "39", "40", "41"],
    imagePath: "assets/images/adidas_gazelle.jpeg",
  ),

  // ================= PUMA =================
  ProdukModel(
    nama: "Puma Suede Classic XXI",
    harga: 1399000,
    deskripsi: "Ikon PUMA sejak 1968. Suede Classic XXI hadir dengan upper full suede yang lembut, desain low-profile yang tak lekang oleh waktu, dan Formstrip khas di bagian samping.",
    tipe: "Puma",
    size: ["39", "40", "41", "42", "43"],
    imagePath: "assets/images/puma_suede.jpeg",
  ),
  ProdukModel(
    nama: "Puma Palermo",
    harga: 1699000,
    deskripsi: "Legenda teras stadion tahun 80-an kembali. Palermo memiliki siluet T-toe yang khas, konstruksi klasik, dan tag logo emas di bagian atas, sempurna untuk gaya kasual modern.",
    tipe: "Puma",
    size: ["38", "39", "40", "41", "42"],
    imagePath: "assets/images/puma_palermo.jpeg",
  ),
  ProdukModel(
    nama: "Puma RS-X Efekt",
    harga: 1799000,
    deskripsi: "Desain retro masa depan kembali dengan estetika progresif. Bagian atas jaring dengan lapisan suede dan nubuck menciptakan tampilan bersudut yang disruptif, siap untuk memamerkan gaya unik Anda.",
    tipe: "Puma",
    size: ["40", "41", "42", "43", "44"],
    imagePath: "assets/images/puma_rs_x.jpeg",
  ),
];