import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';
import '../hive_boxes/cart_box.dart';
import '../services/currency_service.dart';
import '../services/notification_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({Key? key}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late Box<CartItemModel> cartBox;
  final currencyService = CurrencyService.instance;
  final notificationService = NotificationService();
  String currentCurrency = 'IDR';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cartBox = CartBox.getCartItems();
    _loadCurrencyPreference();
    notificationService.init();
  }

  Future<void> _loadCurrencyPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCurrency = prefs.getString('selected_currency') ?? 'IDR';
    await currencyService.ensureRates();
    setState(() {
      currentCurrency = savedCurrency;
      isLoading = false;
    });
  }

  Future<double> _getTotalConverted() async {
    double total = 0;
    for (var item in cartBox.values) {
      double subtotal = item.harga * item.quantity;
      // PERBAIKAN: Langsung jumlahkan IDR, konversi dilakukan saat display
      total += subtotal; 
    }
    return total;
  }

  Future<String> _formatPrice(double amount) async {
    return currencyService.convertAndFormat(amount, 'IDR', currentCurrency);
  }

  void _checkout() async {
    if (cartBox.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart still empty!')),
      );
      return;
    }

    final now = DateTime.now();
    final wib = now;
    final wita = now.add(const Duration(hours: 1));
    final wit = now.add(const Duration(hours: 2));
    final london = now.subtract(const Duration(hours: 7));

    final formatTime = (DateTime dt) =>
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

    await notificationService.showNotification(
      title: 'Purchase Successful',
      body: 'Your purchase has been completed successfully.',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Succesfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thank you for shopping.'),
            const SizedBox(height: 12),
            const Text(
              'Time Transaction:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• WIB     : ${formatTime(wib)}'),
            Text('• WITA    : ${formatTime(wita)}'),
            Text('• WIT     : ${formatTime(wit)}'),
            Text('• London  : ${formatTime(london)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              cartBox.clear();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final items = cartBox.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: items.isEmpty
          ? const Center(child: Text('Your cart is empty.'))
          : FutureBuilder<double>(
              future: _getTotalConverted(),
              builder: (context, snapshot) {
                final total = snapshot.data ?? 0;

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final subtotal = item.harga * item.quantity;

                          return FutureBuilder<String>(
                            future: _formatPrice(subtotal),
                            builder: (context, priceSnapshot) {
                              final priceText = priceSnapshot.data ?? '...';
                              return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    item.imagePath,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Text(item.nama,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  'Size: ${item.size}\nQty: ${item.quantity}',
                                ),
                                trailing: Text(
                                  priceText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FutureBuilder<String>(
                            future: _formatPrice(total),
                            builder: (context, totalSnapshot) {
                              final formattedTotal =
                                  totalSnapshot.data ?? 'Loading...';
                              return Text(
                                'Total (${currentCurrency.toUpperCase()}): $formattedTotal',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _checkout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Pay Now',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}