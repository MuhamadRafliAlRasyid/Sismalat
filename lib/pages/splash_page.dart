// lib/pages/splash_page.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // beri waktu sedikit agar splash terlihat (opsional)
    await Future.delayed(const Duration(milliseconds: 800));

    // 👇 ambil token yang tersimpan
    final token = await AuthService.getToken();

    if (token == null) {
      // tidak ada token → ke landing page
      _goTo('/landing_page');
      return;
    }

    // validasi token dengan memanggil endpoint /profile
    final result = await AuthService.getProfile();
    if (result['status'] == true) {
      // token valid → langsung ke dashboard
      _goTo('/dashboard');
    } else {
      // token tidak valid (expired/hapus) → hapus token & ke landing page
      await AuthService.logout(); // bersihkan token di SharedPreferences
      _goTo('/landing_page');
    }
  }

  void _goTo(String route) {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD97706), // amber
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo atau ikon aplikasi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.build,
                size: 64,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sismalat',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sistem Manajemen Alat Ukur',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
