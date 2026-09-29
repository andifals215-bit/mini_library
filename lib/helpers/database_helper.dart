import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/category_model.dart';
import '../models/book_model.dart';
import '../models/borrow_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mini_library.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Create table kategori
    await db.execute('''
      CREATE TABLE kategori (
        id_kategori INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_kategori TEXT NOT NULL
      )
    ''');

    // 2. Create table buku
    await db.execute('''
      CREATE TABLE buku (
        id_buku INTEGER PRIMARY KEY AUTOINCREMENT,
        judul TEXT NOT NULL,
        penulis TEXT NOT NULL,
        tahun_terbit INTEGER NOT NULL,
        id_kategori INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'Tersedia',
        FOREIGN KEY (id_kategori) REFERENCES kategori (id_kategori) ON DELETE RESTRICT
      )
    ''');

    // 3. Create table peminjaman
    await db.execute('''
      CREATE TABLE peminjaman (
        id_peminjaman INTEGER PRIMARY KEY AUTOINCREMENT,
        id_buku INTEGER NOT NULL,
        nama_peminjam TEXT NOT NULL,
        tanggal_pinjam TEXT NOT NULL,
        tanggal_kembali TEXT,
        status TEXT NOT NULL DEFAULT 'Dipinjam',
        FOREIGN KEY (id_buku) REFERENCES buku (id_buku) ON DELETE RESTRICT
      )
    ''');

    // Seed Data according to mini_library.sql
    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // Seed Categories
    await db.rawInsert("INSERT INTO kategori (nama_kategori) VALUES ('Fiksi')");
    await db.rawInsert("INSERT INTO kategori (nama_kategori) VALUES ('Teknologi')");
    await db.rawInsert("INSERT INTO kategori (nama_kategori) VALUES ('Pendidikan')");
    await db.rawInsert("INSERT INTO kategori (nama_kategori) VALUES ('Sejarah')");

    // Seed Books
    await db.rawInsert(
      "INSERT INTO buku (judul, penulis, tahun_terbit, id_kategori, status) VALUES ('Laskar Pelangi', 'Andrea Hirata', 2005, 1, 'Tersedia')"
    );
    await db.rawInsert(
      "INSERT INTO buku (judul, penulis, tahun_terbit, id_kategori, status) VALUES ('Bumi Manusia', 'Pramoedya Ananta Toer', 1980, 1, 'Tersedia')"
    );
    await db.rawInsert(
      "INSERT INTO buku (judul, penulis, tahun_terbit, id_kategori, status) VALUES ('Belajar Basis Data', 'Fathansyah', 2015, 3, 'Tersedia')"
    );
    await db.rawInsert(
      "INSERT INTO buku (judul, penulis, tahun_terbit, id_kategori, status) VALUES ('Sejarah Indonesia Modern', 'M.C. Ricklefs', 2008, 4, 'Tersedia')"
    );
  }

  // ================= KATEGORI CRUD =================

  Future<List<CategoryModel>> getCategories({String? searchQuery}) async {
    final db = await instance.database;
    String sql = 'SELECT * FROM kategori';
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      sql += ' WHERE nama_kategori LIKE ?';
      whereArgs.add('%$searchQuery%');
    }
    sql += ' ORDER BY nama_kategori ASC';

    final result = await db.rawQuery(sql, whereArgs);
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<int> insertCategory(CategoryModel category) async {
    final db = await instance.database;
    return await db.insert('kategori', category.toMap());
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await instance.database;
    return await db.update(
      'kategori',
      category.toMap(),
      where: 'id_kategori = ?',
      whereArgs: [category.idKategori],
    );
  }

  Future<int> getCategoryBookCount(int categoryId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM buku WHERE id_kategori = ?',
      [categoryId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    // Check if any books are associated with this category
    final bookCount = await getCategoryBookCount(id);
    if (bookCount > 0) {
      throw Exception('Kategori ini masih digunakan oleh $bookCount buku.');
    }
    return await db.delete(
      'kategori',
      where: 'id_kategori = ?',
      whereArgs: [id],
    );
  }

  // ================= BUKU CRUD =================

  Future<List<BookModel>> getBooks({String? searchQuery, int? categoryId}) async {
    final db = await instance.database;
    String sql = '''
      SELECT b.*, k.nama_kategori 
      FROM buku b
      LEFT JOIN kategori k ON b.id_kategori = k.id_kategori
    ''';

    List<String> conditions = [];
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      conditions.add('(b.judul LIKE ? OR b.penulis LIKE ?)');
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    if (categoryId != null && categoryId > 0) {
      conditions.add('b.id_kategori = ?');
      whereArgs.add(categoryId);
    }

    if (conditions.isNotEmpty) {
      sql += ' WHERE ' + conditions.join(' AND ');
    }

    sql += ' ORDER BY b.id_buku DESC';

    final result = await db.rawQuery(sql, whereArgs);
    return result.map((json) => BookModel.fromMap(json)).toList();
  }

  Future<int> insertBook(BookModel book) async {
    final db = await instance.database;
    return await db.insert('buku', book.toMap());
  }

  Future<int> updateBook(BookModel book) async {
    final db = await instance.database;
    return await db.update(
      'buku',
      book.toMap(),
      where: 'id_buku = ?',
      whereArgs: [book.idBuku],
    );
  }

  Future<int> deleteBook(int id) async {
    final db = await instance.database;
    // Check if book is currently borrowed
    final activeBorrows = await db.rawQuery(
      "SELECT COUNT(*) as count FROM peminjaman WHERE id_buku = ? AND status = 'Dipinjam'",
      [id],
    );
    final count = Sqflite.firstIntValue(activeBorrows) ?? 0;
    if (count > 0) {
      throw Exception('Buku sedang dipinjam dan tidak bisa dihapus.');
    }
    return await db.delete(
      'buku',
      where: 'id_buku = ?',
      whereArgs: [id],
    );
  }

  // ================= PEMINJAMAN CRUD =================

  Future<List<BorrowModel>> getBorrows({String? status, String? searchQuery}) async {
    final db = await instance.database;
    String sql = '''
      SELECT p.*, b.judul as judul_buku 
      FROM peminjaman p
      JOIN buku b ON p.id_buku = b.id_buku
    ''';

    List<String> conditions = [];
    List<dynamic> whereArgs = [];

    if (status != null && status.isNotEmpty) {
      conditions.add('p.status = ?');
      whereArgs.add(status);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      conditions.add('(p.nama_peminjam LIKE ? OR b.judul LIKE ?)');
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    if (conditions.isNotEmpty) {
      sql += ' WHERE ' + conditions.join(' AND ');
    }

    sql += ' ORDER BY p.id_peminjaman DESC';

    final result = await db.rawQuery(sql, whereArgs);
    return result.map((json) => BorrowModel.fromMap(json)).toList();
  }

  Future<int> insertBorrow(BorrowModel borrow) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      // 1. Insert borrow record
      final id = await txn.insert('peminjaman', borrow.toMap());

      // 2. Update book status to 'Dipinjam'
      await txn.update(
        'buku',
        {'status': 'Dipinjam'},
        where: 'id_buku = ?',
        whereArgs: [borrow.idBuku],
      );

      return id;
    });
  }

  Future<void> returnBook(int idPeminjaman, int idBuku, String tanggalKembali) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // 1. Update borrow status to 'Dikembalikan'
      await txn.update(
        'peminjaman',
        {
          'status': 'Dikembalikan',
          'tanggal_kembali': tanggalKembali,
        },
        where: 'id_peminjaman = ?',
        whereArgs: [idPeminjaman],
      );

      // 2. Update book status to 'Tersedia'
      await txn.update(
        'buku',
        {'status': 'Tersedia'},
        where: 'id_buku = ?',
        whereArgs: [idBuku],
      );
    });
  }

  // ================= DASHBOARD STATS =================

  Future<Map<String, int>> getDashboardStats() async {
    final db = await instance.database;

    final totalBooksRes = await db.rawQuery('SELECT COUNT(*) as count FROM buku');
    final availableBooksRes = await db.rawQuery("SELECT COUNT(*) as count FROM buku WHERE status = 'Tersedia'");
    final borrowedBooksRes = await db.rawQuery("SELECT COUNT(*) as count FROM buku WHERE status = 'Dipinjam'");
    final totalCategoriesRes = await db.rawQuery('SELECT COUNT(*) as count FROM kategori');

    return {
      'total_buku': Sqflite.firstIntValue(totalBooksRes) ?? 0,
      'buku_tersedia': Sqflite.firstIntValue(availableBooksRes) ?? 0,
      'buku_dipinjam': Sqflite.firstIntValue(borrowedBooksRes) ?? 0,
      'total_kategori': Sqflite.firstIntValue(totalCategoriesRes) ?? 0,
    };
  }
}
