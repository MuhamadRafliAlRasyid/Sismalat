// lib/pages/qr_scanner_page.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/auth_service.dart';

class QRScannerPage extends StatelessWidget {
  const QRScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Barang'), centerTitle: true),
      body: MobileScanner(
        onDetect: (capture) async {
          for (final barcode in capture.barcodes) {
            if (barcode.rawValue != null) {
              String rawValue = barcode.rawValue!.trim();

              // Ekstrak hashid
              String hashid = _extractHashId(rawValue);

              if (hashid.isEmpty) {
                _showError(context, 'QR Code tidak valid');
                return;
              }

              try {
                await AuthService.saveTempSparepart(hashid);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('QR berhasil dibaca: $hashid'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  Navigator.pop(context, hashid);
                }
              } catch (e) {
                if (context.mounted) {
                  _showError(context, 'Gagal menyimpan QR Code');
                }
              }
              return;
            }
          }
        },
      ),
    );
  }

  String _extractHashId(String value) {
    try {
      // Jika berupa full URL
      if (value.contains('?')) {
        final uri = Uri.parse(value);
        return uri.queryParameters['spareparts_id'] ?? '';
      }
      // Jika langsung hashid
      return value;
    } catch (_) {
      return value; // fallback
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
