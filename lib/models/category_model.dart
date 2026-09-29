class CategoryModel {
  final int? idKategori;
  final String namaKategori;

  CategoryModel({
    this.idKategori,
    required this.namaKategori,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      idKategori: map['id_kategori'] as int?,
      namaKategori: map['nama_kategori'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nama_kategori': namaKategori,
    };
    if (idKategori != null) {
      map['id_kategori'] = idKategori;
    }
    return map;
  }
}
