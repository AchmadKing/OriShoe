import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Import model
import 'models/user_model.dart';
import 'models/produk_model.dart';
import 'models/cart_item_model.dart';
import 'models/transaction_model.dart';

// Import halaman
import 'pages/home_page.dart';
import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Hive
  await Hive.initFlutter();

  // Registrasi adapter
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ProdukModelAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CartItemModelAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(UserModelAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(TransactionModelAdapter());

  // Buka semua box Hive
  await Hive.openBox<UserModel>('userBox');
  await Hive.openBox<ProdukModel>('productBox');
  await Hive.openBox<CartItemModel>('cartBox');
  await Hive.openBox('sessionBox');
  await Hive.openBox<TransactionModel>('transactionBox');

  // Ambil box session untuk cek status login
  final sessionBox = Hive.box('sessionBox');
  
  // PERBAIKAN: Cek currentUser bukan isLoggedIn
  final bool isLoggedIn = sessionBox.get('currentUser') != null;

  // Jalankan aplikasi
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sepatu Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: isLoggedIn ? const HomePage() : const LoginPage(),
    );
  }
}