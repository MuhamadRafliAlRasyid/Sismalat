import 'package:flutter/material.dart';
import '../../services/barang_service.dart';

class BarangFormPage extends StatefulWidget {
  final String? hashid; // null = Create, ada value = Edit

  const BarangFormPage({super.key, this.hashid});

  @override
  State<BarangFormPage> createState() => _BarangFormPageState();
}

class _BarangFormPageState extends State<BarangFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isEdit = false;

  // Controllers
  final _namaPartCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _merkCtrl = TextEditingController();
  final _jumlahBaruCtrl = TextEditingController();
  final _jumlahBekasCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _patokanHargaCtrl = TextEditingController();
  final _rukNoCtrl = TextEditingController();
  final _purchaseDateCtrl = TextEditingController();
  final _deliveryDateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    isEdit = widget.hashid != null && widget.hashid!.isNotEmpty;

    if (isEdit) {
      print('DEBUG: Memuat data edit untuk hashid: ${widget.hashid}');
      _loadDetail();
    }
  }

  Future<void> _loadDetail() async {
    setState(() => isLoading = true);

    final result = await BarangService.getById(widget.hashid!);

    print('DEBUG _loadDetail result: $result');

    if (result['status'] == true && result['data'] != null) {
      final data = result['data'];

      _namaPartCtrl.text = data['nama_part']?.toString() ?? '';
      _modelCtrl.text = data['model']?.toString() ?? '';
      _merkCtrl.text = data['merk']?.toString() ?? '';
      _jumlahBaruCtrl.text = data['jumlah_baru']?.toString() ?? '';
      _jumlahBekasCtrl.text = data['jumlah_bekas']?.toString() ?? '';
      _supplierCtrl.text = data['supplier']?.toString() ?? '';
      _patokanHargaCtrl.text = data['patokan_harga']?.toString() ?? '';
      _rukNoCtrl.text = data['ruk_no']?.toString() ?? '';
      _purchaseDateCtrl.text =
          data['purchase_date']?.toString().split('T')[0] ?? '';
      _deliveryDateCtrl.text =
          data['delivery_date']?.toString().split('T')[0] ?? '';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal memuat data'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final data = {
      'nama_part': _namaPartCtrl.text.trim(),
      'model': _modelCtrl.text.trim(),
      'merk': _merkCtrl.text.trim(),
      'jumlah_baru': int.tryParse(_jumlahBaruCtrl.text) ?? 0,
      'jumlah_bekas': int.tryParse(_jumlahBekasCtrl.text) ?? 0,
      'supplier': _supplierCtrl.text.trim(),
      'patokan_harga': double.tryParse(_patokanHargaCtrl.text) ?? 0.0,
      'ruk_no': _rukNoCtrl.text.trim(),
      'purchase_date': _purchaseDateCtrl.text.isNotEmpty
          ? _purchaseDateCtrl.text
          : null,
      'delivery_date': _deliveryDateCtrl.text.isNotEmpty
          ? _deliveryDateCtrl.text
          : null,
    };

    final result = isEdit
        ? await BarangService.update(widget.hashid!, data)
        : await BarangService.create(data);

    setState(() => isLoading = false);

    if (result['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Barang berhasil diperbarui'
                : 'Barang berhasil ditambahkan',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menyimpan data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Barang' : 'Tambah Barang Baru'),
        elevation: 0,
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
                    // Header Informasi
                    Text(
                      isEdit ? 'Perbarui Data Barang' : 'Data Barang Baru',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Fields dengan desain lebih modern
                    _buildTextField(
                      _namaPartCtrl,
                      'Nama Part',
                      Icons.inventory_2_outlined,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      _modelCtrl,
                      'Model',
                      Icons.category_outlined,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      _merkCtrl,
                      'Merk',
                      Icons.branding_watermark_outlined,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _jumlahBaruCtrl,
                            'Jumlah Baru',
                            Icons.add_circle_outline,
                            isRequired: true,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            _jumlahBekasCtrl,
                            'Jumlah Bekas',
                            Icons.remove_circle_outline,
                            isRequired: true,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      _supplierCtrl,
                      'Supplier',
                      Icons.business_outlined,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      _patokanHargaCtrl,
                      'Patokan Harga (Rp)',
                      Icons.attach_money_outlined,
                      isRequired: true,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      _rukNoCtrl,
                      'RUK No',
                      Icons.confirmation_number_outlined,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    // Date Pickers
                    _buildDateField(
                      _purchaseDateCtrl,
                      'Tanggal Purchase',
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 16),

                    _buildDateField(
                      _deliveryDateCtrl,
                      'Tanggal Delivery',
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          isEdit ? 'Simpan Perubahan' : 'Tambah Barang',
                          style: const TextStyle(
                            fontSize: 16,
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

  // Widget reusable untuk TextField dengan icon
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: isRequired
          ? (v) => (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null
          : null,
    );
  }

  // Widget reusable untuk Date Picker Field
  Widget _buildDateField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '$label *',
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      readOnly: true,
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
      validator: (v) => (v == null || v.isEmpty) ? '$label wajib diisi' : null,
    );
  }

  @override
  void dispose() {
    _namaPartCtrl.dispose();
    _modelCtrl.dispose();
    _merkCtrl.dispose();
    _jumlahBaruCtrl.dispose();
    _jumlahBekasCtrl.dispose();
    _supplierCtrl.dispose();
    _patokanHargaCtrl.dispose();
    _rukNoCtrl.dispose();
    _purchaseDateCtrl.dispose();
    _deliveryDateCtrl.dispose();
    super.dispose();
  }
}
