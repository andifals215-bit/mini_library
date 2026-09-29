import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../models/borrow_model.dart';

class BorrowPage extends StatefulWidget {
  const BorrowPage({super.key});

  @override
  State<BorrowPage> createState() => _BorrowPageState();
}

class _BorrowPageState extends State<BorrowPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BorrowModel> _activeBorrows = [];
  List<BorrowModel> _returnedBorrows = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBorrows();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBorrows() async {
    setState(() => _isLoading = true);
    try {
      final query = _searchController.text.trim();
      final active = await DatabaseHelper.instance.getBorrows(
        status: 'Dipinjam',
        searchQuery: query.isNotEmpty ? query : null,
      );
      final returned = await DatabaseHelper.instance.getBorrows(
        status: 'Dikembalikan',
        searchQuery: query.isNotEmpty ? query : null,
      );

      if (mounted) {
        setState(() {
          _activeBorrows = active;
          _returnedBorrows = returned;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddBorrowDialog() async {
    // Fetch available books
    final books = await DatabaseHelper.instance.getBooks();
    final availableBooks = books.where((b) => b.status == 'Tersedia').toList();

    if (!mounted) return;

    if (availableBooks.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Buku Tidak Tersedia'),
          content: const Text(
            'Saat ini tidak ada buku berstatus "Tersedia" untuk dipinjam.',
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

    int? selectedBookId = availableBooks.first.idBuku;
    final borrowerController = TextEditingController();
    DateTime borrowDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Peminjaman'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        value: selectedBookId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Buku',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.book),
                        ),
                        items: availableBooks.map((b) {
                          return DropdownMenuItem<int>(
                            value: b.idBuku,
                            child: Text(
                              '${b.judul} (${b.penulis})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedBookId = val;
                          });
                        },
                        validator: (v) => v == null ? 'Pilih buku yang ingin dipinjam' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: borrowerController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Peminjam',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nama peminjam wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: borrowDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              borrowDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Pinjam',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_month),
                          ),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(borrowDate),
                          ),
                        ),
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
                    if (formKey.currentState!.validate() && selectedBookId != null) {
                      final newBorrow = BorrowModel(
                        idBuku: selectedBookId!,
                        namaPeminjam: borrowerController.text.trim(),
                        tanggalPinjam: DateFormat('yyyy-MM-dd').format(borrowDate),
                        status: 'Dipinjam',
                      );

                      await DatabaseHelper.instance.insertBorrow(newBorrow);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Peminjaman berhasil dicatat'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadBorrows();
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmReturnBook(BorrowModel borrow) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kembalikan Buku?'),
        content: Text(
          'Konfirmasi pengembalian buku "${borrow.judulBuku}" oleh ${borrow.namaPeminjam}.\n\nTanggal Pengembalian: $todayStr',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await DatabaseHelper.instance.returnBook(
                borrow.idPeminjaman!,
                borrow.idBuku,
                todayStr,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Buku "${borrow.judulBuku}" telah dikembalikan'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadBorrows();
              }
            },
            child: const Text('Proses Pengembalian'),
          ),
        ],
      ),
    );
  }

  Widget _buildBorrowList(List<BorrowModel> list, {required bool isHistory}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isHistory ? Icons.history_rounded : Icons.menu_book_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              isHistory
                  ? 'Belum ada riwayat pengembalian'
                  : 'Tidak ada peminjaman aktif saat ini',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBorrows,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final borrow = list[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 1.5,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isHistory ? Colors.green.shade100 : Colors.orange.shade100,
                    child: Icon(
                      isHistory ? Icons.check_circle_rounded : Icons.bookmark_rounded,
                      color: isHistory ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          borrow.judulBuku ?? 'Buku #${borrow.idBuku}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Peminjam: ${borrow.namaPeminjam}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Pinjam: ${borrow.tanggalPinjam}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            if (isHistory && borrow.tanggalKembali != null) ...[
                              const SizedBox(width: 12),
                              const Icon(Icons.event_available, size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Kembali: ${borrow.tanggalKembali}',
                                style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isHistory)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _confirmReturnBook(borrow),
                      icon: const Icon(Icons.keyboard_return_rounded, size: 18),
                      label: const Text('Kembali'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelola Peminjaman',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pending_actions_outlined),
                  const SizedBox(width: 8),
                  Text('Dipinjam (${_activeBorrows.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded),
                  const SizedBox(width: 8),
                  Text('Dikembalikan (${_returnedBorrows.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              onChanged: (_) => _loadBorrows(),
              decoration: InputDecoration(
                hintText: 'Cari peminjam atau judul buku...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _loadBorrows();
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

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBorrowList(_activeBorrows, isHistory: false),
                  _buildBorrowList(_returnedBorrows, isHistory: true),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBorrowDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Pinjam Buku'),
      ),
    );
  }
}
