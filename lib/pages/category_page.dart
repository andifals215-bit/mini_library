import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/category_model.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<CategoryModel> _categories = [];
  Map<int, int> _categoryBookCounts = {};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final query = _searchController.text.trim();
      final list = await DatabaseHelper.instance.getCategories(
        searchQuery: query.isNotEmpty ? query : null,
      );

      final Map<int, int> counts = {};
      for (var cat in list) {
        if (cat.idKategori != null) {
          counts[cat.idKategori!] = await DatabaseHelper.instance.getCategoryBookCount(cat.idKategori!);
        }
      }

      if (mounted) {
        setState(() {
          _categories = list;
          _categoryBookCounts = counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCategoryFormDialog({CategoryModel? category}) {
    final isEdit = category != null;
    final nameController = TextEditingController(text: isEdit ? category.namaKategori : '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori Baru'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nama Kategori',
                hintText: 'Misal: Sains, Fiksi, Komik',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama kategori tidak boleh kosong';
                }
                return null;
              },
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
                  final nama = nameController.text.trim();
                  if (isEdit) {
                    final updatedCat = CategoryModel(
                      idKategori: category.idKategori,
                      namaKategori: nama,
                    );
                    await DatabaseHelper.instance.updateCategory(updatedCat);
                  } else {
                    final newCat = CategoryModel(namaKategori: nama);
                    await DatabaseHelper.instance.insertCategory(newCat);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit
                              ? 'Kategori berhasil diperbarui'
                              : 'Kategori berhasil ditambahkan',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadCategories();
                  }
                }
              },
              child: Text(isEdit ? 'Simpan' : 'Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteCategory(CategoryModel category) async {
    final bookCount = _categoryBookCounts[category.idKategori] ?? 0;

    if (bookCount > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tidak Bisa Dihapus'),
          content: Text(
            'Kategori "${category.namaKategori}" masih digunakan oleh $bookCount buku. Ubah kategori buku terlebih dahulu sebelum menghapus.',
          ),
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
        title: const Text('Hapus Kategori?'),
        content: Text('Apakah Anda yakin ingin menghapus kategori "${category.namaKategori}"?'),
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
              try {
                await DatabaseHelper.instance.deleteCategory(category.idKategori!);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kategori berhasil dihapus'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  _loadCategories();
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
          'Kelola Kategori',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              onChanged: (_) => _loadCategories(),
              decoration: InputDecoration(
                hintText: 'Cari nama kategori...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _loadCategories();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Category List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _categories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'Belum ada kategori'
                                    : 'Kategori tidak ditemukan',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCategories,
                          child: ListView.builder(
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              final count = _categoryBookCounts[cat.idKategori] ?? 0;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 1,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    child: Icon(
                                      Icons.folder_open_rounded,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  title: Text(
                                    cat.namaKategori,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$count buku terdaftar',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                                        tooltip: 'Edit Kategori',
                                        onPressed: () => _showCategoryFormDialog(category: cat),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                        tooltip: 'Hapus Kategori',
                                        onPressed: () => _confirmDeleteCategory(cat),
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
        onPressed: () => _showCategoryFormDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Kategori'),
      ),
    );
  }
}
