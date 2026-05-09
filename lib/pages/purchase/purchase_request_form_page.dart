import 'package:flutter/material.dart';
import '../../services/purchase_request_service.dart';
import '../../services/barang_service.dart';

class PurchaseRequestFormPage extends StatefulWidget {
  final String? hashid; // untuk edit
  final String? sparepartHashid; // dari notifikasi / QR

  const PurchaseRequestFormPage({super.key, this.hashid, this.sparepartHashid});

  @override
  State<PurchaseRequestFormPage> createState() =>
      _PurchaseRequestFormPageState();
}

class _PurchaseRequestFormPageState extends State<PurchaseRequestFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isEdit = false;

  // Controllers
  final _partNumberCtrl = TextEditingController();
  final _linkWebsiteCtrl = TextEditingController();
  final _waktuRequestCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _satuanCtrl = TextEditingController(text: 'PCS');
  final _masDeliverCtrl = TextEditingController();
  final _untukApaCtrl = TextEditingController();
  final _picCtrl = TextEditingController();
  final _quotationLeadTimeCtrl = TextEditingController();
  final _searchController = TextEditingController();

  Map<String, dynamic>? selectedSparepart;

  // Untuk searchable dropdown
  List<dynamic> searchResults = [];
  bool isSearching = false;

  bool get isFromNotification =>
      widget.sparepartHashid != null && widget.sparepartHashid!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    isEdit = widget.hashid != null && widget.hashid!.isNotEmpty;

    _waktuRequestCtrl.text = DateTime.now().toIso8601String().split('T')[0];
    _masDeliverCtrl.text = DateTime.now().toIso8601String().split('T')[0];

    if (isEdit) {
      _loadEditData();
    } else if (isFromNotification) {
      _loadSparepartFromNotification(widget.sparepartHashid!);
    }
  }

  // ==================== LOAD DATA SAAT EDIT ====================
  Future<void> _loadEditData() async {
    setState(() => isLoading = true);

    final result = await PurchaseRequestService.getById(widget.hashid!);

    if (result['status'] == true && result['data'] != null) {
      final data = result['data'];

      setState(() {
        _partNumberCtrl.text = data['part_number'] ?? '';
        _linkWebsiteCtrl.text = data['link_website'] ?? '';
        _waktuRequestCtrl.text = (data['waktu_request'] ?? '').toString().split(
          'T',
        )[0];
        _quantityCtrl.text = data['quantity']?.toString() ?? '';
        _satuanCtrl.text = data['satuan'] ?? 'PCS';
        _masDeliverCtrl.text = (data['mas_deliver'] ?? '').toString().split(
          'T',
        )[0];
        _untukApaCtrl.text = data['untuk_apa'] ?? '';
        _picCtrl.text = data['pic'] ?? '';
        _quotationLeadTimeCtrl.text = data['quotation_lead_time'] ?? '';

        // Load sparepart jika ada
        if (data['sparepart_id'] != null || data['sparepart'] != null) {
          final spareId =
              data['sparepart_id']?.toString() ??
              data['sparepart']?['hashid']?.toString();
          if (spareId != null) {
            _loadSparepartForEdit(spareId);
          }
        }
      });
    }

    setState(() => isLoading = false);
  }

  Future<void> _loadSparepartForEdit(String sparepartHashid) async {
    final result = await BarangService.getById(sparepartHashid);
    if (result['status'] == true && result['data'] != null) {
      setState(() {
        selectedSparepart = result['data'];
      });
    }
  }

  // ==================== LOAD DARI NOTIFIKASI / QR ====================
  Future<void> _loadSparepartFromNotification(String hashid) async {
    setState(() => isLoading = true);

    final result = await BarangService.getById(hashid);

    if (result['status'] == true && result['data'] != null) {
      setState(() {
        selectedSparepart = result['data'];
        _partNumberCtrl.text =
            result['data']['model'] ?? result['data']['part_number'] ?? '';
      });
    }
    setState(() => isLoading = false);
  }

  // ==================== SEARCH REAL-TIME ====================
  Future<void> _searchSparepart(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    setState(() => isSearching = true);

    final result = await BarangService.getAll(search: query);

    if (result['status'] == true) {
      setState(() {
        searchResults = result['data'] ?? [];
      });
    }

    setState(() => isSearching = false);
  }

  void _onSparepartSelected(dynamic sparepart) {
    setState(() {
      selectedSparepart = sparepart;
      _partNumberCtrl.text =
          sparepart['model'] ?? sparepart['part_number'] ?? '';
      _searchController.clear();
      searchResults = [];
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!isFromNotification && !isEdit && selectedSparepart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih Sparepart terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final data = {
      'nama_part': selectedSparepart?['nama_part'] ?? '',
      'part_number': _partNumberCtrl.text.trim(),
      'link_website': _linkWebsiteCtrl.text.trim(),
      'waktu_request': _waktuRequestCtrl.text,
      'quantity': int.tryParse(_quantityCtrl.text.trim()) ?? 1,
      'satuan': _satuanCtrl.text,
      'mas_deliver': _masDeliverCtrl.text,
      'untuk_apa': _untukApaCtrl.text.trim(),
      'pic': _picCtrl.text.trim(),
      'quotation_lead_time': _quotationLeadTimeCtrl.text.trim(),
      if (selectedSparepart != null)
        'sparepart_id': selectedSparepart!['hashid'],
    };

    final result = isEdit
        ? await PurchaseRequestService.update(widget.hashid!, data)
        : await PurchaseRequestService.create(data);

    setState(() => isLoading = false);

    if (result['status'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Berhasil disimpan'),
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
          isEdit ? 'Edit Purchase Request' : 'Tambah Purchase Request',
        ),
        backgroundColor: const Color(0xFF001F3F),
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
                    // ==================== SEARCHABLE NAMA PART ====================
                    if (!isFromNotification && !isEdit)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nama Part',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'Ketik nama part...',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.search),
                            ),
                            onChanged: _searchSparepart,
                          ),
                          const SizedBox(height: 8),

                          if (isSearching)
                            const Center(child: CircularProgressIndicator())
                          else if (searchResults.isNotEmpty)
                            Container(
                              height: 300,
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
                                    title: Text(item['nama_part'] ?? ''),
                                    subtitle: Text(item['model'] ?? ''),
                                    onTap: () => _onSparepartSelected(item),
                                  );
                                },
                              ),
                            )
                          else if (_searchController.text.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Tidak ditemukan',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                        ],
                      )
                    else if (selectedSparepart != null)
                      Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sparepart Terpilih',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Nama Part : ${selectedSparepart!['nama_part'] ?? '-'}',
                              ),
                              Text(
                                'Part Number : ${selectedSparepart!['model'] ?? selectedSparepart!['part_number'] ?? '-'}',
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    _buildTextField(
                      _partNumberCtrl,
                      'Part Number / Model',
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_linkWebsiteCtrl, 'Link Website'),
                    const SizedBox(height: 16),
                    _buildDateField(_waktuRequestCtrl, 'Waktu Request'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _quantityCtrl,
                      'Quantity',
                      keyboardType: TextInputType.number,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    _buildSatuanDropdown(),
                    const SizedBox(height: 16),
                    _buildDateField(_masDeliverCtrl, 'Masa Deliver'),
                    const SizedBox(height: 16),
                    _buildTextField(_untukApaCtrl, 'Untuk Apa', maxLines: 3),
                    const SizedBox(height: 16),
                    _buildTextField(_picCtrl, 'PIC'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _quotationLeadTimeCtrl,
                      'Quotation Lead Time',
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
                          isEdit
                              ? 'Simpan Perubahan'
                              : 'Ajukan Purchase Request',
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

  // ==================== HELPER WIDGETS ====================
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (value) => (value == null || value.trim().isEmpty)
                ? '$label wajib diisi'
                : null
          : null,
    );
  }

  Widget _buildDateField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) {
          controller.text = picked.toIso8601String().split('T')[0];
        }
      },
    );
  }

  Widget _buildSatuanDropdown() {
    const list = ['PCS', 'SET', 'UNIT', 'BOX', 'METER', 'LITER'];
    return DropdownButtonFormField<String>(
      value: _satuanCtrl.text,
      decoration: const InputDecoration(
        labelText: 'Satuan',
        border: OutlineInputBorder(),
      ),
      items: list
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (val) => _satuanCtrl.text = val ?? 'PCS',
    );
  }

  @override
  void dispose() {
    _partNumberCtrl.dispose();
    _linkWebsiteCtrl.dispose();
    _waktuRequestCtrl.dispose();
    _quantityCtrl.dispose();
    _satuanCtrl.dispose();
    _masDeliverCtrl.dispose();
    _untukApaCtrl.dispose();
    _picCtrl.dispose();
    _quotationLeadTimeCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
