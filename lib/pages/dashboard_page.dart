import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/borrow_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  int _totalBooks = 0;
  int _availableBooks = 0;
  int _borrowedBooks = 0;
  int _totalCategories = 0;
  List<BorrowModel> _recentBorrows = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await DatabaseHelper.instance.getDashboardStats();
      final recent = await DatabaseHelper.instance.getBorrows();

      if (mounted) {
        setState(() {
          _totalBooks = stats['total_buku'] ?? 0;
          _availableBooks = stats['buku_tersedia'] ?? 0;
          _borrowedBooks = stats['buku_dipinjam'] ?? 0;
          _totalCategories = stats['total_kategori'] ?? 0;
          _recentBorrows = recent.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsList = [
      _StatCardData(
        title: 'Total Buku',
        value: '$_totalBooks',
        color: const Color(0xFF2563EB),
        icon: Icons.book_rounded,
        subtitle: 'Koleksi perpustakaan',
      ),
      _StatCardData(
        title: 'Buku Tersedia',
        value: '$_availableBooks',
        color: const Color(0xFF16A34A),
        icon: Icons.check_circle_rounded,
        subtitle: 'Siap dipinjam',
      ),
      _StatCardData(
        title: 'Dipinjam',
        value: '$_borrowedBooks',
        color: const Color(0xFFEA580C),
        icon: Icons.menu_book_rounded,
        subtitle: 'Sedang dipinjam',
      ),
      _StatCardData(
        title: 'Total Kategori',
        value: '$_totalCategories',
        color: const Color(0xFF9333EA),
        icon: Icons.category_rounded,
        subtitle: 'Klasifikasi buku',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perpustakaan Mini',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Data',
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header greeting banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selamat Datang! 👋',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Sistem Manajemen Sistem Perpustakaan Digital',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white24,
                            child: Icon(
                              Icons.local_library_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section Title
                    const Text(
                      'Ringkasan Statistik',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Responsive Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = switch (constraints.maxWidth) {
                          >= 900 => 4,
                          >= 500 => 2,
                          _ => 2,
                        };

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: statsList.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: columns == 4 ? 1.4 : 1.3,
                          ),
                          itemBuilder: (context, index) {
                            final stat = statsList[index];
                            return _StatCardWidget(stat: stat);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Recent Borrowings Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Peminjaman Terbaru',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _loadDashboardData,
                          icon: const Icon(Icons.sync_rounded, size: 16),
                          label: const Text('Update'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_recentBorrows.isEmpty)
                      Card(
                        elevation: 0,
                        color: Colors.grey.shade100,
                        child: const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.inbox_outlined, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'Belum ada transaksi peminjaman',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentBorrows.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final borrow = _recentBorrows[index];
                          final isBorrowed = borrow.status == 'Dipinjam';

                          return Card(
                            elevation: 1,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isBorrowed
                                    ? Colors.orange.shade100
                                    : Colors.green.shade100,
                                child: Icon(
                                  isBorrowed ? Icons.bookmark_added_rounded : Icons.check_rounded,
                                  color: isBorrowed ? Colors.orange.shade800 : Colors.green.shade800,
                                ),
                              ),
                              title: Text(
                                borrow.judulBuku ?? 'Buku #${borrow.idBuku}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Peminjam: ${borrow.namaPeminjam}\nTanggal Pinjam: ${borrow.tanggalPinjam}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              isThreeLine: true,
                              trailing: Chip(
                                padding: EdgeInsets.zero,
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  color: isBorrowed ? Colors.orange.shade900 : Colors.green.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                                backgroundColor: isBorrowed
                                    ? Colors.orange.shade50
                                    : Colors.green.shade50,
                                label: Text(borrow.status),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatCardData {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final String subtitle;

  _StatCardData({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    required this.subtitle,
  });
}

class _StatCardWidget extends StatelessWidget {
  final _StatCardData stat;

  const _StatCardWidget({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: stat.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(stat.icon, color: stat.color, size: 24),
                ),
                Icon(
                  Icons.arrow_upward_rounded,
                  color: stat.color.withValues(alpha: 0.6),
                  size: 18,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: stat.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  stat.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
