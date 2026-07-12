// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✨ TAMBAHKAN IMPORT INI
import 'config/api.dart';

// Services
import 'services/alat_service.dart';
import 'services/kalibrasi_service.dart';
import 'services/kategori_service.dart';
import 'services/pengambilan_alat_service.dart';
import 'services/pengembalian_alat_service.dart';

// Providers
import 'providers/alat_provider.dart';
import 'providers/kalibrasi_provider.dart';
import 'providers/kategori_provider.dart';
import 'providers/pengambilan_provider.dart';
import 'providers/pengembalian_provider.dart';

// Auth
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';

// Dashboard & Profile
import 'pages/dashboard_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/profile/edit_profile_page.dart';
import 'pages/profile/user_list_page.dart';
import 'pages/profile/notification_page.dart';

// Bagian
import 'pages/bagian/bagian_list_page.dart';
import 'pages/bagian/bagian_form_page.dart';

// Barang (Sparepart)
import 'pages/barang/barang_list_page.dart';
import 'pages/barang/barang_form_page.dart';
import 'pages/barang/barang_detail_page.dart';
import 'pages/barang/trashed_barang_page.dart';

// Pengambilan Sparepart
import 'pages/pengambilan/pengambilan_list_page.dart';
import 'pages/pengambilan/pengambilan_form_page.dart';
import 'pages/pengambilan/pengambilan_detail_page.dart';

// Pengembalian Sparepart
import 'pages/pengembalian/pengembalian_list_page.dart';
import 'pages/pengembalian/pengembalian_form_page.dart';

// Purchase
import 'pages/purchase/purchase_request_list_page.dart';
import 'pages/purchase/purchase_request_detail_page.dart';
import 'pages/purchase/purchase_request_form_page.dart';

// Alat (Inventaris Alat)
import 'pages/alat/alat_list_page.dart';
import 'pages/alat/alat_form_page.dart';
import 'pages/alat/alat_detail_page.dart';
import 'pages/alat/riwayat_alat_page.dart';

// Kategori
import 'pages/kategori/kategori_list_page.dart';
import 'pages/kategori/kategori_form_page.dart';

// Kalibrasi
import 'pages/kalibrasi/kalibrasi_list_page.dart';
import 'pages/kalibrasi/kalibrasi_detail_page.dart';
import 'pages/kalibrasi/kalibrasi_form_page.dart';

// Pengambilan Alat
import 'pages/pengambilan_alat/pengambilan_alat_list_page.dart';
import 'pages/pengambilan_alat/pengambilan_alat_detail_page.dart';
import 'pages/pengambilan_alat/pengambilan_alat_form_page.dart';

// Pengembalian Alat
import 'pages/pengembalian_alat/pengembalian_alat_list_page.dart';
import 'pages/pengembalian_alat/pengembalian_alat_detail_page.dart';
import 'pages/pengembalian_alat/pengembalian_alat_form_page.dart';

// QR Scanner & Landing
import 'pages/qr_scanner_page.dart';
import 'pages/landing_page.dart';
import 'pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✨ GUNAKAN Api.baseUrl dari config
  final baseUrl = Api.baseUrl;

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token') ?? '';

  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception is FlutterError &&
        details.exception.toString().contains(
          'Cannot hit test a render box that has never been laid out',
        )) {
      return;
    }
    FlutterError.presentError(details);
  };

  runApp(
    MultiProvider(
      providers: [
        // Alat
        Provider<AlatService>(
          create: (_) => AlatService(baseUrl: baseUrl, token: token),
        ),
        ChangeNotifierProvider<AlatProvider>(
          create: (ctx) => AlatProvider(alatService: ctx.read()),
        ),

        // Kalibrasi
        Provider<KalibrasiService>(
          create: (_) => KalibrasiService(baseUrl: baseUrl, token: token),
        ),
        ChangeNotifierProvider<KalibrasiProvider>(
          create: (ctx) => KalibrasiProvider(service: ctx.read()),
        ),

        // Kategori
        Provider<KategoriService>(
          create: (_) => KategoriService(baseUrl: baseUrl, token: token),
        ),
        ChangeNotifierProvider<KategoriProvider>(
          create: (ctx) => KategoriProvider(service: ctx.read()),
        ),

        // Pengambilan Alat
        Provider<PengambilanAlatService>(
          create: (_) => PengambilanAlatService(baseUrl: baseUrl, token: token),
        ),
        ChangeNotifierProvider<PengambilanProvider>(
          create: (ctx) => PengambilanProvider(service: ctx.read()),
        ),

        // Pengembalian Alat
        Provider<PengembalianAlatService>(
          create: (_) =>
              PengembalianAlatService(baseUrl: baseUrl, token: token),
        ),
        ChangeNotifierProvider<PengembalianProvider>(
          create: (ctx) => PengembalianProvider(service: ctx.read()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventaris Dinas',
      theme: _buildAppTheme(),
      initialRoute: '/splash',
      routes: {
        // ==================== AUTH & GENERAL ====================
        '/splash': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/landing_page': (context) => const LandingPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/qr-scanner': (context) => const QRScannerPage(),
        '/notifications': (context) => const NotificationPage(),

        // ==================== PROFILE & USER ====================
        '/profile': (context) => const ProfilePage(),
        '/profile/edit': (context) {
          final userData =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return EditProfilePage(userData: userData);
        },
        '/user/list': (context) => const UserListPage(),

        // ==================== BAGIAN ====================
        '/bagian/list': (context) => const BagianListPage(),
        '/bagian/form': (context) {
          final hashid = ModalRoute.of(context)?.settings.arguments as String?;
          return BagianFormPage(hashid: hashid);
        },

        // ==================== BARANG (SPAREPART) ====================
        '/barang/list': (context) => const BarangListPage(),
        '/barang/form': (context) {
          final hashid = ModalRoute.of(context)?.settings.arguments as String?;
          return BarangFormPage(hashid: hashid);
        },
        '/barang/trashed': (context) => const TrashedBarangPage(),

        // ==================== PENGAMBILAN SPAREPART ====================
        '/pengambilan/list': (context) => const PengambilanListPage(),
        '/pengambilan/form': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          String? hashid;
          String? sparepartHashid;
          if (args is Map<String, dynamic>) {
            hashid = args['hashid'] as String?;
            sparepartHashid = args['sparepartHashid'] as String?;
          } else if (args is String) {
            hashid = args;
          }
          return PengambilanFormPage(
            hashid: hashid,
            sparepartHashid: sparepartHashid,
          );
        },

        // ==================== PENGEMBALIAN SPAREPART ====================
        '/pengembalian/list': (context) => const PengembalianListPage(),
        '/pengembalian/form': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          String? hashid;
          if (args is String) {
            hashid = args;
          } else if (args is Map<String, dynamic>) {
            hashid = args['hashid'] as String?;
          }
          return PengembalianFormPage(hashid: hashid);
        },

        // ==================== PURCHASE REQUEST ====================
        '/purchase/list': (context) => const PurchaseRequestListPage(),
        '/purchase/form': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return PurchaseRequestFormPage(
            hashid: args?['hashid'] as String?,
            sparepartHashid: args?['sparepartHashid'] as String?,
          );
        },

        // ==================== ALAT (INVENTARIS) ====================
        '/alat/list': (context) => const AlatListPage(),
        '/alat/form': (context) {
          final hashid = ModalRoute.of(context)?.settings.arguments as String?;
          return AlatFormPage(hashid: hashid);
        },
        '/alat/trashed': (context) => const Scaffold(
          body: Center(child: Text('Trashed Alat - Coming Soon')),
        ),
        '/alat/riwayat': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>;
          return RiwayatAlatPage(
            alatHashid: args['alatHashid'],
            namaAlat: args['namaAlat'],
          );
        },

        // ==================== KATEGORI ====================
        '/kategori/list': (context) => const KategoriListPage(),
        '/kategori/form': (context) {
          final hashid = ModalRoute.of(context)?.settings.arguments as String?;
          return KategoriFormPage(hashid: hashid);
        },

        // ==================== KALIBRASI ====================
        '/kalibrasi/list': (context) => const KalibrasiListPage(),
        '/kalibrasi/form': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          String? hashid;
          String? alatHashid;
          if (args is Map<String, dynamic>) {
            hashid = args['hashid'] as String?;
            alatHashid = args['alatHashid'] as String?;
          }
          return KalibrasiFormPage(hashid: hashid, alatHashid: alatHashid);
        },

        // ==================== PENGAMBILAN ALAT ====================
        '/pengambilan_alat/list': (context) => const PengambilanAlatListPage(),
        '/pengambilan_alat/form': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          String? hashid;
          String? alatHashid;
          if (args is Map<String, dynamic>) {
            hashid = args['hashid'] as String?;
            alatHashid = args['alatHashid'] as String?;
          } else if (args is String) {
            hashid = args;
          }
          return PengambilanAlatFormPage(
            hashid: hashid,
            alatHashid: alatHashid,
          );
        },

        // ==================== PENGEMBALIAN ALAT ====================
        '/pengembalian_alat/list': (context) =>
            const PengembalianAlatListPage(),
        '/pengembalian_alat/form': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          String? hashid;
          String? pengambilanHashid;
          if (args is Map<String, dynamic>) {
            hashid = args['hashid'] as String?;
            pengambilanHashid = args['pengambilanHashid'] as String?;
          } else if (args is String) {
            hashid = args;
          }
          return PengembalianAlatFormPage(
            hashid: hashid,
            pengambilanHashid: pengambilanHashid,
          );
        },
      },

      // ==================== ON GENERATE ROUTE (Detail Pages) ====================
      onGenerateRoute: (settings) {
        if (settings.name == '/barang/detail') {
          final hashid = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) => BarangDetailPage(hashid: hashid ?? ''),
          );
        }
        if (settings.name == '/pengambilan/detail') {
          final hashid = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) => PengambilanDetailPage(hashid: hashid ?? ''),
          );
        }
        if (settings.name == '/purchase/detail') {
          final hashid = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) =>
                PurchaseRequestDetailPage(hashid: hashid ?? ''),
          );
        }
        if (settings.name == '/alat/detail') {
          final hashid = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) => AlatDetailPage(hashid: hashid ?? ''),
          );
        }
        if (settings.name == '/kalibrasi/detail') {
          final hashid = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (_) => KalibrasiDetailPage(hashid: hashid ?? ''),
          );
        }
        if (settings.name == '/pengambilan_alat/detail') {
          final hashid = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (_) => PengambilanAlatDetailPage(hashid: hashid ?? ''),
          );
        }
        if (settings.name == '/pengembalian_alat/detail') {
          final hashid = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (_) => PengembalianAlatDetailPage(hashid: hashid ?? ''),
          );
        }

        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Halaman Tidak Ditemukan')),
            body: Center(
              child: Text(
                'Route ${settings.name ?? "tidak dikenal"} tidak ditemukan',
              ),
            ),
          ),
        );
      },
    );
  }

  ThemeData _buildAppTheme() {
    const seedColor = Color(0xFF001F3F);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      primary: const Color(0xFF001F3F),
      secondary: const Color(0xFF2E7D32),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF001F3F),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
