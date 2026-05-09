class Alat {
  final String hashid;
  final String namaAlat;
  final String? kelas;
  final String merk;
  final String? tipe;
  final String? noSeri;
  final String? noIdentitas;
  final String? kapasitas;
  final String? dayaBaca;
  final int jumlah;
  final String? noSertifikat;
  final String? masaBerlaku;
  final String? status;
  final String? fotoUrl;
  final String? fotoThumb;
  final String? qrCodeUrl;
  final Kategori? kategori;
  final List<Kalibrasi>? kalibrasis;

  Alat({
    required this.hashid,
    required this.namaAlat,
    this.kelas,
    required this.merk,
    this.tipe,
    this.noSeri,
    this.noIdentitas,
    this.kapasitas,
    this.dayaBaca,
    required this.jumlah,
    this.noSertifikat,
    this.masaBerlaku,
    this.status,
    this.fotoUrl,
    this.fotoThumb,
    this.qrCodeUrl,
    this.kategori,
    this.kalibrasis,
  });

  factory Alat.fromJson(Map<String, dynamic> json) {
    return Alat(
      hashid: json['hashid'] ?? '',
      namaAlat: json['nama_alat'] ?? '',
      kelas: json['kelas'],
      merk: json['merk'] ?? '',
      tipe: json['tipe'],
      noSeri: json['no_seri'],
      noIdentitas: json['no_identitas'],
      kapasitas: json['kapasitas'],
      dayaBaca: json['daya_baca'],
      jumlah: json['jumlah'] ?? 0,
      noSertifikat: json['no_sertifikat'],
      masaBerlaku: json['masa_berlaku'],
      status: json['status'],
      fotoUrl: json['foto_url'],
      fotoThumb: json['foto_thumb'],
      qrCodeUrl: json['qr_code_url'],
      kategori: json['kategori'] != null
          ? Kategori.fromJson(json['kategori'])
          : null,
      kalibrasis: json['kalibrasis'] != null
          ? (json['kalibrasis'] as List)
                .map((e) => Kalibrasi.fromJson(e))
                .toList()
          : null,
    );
  }
}

class Kalibrasi {
  final String hashid;
  final int alatId;
  final String? tanggalKalibrasi;
  final String? masaBerlakuBaru;
  final String? noSertifikat;
  final String? keterangan;

  Kalibrasi({
    required this.hashid,
    required this.alatId,
    this.tanggalKalibrasi,
    this.masaBerlakuBaru,
    this.noSertifikat,
    this.keterangan,
  });

  factory Kalibrasi.fromJson(Map<String, dynamic> json) {
    return Kalibrasi(
      hashid: json['hashid'] ?? '',
      alatId: json['alat_id'] ?? 0,
      tanggalKalibrasi: json['tanggal_kalibrasi'],
      masaBerlakuBaru: json['masa_berlaku_baru'],
      noSertifikat: json['no_sertifikat'],
      keterangan: json['keterangan'],
    );
  }
}

class Kategori {
  final String hashid;
  final String nama;
  final String? keterangan;

  Kategori({required this.hashid, required this.nama, this.keterangan});

  factory Kategori.fromJson(Map<String, dynamic> json) {
    return Kategori(
      hashid: json['hashid'] ?? '',
      nama: json['nama'] ?? '',
      keterangan: json['keterangan'],
    );
  }
}

class PengambilanAlat {
  final String hashid;
  final int userId;
  final int bagianId;
  final String? namaPeminjam;
  final int alatId;
  final int jumlah;
  final String satuan;
  final String keperluan;
  final String? waktuPengambilan;
  final String? status;
  final String? fotoUrl;
  final String? fotoThumb;
  final Alat? alat;
  final List<PengembalianAlat>? pengembalians;

  PengambilanAlat({
    required this.hashid,
    required this.userId,
    required this.bagianId,
    this.namaPeminjam,
    required this.alatId,
    required this.jumlah,
    required this.satuan,
    required this.keperluan,
    this.waktuPengambilan,
    this.status,
    this.fotoUrl,
    this.fotoThumb,
    this.alat,
    this.pengembalians,
  });

  factory PengambilanAlat.fromJson(Map<String, dynamic> json) {
    return PengambilanAlat(
      hashid: json['hashid'] ?? '',
      userId: json['user_id'] ?? 0,
      bagianId: json['bagian_id'] ?? 0,
      namaPeminjam: json['nama_peminjam'],
      alatId: json['alat_id'] ?? 0,
      jumlah: json['jumlah'] ?? 0,
      satuan: json['satuan'] ?? '',
      keperluan: json['keperluan'] ?? '',
      waktuPengambilan: json['waktu_pengambilan'],
      status: json['status'],
      fotoUrl: json['foto_url'],
      fotoThumb: json['foto_thumb'],
      alat: json['alat'] != null ? Alat.fromJson(json['alat']) : null,
      pengembalians: json['pengembalians'] != null
          ? (json['pengembalians'] as List)
                .map((e) => PengembalianAlat.fromJson(e))
                .toList()
          : null,
    );
  }
}

class PengembalianAlat {
  final String hashid;
  final int pengambilanAlatId;
  final int userId;
  final String? namaPeminjam;
  final int jumlah;
  final String? tanggalPengembalian;
  final String? keterangan;
  final String? fotoUrl;
  final String? fotoThumb;
  final PengambilanAlat? pengambilan;

  PengembalianAlat({
    required this.hashid,
    required this.pengambilanAlatId,
    required this.userId,
    this.namaPeminjam,
    required this.jumlah,
    this.tanggalPengembalian,
    this.keterangan,
    this.fotoUrl,
    this.fotoThumb,
    this.pengambilan,
  });

  factory PengembalianAlat.fromJson(Map<String, dynamic> json) {
    return PengembalianAlat(
      hashid: json['hashid'] ?? '',
      pengambilanAlatId: json['pengambilan_alat_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      namaPeminjam: json['nama_peminjam'],
      jumlah: json['jumlah'] ?? 0,
      tanggalPengembalian: json['tanggal_pengembalian'],
      keterangan: json['keterangan'],
      fotoUrl: json['foto_url'],
      fotoThumb: json['foto_thumb'],
      pengambilan: json['pengambilan'] != null
          ? PengambilanAlat.fromJson(json['pengambilan'])
          : null,
    );
  }
}
