import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk fitur copy paste
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';
import '../services/currency_service.dart';
import '../services/bank_service.dart'; // Pastikan file ini ada
import '../services/notification_service.dart'; // Pastikan file ini ada
import 'home_page.dart';
import 'profile_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Box<CartItemModel> cartBox;
  int _selectedIndex = 0;

  // Service Instances
  final BankService _bankService = BankService();
  final NotificationService _notificationService = NotificationService();

  String _selectedCurrency = 'IDR';
  bool _isLoadingRates = true;

  @override
  void initState() {
    super.initState();
    cartBox = Hive.box<CartItemModel>('cartBox');
    _notificationService.init(); // Inisialisasi notifikasi
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCurrency = prefs.getString('selected_currency') ?? 'IDR';
    setState(() {
      _selectedCurrency = savedCurrency;
    });
    await _loadRates();
  }

  Future<void> _saveCurrency(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_currency', value);
  }

  Future<void> _loadRates() async {
    await CurrencyService.instance.ensureRates();
    setState(() {
      _isLoadingRates = false;
    });
  }

  Future<String> _formatPrice(double amount) async {
    final converted = await CurrencyService.instance.convertAndFormat(
      amount,
      'IDR',
      _selectedCurrency,
    );
    return converted;
  }

  double getTotalPrice() {
    double total = 0;
    for (var item in cartBox.values) {
      total += item.harga * item.quantity;
    }
    return total;
  }

  void _deleteItem(int index) {
    // ... (Kode delete item sama seperti sebelumnya)
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline, color: Colors.red, size: 40),
              const SizedBox(height: 16),
              const Text("Remove Item?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        cartBox.deleteAt(index);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("Remove", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= LOGIKA CHECKOUT & POP-UP =================

  // 1. Fungsi saat tombol Checkout ditekan
  void _handleCheckout() async {
    if (cartBox.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cart is empty!")),
      );
      return;
    }

    // Tampilkan Loading Dialog saat mengambil data API
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      // Ambil data Bank dari API
      final bankData = await _bankService.getBankInfo();
      
      // Hitung Total yang sudah diformat
      final totalAmount = getTotalPrice();
      final formattedTotal = await _formatPrice(totalAmount);

      // Tutup Loading Dialog
      if (mounted) Navigator.pop(context);

      if (bankData != null && mounted) {
        // Tampilkan Pop-up Pembayaran Profesional
        _showPaymentDialog(bankData, formattedTotal);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengambil data pembayaran")),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Tutup loading jika error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // 2. Desain Pop-up Dialog Profesional
  void _showPaymentDialog(Map<String, dynamic> bankData, String totalDisplay) {
    showDialog(
      context: context,
      barrierDismissible: false, // User harus pilih tombol untuk keluar
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 10,
          child: Container(
            padding: const EdgeInsets.all(0), // Padding diatur di dalam
            constraints: const BoxConstraints(maxHeight: 600), // Agar tidak terlalu panjang
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Header ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.white),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Payment Details",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),

                // --- Content ---
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Total Price
                        const Text("Total Payment", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          totalDisplay,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black),
                        ),
                        const SizedBox(height: 24),

                        // Bank Card Design
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(bankData['bank_name'] ?? 'Bank', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Image.asset('assets/images/.jpg', height: 20, errorBuilder: (c,o,s) => const Icon(Icons.account_balance, size: 20)), 
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Account Number", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      Text(bankData['account_number'] ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      Text("a.n ${bankData['account_holder']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 20, color: Colors.blue),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: bankData['account_number']));
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied!"), duration: Duration(seconds: 1)));
                                    },
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // QRIS Image (Jika ada)
                        if (bankData['qris_image_url'] != null && bankData['qris_image_url'].toString().isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                            ),
                            child: Image.network(
                              bankData['qris_image_url'],
                              height: 180,
                              fit: BoxFit.contain,
                              loadingBuilder: (c, child, loading) => loading == null ? child : const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
                              errorBuilder: (c, o, s) => const SizedBox(height: 50, child: Center(child: Text("QR Image Error"))),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text("Scan QRIS to Pay", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ],
                    ),
                  ),
                ),

                // --- Footer (Tombol) ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _processPayment(), // 3. Tombol Bayar Sekarang
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      child: const Text(
                        "Bayar Sekarang",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 4. Logika Final Pembayaran (Notifikasi & Clear Cart)
  void _processPayment() async {
    // Tutup Dialog Pop-up
    Navigator.pop(context);

    // Tampilkan Notifikasi
    await _notificationService.showNotification(
      title: 'Pembayaran Berhasil!',
      body: 'Terima kasih telah berbelanja di OriShoe.',
    );

    // Kosongkan Keranjang
    cartBox.clear();

    // Tampilkan Dialog Sukses Sederhana
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text("Success!", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text("Pesanan Anda sedang diproses.", textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog sukses
              // Kembali ke halaman home (opsional)
              _onItemTapped(1); 
            },
            child: const Text("OK", style: TextStyle(color: Colors.black)),
          )
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);

    if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            "Shopping Cart",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedCurrency,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    underline: Container(height: 1, color: Colors.black),
                    items: const [
                      DropdownMenuItem(value: 'IDR', child: Text('IDR')),
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'JPY', child: Text('JPY')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                    ],
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() {
                          _selectedCurrency = value;
                          _isLoadingRates = true;
                        });
                        await _saveCurrency(value);
                        await _loadRates();
                      }
                    },
                  ),
                ],
              ),
            ),

            // Cart List
            Expanded(
              child: _isLoadingRates
                  ? const Center(child: CircularProgressIndicator())
                  : ValueListenableBuilder(
                      valueListenable: cartBox.listenable(),
                      builder: (context, Box<CartItemModel> box, _) {
                        if (box.isEmpty) {
                          return const Center(
                            child: Text(
                              "Your cart is empty\nAdd some items first!",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, color: Colors.black54),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: box.length,
                          itemBuilder: (context, index) {
                            final item = box.getAt(index)!;
                            final totalItemPrice = item.harga * item.quantity;
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.asset(
                                        item.imagePath,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              item.nama,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text("Size: ${item.size}", style: const TextStyle(fontSize: 13)),
                                          Text("Qty: ${item.quantity}", style: const TextStyle(fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        FutureBuilder<String>(
                                          future: _formatPrice(totalItemPrice),
                                          builder: (context, snapshot) {
                                            if (!snapshot.hasData) return const Text("...");
                                            return Text(snapshot.data!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14));
                                          },
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _deleteItem(index),
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),

            // Footer Total & Checkout Button
            if (cartBox.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4)),
                  ],
                ),
                child: Column(
                  children: [
                    FutureBuilder<String>(
                      future: _formatPrice(getTotalPrice()),
                      builder: (context, snapshot) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Flexible(
                              child: Text(
                                snapshot.data ?? 'Loading...',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _handleCheckout, // [UBAH] Panggil fungsi baru ini
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "Checkout",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black45,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "Cart"),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
          ],
        ),
      ),
    );
  }
}