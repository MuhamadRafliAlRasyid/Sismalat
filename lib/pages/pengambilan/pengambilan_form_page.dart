import 'package:flutter/material.dart';
import '../../services/pengambilan_service.dart';
import '../../services/barang_service.dart';

class PengambilanFormPage extends StatefulWidget {
  final String? hashid; // untuk edit
  final String? sparepartHashid; // dari QR / Login

  const PengambilanFormPage({super.key, this.hashid, this.sparepartHashid});

  @override
  State<PengambilanFormPage> createState() => _PengambilanFormPageState();
}

class _PengambilanFormPageState extends State<PengambilanFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isEdit = false;

  final _jumlahCtrl = TextEditingController();
  final _satuanCtrl = TextEditingController(text: 'PCS');
  final _keperluanCtrl = TextEditingController();
  final _waktuPengambilanCtrl = TextEditingController();

  String partType = 'baru';

  // Pencarian Sparepart
  String? selectedSparepartHashid;
  Map<String, dynamic>? selectedSparepartDetail;

  int stokBaru = 0;
  int stokBekas = 0;

  // Hasil pencarian
  List<dynamic> searchResults = [];
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  bool get isFromQR =>
      widget.sparepartHashid != null && widget.sparepartHashid!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    isEdit = widget.hashid != null && widget.hashid!.isNotEmpty;

    _waktuPengambilanCtrl.text = DateTime.now().toIso8601String().split('T')[0];

    if (isFromQR) {
      selectedSparepartHashid = widget.sparepartHashid!.trim();
      _loadSparepartDetailFromHash();
    } else if (isEdit) {
      _loadEditDetail(); // ← Ini yang diperbaiki
    }
  }

  // Load detail dari QR
  Future<void> _loadSparepartDetailFromHash() async {
    setState(() => isLoading = true);

    final result = await BarangService.getByIdentifier(
      selectedSparepartHashid!,
    );

    if (result['status'] == true && result['data'] != null) {
      final data = result['data'] as Map<String, dynamic>;
      setState(() {
        selectedSparepartDetail = data;
        stokBaru = data['jumlah_baru'] ?? 0;
        stokBekas = data['jumlah_bekas'] ?? 0;
      });
    }

    setState(() => isLoading = false);
  }

  // ================= LOAD DETAIL SAAT EDIT =================
  Future<void> _loadEditDetail() async {
    setState(() => isLoading = true);

    final result = await PengambilanService.getById(widget.hashid!);

    if (result['status'] == true && result['data'] != null) {
      final data = result['data'] as Map<String, dynamic>;

      // Isi form
      _jumlahCtrl.text = (data['jumlah'] ?? 0).toString();
      _satuanCtrl.text = data['satuan'] ?? 'PCS';
      _keperluanCtrl.text = data['keperluan'] ?? '';
      _waktuPengambilanCtrl.text = data['waktu_pengambilan'] ?? '';

      partType = data['part_type'] ?? 'baru';

      // Ambil sparepart yang dipilih
      selectedSparepartHashid =
          data['spareparts_id']?.toString() ??
          data['sparepart']?['hashid']?.toString();

      if (selectedSparepartHashid != null) {
        // Load detail stok sparepart
        final sparepartResult = await BarangService.getByIdentifier(
          selectedSparepartHashid!,
        );
        if (sparepartResult['status'] == true &&
            sparepartResult['data'] != null) {
          final sparepartData = sparepartResult['data'] as Map<String, dynamic>;
          setState(() {
            selectedSparepartDetail = sparepartData;
            stokBaru = sparepartData['jumlah_baru'] ?? 0;
            stokBekas = sparepartData['jumlah_bekas'] ?? 0;
          });
        }
      }

      print("DEBUG Edit Loaded - Sparepart Hashid: $selectedSparepartHashid");
    } else {
      print("DEBUG Gagal load edit data: ${result['message']}");
    }

    setState(() => isLoading = false);
  }

  // Pencarian sparepart
  Future<void> _searchSparepart(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    setState(() => isSearching = true);

    final result = await BarangService.getAll(search: query.trim());

    if (result['status'] == true) {
      setState(() {
        searchResults = result['data'] ?? [];
      });
    }

    setState(() => isSearching = false);
  }

  // Pilih sparepart dari hasil pencarian
  void _selectSparepart(Map<String, dynamic> sparepart) {
    setState(() {
      selectedSparepartHashid = sparepart['hashid']?.toString();
      selectedSparepartDetail = sparepart;
      stokBaru = sparepart['jumlah_baru'] ?? 0;
      stokBekas = sparepart['jumlah_bekas'] ?? 0;
      searchResults = [];
      _searchController.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final jumlah = int.tryParse(_jumlahCtrl.text.trim()) ?? 0;
    final stokTersedia = partType == 'baru' ? stokBaru : stokBekas;

    if (jumlah > stokTersedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah melebihi stok yang tersedia!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final data = {
      'spareparts_id': selectedSparepartHashid,
      'part_type': partType,
      'jumlah': jumlah,
      'satuan': _satuanCtrl.text.trim(),
      'keperluan': _keperluanCtrl.text.trim(),
      'waktu_pengambilan': _waktuPengambilanCtrl.text,
    };

    final result = isEdit
        ? await PengambilanService.update(widget.hashid!, data)
        : await PengambilanService.create(data);

    setState(() => isLoading = false);

    if (result['status'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Pengambilan berhasil diperbarui'
                : 'Pengambilan berhasil dicatat',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menyimpan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Pengambilan' : 'Tambah Pengambilan Sparepart',
        ),
        backgroundColor: const Color(0xFF001F3F),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================== PENCARIAN SPAREPART ====================
                    if (!isFromQR && !isEdit)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cari Sparepart',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'Ketik nama sparepart...',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) {
                              _searchSparepart(value);
                            },
                          ),
                          const SizedBox(height: 8),

                          // Hasil Pencarian
                          if (searchResults.isNotEmpty)
                            Container(
                              height: 220,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: searchResults.length,
                                itemBuilder: (context, index) {
                                  final item = searchResults[index];
                                  return ListTile(
                                    title: Text(item['nama_part'] ?? '-'),
                                    subtitle: Text(
                                      "${item['merk'] ?? ''} - ${item['model'] ?? ''}",
                                    ),
                                    onTap: () => _selectSparepart(item),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),

                    // ==================== INFO STOK SETELAH DIPILIH ====================
                    if (selectedSparepartDetail != null)
                      Card(
                        color: Colors.blue[50],
                        margin: const EdgeInsets.only(top: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedSparepartDetail!['nama_part'] ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Stok Baru: $stokBaru | Stok Bekas: $stokBekas',
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Jenis Part
                    const Text(
                      'Jenis Part',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'baru', label: Text('Part Baru')),
                        ButtonSegment(
                          value: 'bekas',
                          label: Text('Part Bekas'),
                        ),
                      ],
                      selected: {partType},
                      onSelectionChanged: (Set<String> selection) {
                        setState(() => partType = selection.first);
                      },
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _jumlahCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Jumlah',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Wajib diisi'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _satuanCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Satuan',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _keperluanCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Keperluan',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Wajib diisi'
                          : null,
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _waktuPengambilanCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Waktu Pengambilan',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          _waktuPengambilanCtrl.text = picked
                              .toIso8601String()
                              .split('T')[0];
                        }
                      },
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF001F3F),
                        ),
                        child: Text(
                          isEdit ? 'Simpan Perubahan' : 'Simpan',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _jumlahCtrl.dispose();
    _satuanCtrl.dispose();
    _keperluanCtrl.dispose();
    _waktuPengambilanCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
