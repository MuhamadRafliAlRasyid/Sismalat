import 'package:flutter/material.dart';
import '../../services/pengambilan_alat_service.dart';
import '../../services/alat_service.dart';
import '../../services/api_service.dart';

class PengambilanAlatFormPage extends StatefulWidget {
  final String? hashid;
  final String? alatHashid; // dari QR
  const PengambilanAlatFormPage({super.key, this.hashid, this.alatHashid});

  @override
  State<PengambilanAlatFormPage> createState() =>
      _PengambilanAlatFormPageState();
}

class _PengambilanAlatFormPageState extends State<PengambilanAlatFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isEdit = false;

  final _jumlahCtrl = TextEditingController();
  final _satuanCtrl = TextEditingController(text: 'pcs');
  final _keperluanCtrl = TextEditingController();

  String? selectedAlatHashid;
  Map<String, dynamic>? selectedAlatDetail;

  List<dynamic> searchResults = [];
  final TextEditingController _searchCtrl = TextEditingController();

  // 📌 Untuk dummy, Anda bisa ganti dengan service alat yang sebenarnya
  Future<void> _searchAlat(String query) async {
    // Panggil API alat (misal /api/alat?search=...)
    final result = await ApiService.get('alat?search=$query'); // sesuaikan
    if (result['status'] == true) {
      setState(() => searchResults = result['data'] ?? []);
    }
  }

  void _selectAlat(Map<String, dynamic> alat) {
    setState(() {
      selectedAlatHashid = alat['hashid'];
      selectedAlatDetail = alat;
      searchResults = [];
      _searchCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final data = {
      'alat_id': selectedAlatHashid,
      'jumlah': int.tryParse(_jumlahCtrl.text) ?? 1,
      'satuan': _satuanCtrl.text,
      'keperluan': _keperluanCtrl.text,
      'waktu_pengambilan': DateTime.now().toIso8601String(),
      'bagian_id': 1, // sesuaikan
    };
    final result = isEdit
        ? await PengambilanAlatService.update(widget.hashid!, data)
        : await PengambilanAlatService.create(data);
    if (result['status'] == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Pengambilan' : 'Ambil Alat')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(labelText: 'Cari Alat'),
              onChanged: _searchAlat,
            ),
            if (searchResults.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (ctx, i) {
                    final a = searchResults[i];
                    return ListTile(
                      title: Text(a['nama_alat'] ?? ''),
                      onTap: () => _selectAlat(a),
                    );
                  },
                ),
              ),
            if (selectedAlatDetail != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(selectedAlatDetail!['nama_alat'] ?? ''),
                ),
              ),
            TextFormField(
              controller: _jumlahCtrl,
              decoration: const InputDecoration(labelText: 'Jumlah'),
            ),
            TextFormField(
              controller: _satuanCtrl,
              decoration: const InputDecoration(labelText: 'Satuan'),
            ),
            TextFormField(
              controller: _keperluanCtrl,
              decoration: const InputDecoration(labelText: 'Keperluan'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _save, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }
}
