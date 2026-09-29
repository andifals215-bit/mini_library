import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../models/book_model.dart';
import '../models/category_model.dart';
import '../models/borrow_model.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  List<BookModel> _books = [];
  List<CategoryModel> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final categoriesList = await DatabaseHelper.instance.getCategories();
      await _fetchBooks();

      if (mounted) {
        setState(() {
          _categories = categoriesList;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchBooks() async {
    final query = _searchController.text.trim();
    final list = await DatabaseHelper.instance.getBooks(
      searchQuery: query.isNotEmpty ? query : null,
      categoryId: _selectedCategoryId,
    );

    if (mounted) {
      setState(() {
        _books = list;
        _isLoading = false;
      });
    }
  }

  void _showBookFormDialog({BookModel? book}) {
    final isEdit = book != null;
    final judulController = TextEditingController(text: isEdit ? book.judul : '');
    final penulisController = TextEditingController(text: isEdit ? book.penulis : '');
    final tahunController = TextEditingController(
      text: isEdit ? book.tahunTerbit.toString() : DateTime.now().year.toString(),
    );
    int? selectedCategory = isEdit
        ? book.idKategori
        : (_categories.isNotEmpty ? _categories.first.idKategori : null);

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Buku' : 'Tambah Buku Baru'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: judulController,
                        decoration: const InputDecoration(
                          labelText: 'Judul Buku',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.book_outlined),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Judul wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: penulisController,
                        decoration: const InputDecoration(
                          labelText: 'Penulis',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Penulis wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: tahunController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tahun Terbit',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Tahun wajib diisi';
                          final val = int.tryParse(v.trim());
                          if (val == null || val < 1800 || val > 2100) {
                            return 'Masukkan tahun valid (1800-2100)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: _categories.map((c) {
                          return DropdownMenuItem<int>(
                            value: c.idKategori,
                            child: Text(c.namaKategori),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedCategory = val;
                          });
                        },
                        validator: (v) => v == null ? 'Pilih kategori buku' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate() && selectedCategory != null) {
                      final newBook = BookModel(
                        idBuku: book?.idBuku,
                        judul: judulController.text.trim(),
                        penulis: penulisController.text.trim(),
                        tahunTerbit: int.parse(tahunController.text.trim()),
                        idKategori: selectedCategory!,
                        status: book?.status ?? 'Tersedia',
                      );

                      if (isEdit) {
                        await DatabaseHelper.instance.updateBook(newBook);
                      } else {
                        await DatabaseHelper.instance.insertBook(newBook);
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit ? 'Buku berhasil diperbarui' : 'Buku berhasil ditambahkan',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _fetchBooks();
                      }
                    }
                  },
                  child: Text(isEdit ? 'Simpan' : 'Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showQuickBorrowDialog(BookModel book) {
    final borrowerController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pinjam Buku: ${book.judul}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Penulis: ${book.penulis}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: borrowerController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nama Peminjam',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nama peminjam wajib diisi' : null,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tanggal Pinjam: $todayStr',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final borrow = BorrowModel(
                    idBuku: book.idBuku!,
                    namaPeminjam: borrowerController.text.trim(),
                    tanggalPinjam: todayStr,
                    status: 'Dipinjam',
                  );

                  await DatabaseHelper.instance.insertBorrow(borrow);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Buku "${book.judul}" berhasil dipinjam!'),
                        backgroundColor: Colors.orange.shade800,
                      ),
                    );
                    _fetchBooks();
                  }
                }
              },
              child: const Text('Pinjam Sekarang'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteBook(BookModel book) {
    if (book.status == 'Dipinjam') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tidak Bisa Dihapus'),
          content: Text('Buku "${book.judul}" sedang dalam status DIPINJAM. Kembalikan buku terlebih dahulu.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Buku?'),
        content: Text('Apakah Anda yakin ingin menghapus buku "${book.judul}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await DatabaseHelper.instance.deleteBook(book.idBuku!);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Buku berhasil dihapus'),
                    backgroundColor: Colors.red,
                  ),
                );
                _fetchBooks();
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Buku',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (_) => _fetchBooks(),
              decoration: InputDecoration(
                hintText: 'Cari judul atau penulis...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _fetchBooks();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Filter Kategori Horizontal List
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: const Text('Semua Kategori'),
                      selected: _selectedCategoryId == null,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategoryId = null;
                          });
                          _fetchBooks();
                        }
                      },
                    ),
                  ),
                  ..._categories.map((c) {
                    final isSelected = _selectedCategoryId == c.idKategori;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(c.namaKategori),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryId = selected ? c.idKategori : null;
                          });
                          _fetchBooks();
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Book List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _books.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.book_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'Belum ada buku'
                                    : 'Buku tidak ditemukan',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchBooks,
                          child: ListView.builder(
                            itemCount: _books.length,
                            itemBuilder: (context, index) {
                              final book = _books[index];
                              final isAvailable = book.status == 'Tersedia';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 1.5,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Book Cover Placeholder
                                      Container(
                                        width: 50,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          color: isAvailable
                                              ? Colors.blue.shade100
                                              : Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.menu_book_rounded,
                                            color: isAvailable
                                                ? Colors.blue.shade800
                                                : Colors.orange.shade800,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Book Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              book.judul,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Penulis: ${book.penulis}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade800,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Tahun: ${book.tahunTerbit}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                // Category Tag
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.purple.shade50,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: Colors.purple.shade200,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    book.namaKategori ?? 'Kategori #${book.idKategori}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.purple.shade800,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),

                                                // Status Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isAvailable
                                                        ? Colors.green.shade50
                                                        : Colors.orange.shade50,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: isAvailable
                                                          ? Colors.green.shade300
                                                          : Colors.orange.shade300,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    book.status,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isAvailable
                                                          ? Colors.green.shade800
                                                          : Colors.orange.shade800,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Actions
                                      PopupMenuButton<String>(
                                        onSelected: (val) {
                                          if (val == 'edit') {
                                            _showBookFormDialog(book: book);
                                          } else if (val == 'pinjam') {
                                            _showQuickBorrowDialog(book);
                                          } else if (val == 'delete') {
                                            _confirmDeleteBook(book);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          if (isAvailable)
                                            const PopupMenuItem(
                                              value: 'pinjam',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.bookmark_add_outlined, color: Colors.orange),
                                                  SizedBox(width: 8),
                                                  Text('Pinjam Buku'),
                                                ],
                                              ),
                                            ),
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_rounded, color: Colors.blue),
                                                SizedBox(width: 8),
                                                Text('Edit'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline_rounded, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Hapus'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_categories.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tambahkan kategori terlebih dahulu sebelum menambah buku'),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            _showBookFormDialog();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Buku'),
      ),
    );
  }
}
