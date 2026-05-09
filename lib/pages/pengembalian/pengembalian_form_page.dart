import 'package:flutter/material.dart';
import '../../services/pengembalian_service.dart';
import '../../services/pengambilan_service.dart';

class PengembalianFormPage extends StatefulWidget {
  final String? hashid;

  const PengembalianFormPage({super.key, this.hashid});

  @override
  State<PengembalianFormPage> createState() => _PengembalianFormPageState();
}

class _PengembalianFormPageState extends State<PengembalianFormPage> {
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool isEdit = false;

  final _jumlahCtrl = TextEditingController();
  final _alasanCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();

  String? selectedKondisi = 'baik';
  String? selectedPengambilanHashid;

  List<dynamic> pengambilanOptions = [];
  Map<String, dynamic>? selectedPengambilanData;

  @override
  void initState() {
    super.initState();
    isEdit = widget.hashid != null && widget.hashid!.isNotEmpty;
    _initPage();
  }

  // ================= INIT =================
  Future<void> _initPage() async {
    setState(() => isLoading = true);

    try {
      final resultPengambilan = await PengambilanService.getAll();

      if (resultPengambilan['status'] == true) {
        pengambilanOptions = resultPengambilan['data'] ?? [];
      }

      print("DEBUG dropdown loaded: ${pengambilanOptions.length}");

      // ================= EDIT MODE =================
      if (isEdit) {
        final result = await PengembalianService.getById(widget.hashid!);

        if (result['status'] == true && result['data'] != null) {
          final data = result['data'];

          _jumlahCtrl.text = data['jumlah_dikembalikan']?.toString() ?? '';
          _alasanCtrl.text = data['alasan'] ?? '';
          _keteranganCtrl.text = data['keterangan'] ?? '';
          selectedKondisi = data['kondisi'] ?? 'baik';

          // 🔥 FIX: pastikan string + fallback
          selectedPengambilanHashid =
              data['pengambilan']?['hashid']?.toString() ??
              data['pengambilan']?['id']?.toString();

          print("DEBUG selected hashid: $selectedPengambilanHashid");

          // 🔥 FIX: cari di dropdown
          for (var item in pengambilanOptions) {
            if (item['hashid']?.toString() == selectedPengambilanHashid) {
              selectedPengambilanData = item;
              break;
            }
          }

          // 🔥 fallback kalau tidak ketemu
          if (selectedPengambilanData == null) {
            print("❌ fallback ke data API");
            selectedPengambilanData = data['pengambilan'];
          }

          print("DEBUG selected data: $selectedPengambilanData");
        } else {
          _showError(result['message'] ?? 'Gagal load data');
        }
      }
    } catch (e) {
      print("❌ INIT ERROR: $e");
      _showError("Terjadi kesalahan");
    }

    setState(() => isLoading = false);
  }

  // ================= SAVE =================
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final data = {
      'pengambilan_hashid': selectedPengambilanHashid,
      'jumlah_dikembalikan': int.parse(_jumlahCtrl.text.trim()),
      'kondisi': selectedKondisi,
      'alasan': _alasanCtrl.text.trim(),
      'keterangan': _keteranganCtrl.text.trim(),
    };

    try {
      final result = isEdit
          ? await PengembalianService.update(widget.hashid!, data)
          : await PengembalianService.create(data);

      if (result['status'] == true) {
        _showSuccess(
          isEdit
              ? 'Pengembalian berhasil diperbarui'
              : 'Pengembalian berhasil dicatat',
        );
        Navigator.pop(context, true);
      } else {
        _showError(result['message'] ?? 'Gagal menyimpan');
      }
    } catch (e) {
      print("❌ SAVE ERROR: $e");
      _showError("Terjadi kesalahan saat menyimpan");
    }

    setState(() => isLoading = false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Pengembalian' : 'Tambah Pengembalian'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= CREATE =================
                    if (!isEdit) ...[
                      DropdownButtonFormField<String>(
                        value:
                            pengambilanOptions.any(
                              (e) =>
                                  e['hashid']?.toString() ==
                                  selectedPengambilanHashid,
                            )
                            ? selectedPengambilanHashid
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Pengambilan',
                          border: OutlineInputBorder(),
                        ),
                        items: pengambilanOptions.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['hashid']?.toString(),
                            child: Text(
                              "${item['sparepart']?['nama_part'] ?? '-'} - ${item['user']?['name'] ?? '-'}",
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          final selected = pengambilanOptions.firstWhere(
                            (e) => e['hashid']?.toString() == value,
                            orElse: () => {},
                          );

                          setState(() {
                            selectedPengambilanHashid = value;
                            selectedPengambilanData = selected.isNotEmpty
                                ? selected
                                : null;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Pilih data' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ================= EDIT =================
                    if (isEdit && selectedPengambilanData != null) ...[
                      Card(
                        color: Colors.grey[200],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Detail Pengambilan',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sparepart: ${selectedPengambilanData?['sparepart']?['nama_part'] ?? '-'}',
                              ),
                              Text(
                                'User: ${selectedPengambilanData?['user']?['name'] ?? '-'}',
                              ),
                              Text(
                                'Jumlah Diambil: ${selectedPengambilanData?['jumlah'] ?? 0}',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ================= JUMLAH =================
                    TextFormField(
                      controller: _jumlahCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Dikembalikan',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Wajib diisi';
                        }

                        final val = int.tryParse(value);
                        if (val == null || val < 1) {
                          return 'Tidak valid';
                        }

                        if (selectedPengambilanData != null) {
                          final max = selectedPengambilanData!['jumlah'] ?? 0;

                          if (val > max) {
                            return 'Maksimal $max';
                          }
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ================= KONDISI =================
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile(
                            title: const Text('Baik'),
                            value: 'baik',
                            groupValue: selectedKondisi,
                            onChanged: (v) =>
                                setState(() => selectedKondisi = v),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile(
                            title: const Text('Rusak'),
                            value: 'rusak',
                            groupValue: selectedKondisi,
                            onChanged: (v) =>
                                setState(() => selectedKondisi = v),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _alasanCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Alasan',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _keteranganCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _save,
                        child: Text(isEdit ? 'Update' : 'Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  @override
  void dispose() {
    _jumlahCtrl.dispose();
    _alasanCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }
}
