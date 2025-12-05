import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/product_data.dart';
import '../models/produk_model.dart';
import '../services/currency_service.dart';
import 'detail_page.dart';
import 'cart_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;
  final List<ProdukModel> products = initialProducts;

  bool _isSearching = false;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  String _selectedCurrency = 'IDR';
  bool _isLoadingRates = true;

  @override
  void initState() {
    super.initState();
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

  void _onItemTapped(int index) {
    if (index == 1) {
      setState(() {
        _isSearching = true;
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        FocusScope.of(context).requestFocus(_searchFocus);
      });
    } else if (index == 0) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
    }
  }

  List<ProdukModel> get _filteredProducts {
    if (_query.isEmpty) return [];
    return products
        .where((p) =>
            p.nama.toLowerCase().contains(_query.toLowerCase()) ||
            p.tipe.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isSearching ? _buildSearchMode() : _buildHomeMode(),
        ),
      ),
      bottomNavigationBar: _isSearching ? null : _buildBottomNav(),
    );
  }

  Widget _buildHomeMode() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  color: Colors.white,
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingRates
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.60, // [FIX] Ubah rasio agar kartu lebih tinggi (sebelumnya 0.68)
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(product);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchMode() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _query = '';
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                  });
                },
              ),
              Expanded(
                child: TextField(
                  focusNode: _searchFocus,
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _query = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search product...',
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _query.isEmpty
              ? const Center(
                  child: Text(
                    'Type to search product',
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                )
              : _filteredProducts.isEmpty
                  ? const Center(
                      child: Text(
                        'Product not found',
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              product.imagePath,
                              width: 55,
                              height: 55,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            product.nama,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: FutureBuilder<String>(
                            future: CurrencyService.instance.convertAndFormat(
                              product.harga.toDouble(),
                              'IDR',
                              _selectedCurrency,
                            ),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Text("Loading...");
                              }
                              return Text(snapshot.data!,
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14));
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailPage(product: product),
                              ),
                            );
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.shopping_bag_outlined, Icons.shopping_bag, 'Cart', 0),
              _buildNavItem(Icons.search, Icons.search, 'Search', 1),
              _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData outlinedIcon, IconData filledIcon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? filledIcon : outlinedIcon,
                color: isSelected ? Colors.white : Colors.black54),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: -0.3)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProdukModel product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(product: product)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [FIX] Mengubah flex agar bagian bawah (teks) mendapat ruang lebih banyak
            Expanded(
              flex: 3, // Sebelumnya 5
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(product.imagePath, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            Expanded(
              flex: 2, // Sebelumnya 2 (Rasio 3:2 lebih seimbang daripada 5:2)
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // [MODIFIED] Menggunakan FittedBox agar teks mengecil jika kepanjangan
                    SizedBox(
                      height: 40, // Batasan tinggi untuk 2 baris
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          product.nama,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black,
                              letterSpacing: -0.5),
                        ),
                      ),
                    ),
                    FutureBuilder<String>(
                      future: CurrencyService.instance.convertAndFormat(
                        product.harga.toDouble(),
                        'IDR',
                        _selectedCurrency,
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Text("Loading...");
                        }
                        return Text(snapshot.data!,
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                letterSpacing: -0.3));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}