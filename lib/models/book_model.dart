class BookModel {
  final int? idBuku;
  final String judul;
  final String penulis;
  final int tahunTerbit;
  final int idKategori;
  final String? namaKategori;
  final String status; // 'Tersedia' or 'Dipinjam'

  BookModel({
    this.idBuku,
    required this.judul,
    required this.penulis,
    required this.tahunTerbit,
    required this.idKategori,
    this.namaKategori,
    this.status = 'Tersedia',
  });

  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      idBuku: map['id_buku'] as int?,
      judul: map['judul'] as String? ?? '',
      penulis: map['penulis'] as String? ?? '',
      tahunTerbit: map['tahun_terbit'] is int
          ? map['tahun_terbit'] as int
          : int.tryParse(map['tahun_terbit'].toString()) ?? 2000,
      idKategori: map['id_kategori'] as int? ?? 0,
      namaKategori: map['nama_kategori'] as String?,
      status: map['status'] as String? ?? 'Tersedia',
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'judul': judul,
      'penulis': penulis,
      'tahun_terbit': tahunTerbit,
      'id_kategori': idKategori,
      'status': status,
    };
    if (idBuku != null) {
      map['id_buku'] = idBuku;
    }
    return map;
  }
}
