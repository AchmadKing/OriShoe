import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/currency_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Box<TransactionModel> transactionBox;
  String currentUsername = '';

  @override
  void initState() {
    super.initState();
    transactionBox = Hive.box<TransactionModel>('transactionBox');
    final sessionBox = Hive.box('sessionBox');
    
    // [FIX] currentUser disimpan sebagai String (hanya username), bukan Map.
    // Jadi kita langsung ambil nilainya.
    final currentUser = sessionBox.get('currentUser');
    
    if (currentUser is String) {
      currentUsername = currentUser;
    } else if (currentUser is Map) {
      // Jaga-jaga jika di masa depan struktur berubah jadi Map
      currentUsername = currentUser['username'] ?? '';
    }
  }

  // Helper untuk format harga
  Future<String> _formatPrice(double amount) async {
    return await CurrencyService.instance.convertAndFormat(amount, 'IDR', 'IDR'); 
  }

  @override
  Widget build(BuildContext context) {
    // Filter transaksi hanya milik user yang sedang login
    final myTransactions = transactionBox.values
        .where((tr) => tr.username == currentUsername)
        .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Urutkan dari yang terbaru

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Riwayat Pembelian", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: myTransactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("Belum ada riwayat transaksi.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myTransactions.length,
              itemBuilder: (context, index) {
                final transaction = myTransactions[index];
                return _buildHistoryCard(transaction);
              },
            ),
    );
  }

  Widget _buildHistoryCard(TransactionModel transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailPopup(transaction), // Munculkan Detail Mengambang
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Order #${transaction.id.substring(transaction.id.length - 6)}", style: const TextStyle(fontWeight: FontWeight.bold)), // Ambil 6 digit terakhir ID
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(transaction.timestamp),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text("${transaction.items.length} Barang", style: const TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                transaction.items.map((e) => e.nama).join(", "),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              ),
              const SizedBox(height: 12),
              FutureBuilder<String>(
                future: _formatPrice(transaction.totalAmount),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? "...",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // LOGIKA POPUP MENGAMBANG
  void _showDetailPopup(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Detail Transaksi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Bagian 4 Zona Waktu
                  _buildTimeZones(transaction.timestamp),
                  const Divider(height: 30),

                  // Detail Barang
                  Text("Order ID: ${transaction.id}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  ...transaction.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.nama, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              Text("${item.quantity} x ${item.size}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        FutureBuilder<String>(
                          future: _formatPrice(item.harga * item.quantity),
                          builder: (c, s) => Text(s.data ?? "", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  )),
                  
                  const Divider(height: 30),
                  
                  // Total Harga
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Bayar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      FutureBuilder<String>(
                        future: _formatPrice(transaction.totalAmount),
                        builder: (c, s) => Text(s.data ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeZones(DateTime timestamp) {
    // timestamp dari Hive biasanya tersimpan sesuai waktu lokal saat save.
    // Kita anggap base waktu adalah waktu lokal device saat ini untuk dikonversi ke UTC.
    final utc = timestamp.toUtc();
    final wib = utc.add(const Duration(hours: 7));
    final wita = utc.add(const Duration(hours: 8));
    final wit = utc.add(const Duration(hours: 9));
    final london = utc; // UTC+0

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              const Text("Waktu Pembelian", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          _timeRow("WIB ", wib),
          _timeRow("WITA ", wita),
          _timeRow("WIT ", wit),
          _timeRow("UTC (London)", london),
        ],
      ),
    );
  }

  Widget _timeRow(String label, DateTime time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          Text(DateFormat('HH:mm').format(time), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}