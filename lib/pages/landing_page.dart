import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth/login_page.dart';
import 'auth/register_page.dart';
import 'qr_scanner_page.dart';
import '../services/auth_service.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 680;

    return WillPopScope(
      onWillPop: () async => await _showExitDialog(context),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF001F3F), Color(0xFF003366)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo.jpg',
                    height: isSmallScreen ? 110 : 140,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.inventory_2_rounded,
                      size: 140,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Text(
                    'Inventaris Dinas',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 28 : 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Kabupaten Karawang',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 20,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Kelola stok barang, pengambilan, dan permintaan pembelian dengan lebih mudah, cepat, dan transparan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14.5 : 15.5,
                        height: 1.6,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureCard(
                        Icons.inventory_2,
                        'Inventaris',
                        isSmallScreen,
                      ),
                      _buildFeatureCard(
                        Icons.local_shipping_outlined,
                        'Pengambilan',
                        isSmallScreen,
                      ),
                      _buildFeatureCard(
                        Icons.shopping_cart_outlined,
                        'Purchase',
                        isSmallScreen,
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),

                  // Tombol Masuk & Daftar
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: isSmallScreen ? 52 : 58,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF001F3F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: isSmallScreen ? 52 : 58,
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Buat Akun Baru',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // ==================== TOMBOL SCAN QR ====================
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QRScannerPage(),
                        ),
                      );

                      if (result != null &&
                          result is String &&
                          context.mounted) {
                        // Simpan hashid dari QR
                        await AuthService.saveTempSparepart(result);

                        // Langsung ke halaman Login
                        Navigator.pushNamed(context, '/login');
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 16 : 20,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Scan QR Barang',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 17 : 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Aplikasi?'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => SystemNavigator.pop(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildFeatureCard(IconData icon, String label, bool isSmallScreen) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: isSmallScreen ? 26 : 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: isSmallScreen ? 12 : 13.5,
          ),
        ),
      ],
    );
  }
}
