import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Services & Providers
import 'services/alat_service.dart';
import 'services/provider/alat_provider.dart';

// Auth
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';

// Dashboard & Profile
import 'pages/dashboard_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/profile/edit_profile_page.dart';
import 'pages/profile/user_list_page.dart';

// Bagian
import 'pages/bagian/bagian_list_page.dart';
import 'pages/bagian/bagian_form_page.dart';

// Pengembalian
import 'pages/pengembalian/pengembalian_list_page.dart';
import 'pages/pengembalian/pengembalian_form_page.dart';

// Barang
import 'pages/barang/barang_list_page.dart';
import 'pages/barang/barang_form_page.dart';
import 'pages/barang/barang_detail_page.dart';
import 'pages/barang/trashed_barang_page.dart';

// Pengambilan
import 'pages/pengambilan/pengambilan_list_page.dart';
import 'pages/pengambilan/pengambilan_form_page.dart';
import 'pages/pengambilan/pengambilan_detail_page.dart';

// Purchase
import 'pages/purchase/purchase_request_list_page.dart';
import 'pages/purchase/purchase_request_detail_page.dart';
import 'pages/purchase/purchase_request_form_page.dart';

// Notification
import 'pages/profile/notification_page.dart';

// QR Scanner & Landing
import 'pages/qr_scanner_page.dart';
import 'pages/landing_page.dart';

// Alat (baru)
import 'pages/alat/alat_list_page.dart';
import 'pages/alat/alat_form_page.dart';
import 'pages/alat/alat_detail_page.dart';

void main() {
  // Inisialisasi service (token akan diatur setelah login)
  final alatService = AlatService(
    baseUrl: 'https://your-api-url.com/api', // ganti dengan URL backend Anda
    token: '', // nanti diisi setelah login
  );

  runApp(
    MultiProvider(
      providers: [
        // Provider untuk AlatProvider (state management list alat)
        ChangeNotifierProvider(
          create: (_) => AlatProvider(service: alatService),
        ),
        // Provider untuk AlatService (agar bisa diakses langsung via context.read)
        Provider.value(value: alatService),
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
      initialRoute: '/landing_page',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/profile': (context) => const ProfilePage(),
        '/landing_page': (context) => const LandingPage(),
        '/notifications': (context) => const NotificationPage(),
        '/qr-scanner': (context) => const QRScannerPage(),

        // Bagian
        '/bagian/list': (context) => const BagianListPage(),
        '/bagian/form': (context) {
          final hashid = ModalRoute.of(context)?.settings.arguments as String?;
          return BagianFormPage(hashid: hashid);
        },

        // Profile Edit
        '/profile/edit': (context) {
          final userData =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return EditProfilePage(userData: userData);
        },

        // User Management
        '/user/list': (context) => const UserListPage(),

        // Barang
        '/barang/list': (context) => const BarangListPage(),
        '/barang/form': (context) {
          final hashid = ModalRoute.of(context)?.settings.arguments as String?;
          return BarangFormPage(hashid: hashid);
        },
        '/barang/trashed': (context) => const TrashedBarangPage(),

        // Pengambilan
        '/pengambilan/list': (context) => const PengambilanListPage(),
        '/pengambilan/form': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          String? hashid;
          String? sparepartHashid;
          if (args is String) {
            hashid = args;
          } else if (args is Map<String, dynamic>) {
            hashid = args['hashid'] as String?;
            sparepartHashid = args['sparepartHashid'] as String?;
          }
          return PengambilanFormPage(
            hashid: hashid,
            sparepartHashid: sparepartHashid,
          );
        },

        // Pengembalian
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

        // Purchase Request
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

        // Alat (sesuai dengan service baru)
        '/alat/list': (context) => const AlatListPage(),
        '/alat/form': (context) {
          final hashid = ModalRoute.of(context)?.settings.arguments as String?;
          return AlatFormPage(hashid: hashid);
        },
        '/alat/trashed': (context) {
          // halaman trashed bisa dibuat terpisah, sementara arahkan ke list dulu
          // TODO: implementasikan halaman trashed untuk alat
          return const Scaffold(
            body: Center(child: Text('Trashed Alat - Coming Soon')),
          );
        },
      },
      onGenerateRoute: (settings) {
        // Detail routes (menggunakan arguments)
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

        // Fallback
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
