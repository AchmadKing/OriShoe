import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart'; // Import Geolocator
import 'package:geocoding/geocoding.dart';   // Import Geocoding
import '../models/user_model.dart';
import '../hive_boxes/session_box.dart';

// Import Halaman
import 'login_page.dart';
import 'cart_page.dart';
import 'home_page.dart';
import 'history_page.dart'; // [BARU] Import halaman riwayat

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Box<UserModel> userBox;
  String username = '';
  String email = '';
  int _selectedIndex = 2;
  String _selectedCurrency = 'IDR';
  bool _isDetectingLocation = false; // Loading state untuk lokasi

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCurrency = prefs.getString('selected_currency') ?? 'IDR';
    setState(() {
      _selectedCurrency = savedCurrency;
    });
  }

  Future<void> _saveCurrency(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_currency', value);
    setState(() {
      _selectedCurrency = value;
    });
  }

  // --- LOGIKA LBS (Location Based Service) ---
  Future<void> _detectLocationAndSetCurrency() async {
    setState(() => _isDetectingLocation = true);

    try {
      // 1. Cek Service GPS
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable GPS.';
      }

      // 2. Cek Izin
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      }

      // 3. Ambil Koordinat
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 4. Geocoding (Koordinat -> Alamat/Negara)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final countryCode = place.isoCountryCode?.toUpperCase() ?? '';
        final countryName = place.country ?? 'Unknown';

        // 5. Mapping Mata Uang
        String newCurrency = 'IDR'; // Default

        if (countryCode == 'ID') {
          newCurrency = 'IDR';
        } else if (countryCode == 'US') {
          newCurrency = 'USD';
        } else if (countryCode == 'JP') {
          newCurrency = 'JPY';
        } else if (['DE', 'FR', 'IT', 'ES', 'NL', 'BE', 'AT', 'GR', 'PT', 'FI', 'IE'].contains(countryCode)) {
          // Negara-negara zona Euro umum
          newCurrency = 'EUR';
        } else {
          // Default fallback
          newCurrency = 'IDR'; 
        }

        // Simpan
        await _saveCurrency(newCurrency);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("📍 Located in $countryName. Currency set to $newCurrency."),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isDetectingLocation = false);
    }
  }
  // ------------------------------------------

  Future<void> _loadUserData() async {
    userBox = Hive.box<UserModel>('userBox');
    final currentUser = await SessionBox.getCurrentUser();
    if (currentUser != null) {
      // ignore: cast_nullable_to_non_nullable
      final user = userBox.values.firstWhere(
        (u) => u.username == currentUser,
        orElse: () => UserModel(username: 'Guest', password: '', email: ''),
      );
      setState(() {
        username = user.username;
        email = user.email;
      });
    }
  }

  Future<void> logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                child: const Icon(Icons.logout, color: Colors.red, size: 30),
              ),
              const SizedBox(height: 16),
              const Text("Logout", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text("Are you sure you want to logout?", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.black.withOpacity(0.6))),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Logout", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await SessionBox.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CartPage()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dropdown Manual (tetap ada sebagai opsi)
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
                      if (value != null) await _saveCurrency(value);
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      color: Colors.white,
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER PROFILE ---
                    const Text('My Profile', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1)),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: Colors.black, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))],
                            ),
                            child: const Icon(Icons.person, size: 40, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(username.isNotEmpty ? username : 'Guest User', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text(email.isNotEmpty ? email : 'No email', style: const TextStyle(fontSize: 15, color: Colors.black54)),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // --- FITUR LBS Currency Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isDetectingLocation ? null : _detectLocationAndSetCurrency,
                        icon: _isDetectingLocation 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Icon(Icons.location_on_outlined, color: Colors.black),
                        label: Text(
                          _isDetectingLocation ? "Detecting..." : "📍 Auto-Detect Currency (GPS)",
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[700], // Warna kuning agar menonjol
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    // --- [BARU] FITUR RIWAYAT PEMBELIAN ---
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50], 
                            shape: BoxShape.circle
                          ),
                          child: const Icon(Icons.history, color: Colors.blue),
                        ),
                        title: const Text(
                          "Riwayat Pembelian", 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                        subtitle: const Text(
                          "Lihat riwayat transaksi anda", 
                          style: TextStyle(color: Colors.grey, fontSize: 12)
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          // Navigasi ke Halaman Riwayat
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HistoryPage()),
                          );
                        },
                      ),
                    ),
                    // ----------------------------------------

                    const SizedBox(height: 32),
                    
                    const Text('Saran dan Kesan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: 12),
                          const Text('Saya merasa mata kuliah ini menambah wawasan dan kemampuan saya dalam pengembangan aplikasi modern, terutama yang berbasis Android.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
                          const SizedBox(height: 8),
                          const Text('Lebih menarik jika diberikan proyek kelompok yang meniru pengembangan aplikasi di industri agar mahasiswa terbiasa bekerja secara tim.', style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => logout(context),
                        icon: const Icon(Icons.logout, size: 22),
                        label: const Text('Logout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: Colors.red.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -4))],
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
        decoration: BoxDecoration(color: isSelected ? Colors.black : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? filledIcon : outlinedIcon, color: isSelected ? Colors.white : Colors.black54, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: -0.3)),
            ],
          ],
      ),
        ),
    );
  }
}