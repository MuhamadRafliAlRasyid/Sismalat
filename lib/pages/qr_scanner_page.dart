// lib/pages/qr_scanner_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/auth_service.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _isProcessing = false;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: _flashOn,
    );

    // Mulai kamera setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _controller.stop();
        break;
      case AppLifecycleState.resumed:
        _controller.start();
        break;
      default:
        break;
    }
  }

  void _toggleFlash() {
    setState(() {
      _flashOn = !_flashOn;
      _controller.toggleTorch();
    });
  }

  Future<void> _handleScan(String rawValue) async {
    if (_isProcessing) return;

    final hashid = _extractHashId(rawValue);
    if (hashid.isEmpty) {
      _showFeedback('QR Code tidak valid', isError: true);
      return;
    }

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      await AuthService.saveTempSparepart(hashid);
      if (!mounted) return;
      _showFeedback('QR berhasil dibaca: $hashid', isError: false);

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pop(context, hashid); // kembalikan hashid
      }
    } catch (e) {
      if (!mounted) return;
      _showFeedback('Gagal menyimpan QR Code', isError: true);
      setState(() => _isProcessing = false);
    }
  }

  void _showFeedback(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isError
              ? Colors.red.shade700
              : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  /// Ekstrak hash ID dari berbagai format QR Code
  String _extractHashId(String value) {
    try {
      // Jika mengandung query string (URL)
      if (value.contains('?')) {
        final uri = Uri.parse(value);

        // Prioritas 1: alat_id
        final alatId = uri.queryParameters['alat_id'];
        if (alatId != null && alatId.isNotEmpty) return alatId;

        // Prioritas 2: spareparts_id (untuk kompatibilitas lama)
        final sparepartId = uri.queryParameters['spareparts_id'];
        if (sparepartId != null && sparepartId.isNotEmpty) return sparepartId;

        // Jika tidak ada, ambil parameter pertama yang ada
        if (uri.queryParameters.isNotEmpty) {
          return uri.queryParameters.values.first;
        }
      }

      // Jika path biasa (tanpa query), ambil segmen terakhir
      if (value.contains('/')) {
        final segments = value.split('/');
        final last = segments.last;
        if (last.isNotEmpty && !last.contains('?')) return last;
      }

      // Fallback: trim nilai mentah
      return value.trim();
    } catch (_) {
      return value.trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Barang'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Kamera pemindai
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isProcessing) return;
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue != null) {
                  _handleScan(barcode.rawValue!);
                  break;
                }
              }
            },
            errorBuilder: (context, error) {
              return _buildPermissionError();
            },
          ),

          // Overlay semi-transparan dengan area scan
          _buildScanOverlay(),

          // Indikator loading
          if (_isProcessing)
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Tombol flash
          Positioned(
            bottom: 40,
            right: 30,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white.withOpacity(0.9),
              onPressed: _toggleFlash,
              child: Icon(
                _flashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Stack(
      children: [
        ClipPath(
          clipper: _ScanFrameClipper(),
          child: Container(color: Colors.black54),
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.cyanAccent, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const _ScannerAnimation(),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Izin kamera diperlukan untuk memindai QR Code',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[300], fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Cara mengaktifkan'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Izin Kamera'),
                    content: const Text(
                      'Silakan buka Pengaturan > Aplikasi > Inventaris > Izin, '
                      'lalu aktifkan izin Kamera.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Clipper untuk membuat area transparan di tengah
class _ScanFrameClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double frameSize = 250;
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: frameSize,
            height: frameSize,
          ),
          const Radius.circular(16),
        ),
      )
      ..fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Animasi garis bergerak vertikal di dalam frame
class _ScannerAnimation extends StatefulWidget {
  const _ScannerAnimation();

  @override
  _ScannerAnimationState createState() => _ScannerAnimationState();
}

class _ScannerAnimationState extends State<_ScannerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 10, end: 240).animate(_animCtrl);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: _anim.value,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.cyanAccent.withOpacity(0),
                      Colors.cyanAccent,
                      Colors.cyanAccent.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
