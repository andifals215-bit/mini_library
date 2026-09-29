class BorrowModel {
  final int? idPeminjaman;
  final int idBuku;
  final String? judulBuku;
  final String namaPeminjam;
  final String tanggalPinjam;
  final String? tanggalKembali;
  final String status; // 'Dipinjam' or 'Dikembalikan'

  BorrowModel({
    this.idPeminjaman,
    required this.idBuku,
    this.judulBuku,
    required this.namaPeminjam,
    required this.tanggalPinjam,
    this.tanggalKembali,
    this.status = 'Dipinjam',
  });

  factory BorrowModel.fromMap(Map<String, dynamic> map) {
    return BorrowModel(
      idPeminjaman: map['id_peminjaman'] as int?,
      idBuku: map['id_buku'] as int? ?? 0,
      judulBuku: map['judul_buku'] as String? ?? map['judul'] as String?,
      namaPeminjam: map['nama_peminjam'] as String? ?? '',
      tanggalPinjam: map['tanggal_pinjam'] as String? ?? '',
      tanggalKembali: map['tanggal_kembali'] as String?,
      status: map['status'] as String? ?? 'Dipinjam',
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id_buku': idBuku,
      'nama_peminjam': namaPeminjam,
      'tanggal_pinjam': tanggalPinjam,
      'tanggal_kembali': tanggalKembali,
      'status': status,
    };
    if (idPeminjaman != null) {
      map['id_peminjaman'] = idPeminjaman;
    }
    return map;
  }
}
