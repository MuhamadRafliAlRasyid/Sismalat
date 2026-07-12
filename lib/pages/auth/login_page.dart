import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isLoadingGoogle = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _togglePassword() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['status'] == true) {
      // ✅ Cek apakah ada QR flow (alat_id)
      if (result['should_open_form'] == true && result['alat_id'] != null) {
        // Simpan alat_id untuk digunakan di form pengambilan
        await AuthService.saveTempAlat(result['alat_id']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Login berhasil'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate ke form pengambilan alat
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/pengambilan_alat/form',
          (route) => false,
          arguments: {'alatHashid': result['alat_id']},
        );
      } else {
        // Normal login → Dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Login berhasil'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => DashboardPage()),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login gagal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoadingGoogle = true);

    final result = await AuthService.loginWithGoogle();

    if (!mounted) return;
    setState(() => _isLoadingGoogle = false);

    if (result['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login Google berhasil'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => DashboardPage()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login Google gagal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(child: _buildMainContent()),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 768;
        return Container(
          constraints: const BoxConstraints(maxWidth: 1024),
          margin: const EdgeInsets.all(16),
          child: isWide ? _buildWideLayout() : _buildMobileLayout(),
        );
      },
    );
  }

  // ========== LAYOUT WIDE (Tablet/Desktop) ==========
  Widget _buildWideLayout() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
        border: Border.all(color: const Color(0xFFFDE047).withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(child: _buildLeftPanel()),
          Expanded(child: _buildRightPanel()),
        ],
      ),
    );
  }

  // ========== LAYOUT MOBILE ==========
  Widget _buildMobileLayout() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildLeftPanel(isMobile: true),
          _buildRightPanel(isMobile: true),
        ],
      ),
    );
  }

  // ========== PANEL KIRI (INFO APLIKASI) ==========
  Widget _buildLeftPanel({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 32 : 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFFFBF0)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo & nama
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.2),
                          blurRadius: 10,
                        ),
                      ],
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        'https://perindag.slemankab.go.id/wp-content/uploads/2025/09/Logo-Metrologi-Diedit.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.scale,
                          size: 50,
                          color: Color(0xFFa16207),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sismalat',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Sistem Manajemen Alat Ukur',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFD97706),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Kelola Inventaris Alat Ukur',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Disperindag Kabupaten Karawang',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFD97706),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Aplikasi modern untuk mencatat pengambilan, pengembalian, kalibrasi, serta memantau stok alat secara real-time dengan dukungan scan QR Code.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4B5563),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  _FeatureItem(
                    emoji: '✅',
                    title: 'Stok Real‑time',
                    subtitle: 'Update otomatis',
                  ),
                  _FeatureItem(
                    emoji: '📱',
                    title: 'QR Code Scan',
                    subtitle: 'Pengambilan cepat',
                  ),
                  _FeatureItem(
                    emoji: '📊',
                    title: 'Laporan Lengkap',
                    subtitle: 'PDF & Excel',
                  ),
                  _FeatureItem(
                    emoji: '🔒',
                    title: 'Aman & Terintegrasi',
                    subtitle: 'Role-based access',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========== PANEL KANAN (FORM LOGIN) ==========
  Widget _buildRightPanel({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 32 : 48),
      color: Colors.white,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selamat Datang Kembali',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Masuk untuk melanjutkan ke Sismalat',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // ✅ Email field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Alamat Email',
                hintText: 'nama@email.com',
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFFBBF24),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email harus diisi';
                }
                if (!value.contains('@')) {
                  return 'Email tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ✅ Password field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Kata Sandi',
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  onPressed: _togglePassword,
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFFBBF24),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ✅ Tombol Login Email
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  shadowColor: Colors.amber.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Masuk ke Sismalat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Divider "ATAU"
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'ATAU',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 16),

            // ✅ Tombol Login Google
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _isLoadingGoogle ? null : _handleGoogleLogin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: BorderSide(color: Colors.grey.shade200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Colors.white,
                ),
                child: _isLoadingGoogle
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://www.google.com/favicon.ico',
                            width: 20,
                            height: 20,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.g_mobiledata, size: 24),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Masuk dengan Google',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '© 2026 Dinas Industri dan Perdagangan Kabupaten Karawang',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Widget item fitur
class _FeatureItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF374151),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
