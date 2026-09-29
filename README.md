# 📚 Mini Library (Aplikasi Perpustakaan Mobile & Desktop)

Aplikasi Perpustakaan berbasis **Flutter** dan **SQLite** yang dirancang dengan arsitektur bersih (*Clean MVC Pattern*) untuk kemudahan pengembangan dan presentasi akademik.

---

## 📂 Struktur Projek (Clean MVC Architecture)

Struktur kode diatur dengan rapi di dalam folder `lib/` agar mudah dipahami dan dijelaskan:

```text
mini_library/
├── database/
│   └── mini_library.sql        # Skema basis data SQL (Tabel & Seed Data)
├── lib/
│   ├── main.dart               # Entry point aplikasi & konfigurasi tema Material 3
│   ├── helpers/
│   │   └── database_helper.dart # Helper SQLite / FFI (CRUD DB, Transaction, & Seeding)
│   ├── models/
│   │   ├── book_model.dart     # Model data Buku
│   │   ├── category_model.dart # Model data Kategori
│   │   └── borrow_model.dart   # Model data Peminjaman
│   └── pages/
│       ├── dashboard_page.dart # Halaman Utama / Statistik Realtime
│       ├── book_page.dart      # Halaman Catalog & CRUD Buku
│       ├── category_page.dart  # Halaman Manajemen Kategori
│       └── borrow_page.dart    # Halaman Transaksi Peminjaman & Pengembalian
├── pubspec.yaml                # Konfigurasi dependensi Flutter
└── README.md                   # Dokumentasi projek
```

---

## 🌟 Fitur Utama Aplikasi

1. **Dashboard Statistik Realtime**
   - Menampilkan total buku, jumlah buku yang tersedia, jumlah buku yang sedang dipinjam, dan total kategori.
   - Ringkasan transaksi peminjaman terbaru.

2. **Manajemen Kategori Buku (CRUD Kategori)**
   - Daftar kategori beserta jumlah buku di setiap kategori.
   - Tambah, Edit, Pencarian, dan Hapus kategori (dilengkapi proteksi validasi jika kategori masih terikat dengan buku).

3. **Manajemen Catalog Buku (CRUD Buku)**
   - Katalog buku dengan judul, penulis, tahun terbit, badge kategori, dan status (*Tersedia* / *Dipinjam*).
   - Filter kategori dan pencarian cepat.
   - Validasi hapus buku (buku dipinjam tidak dapat dihapus).

4. **Sistem Peminjaman & Pengembalian Buku**
   - **Peminjaman Aktif**: Peminjam, judul buku, dan tanggal pinjam.
   - **Pengembalian Buku (1-Click)**: Sekali klik *Kembalikan*, sistem mencatat tanggal kembali dan mengubah status buku menjadi *Tersedia*.

---

## 🗄️ Skema Database SQLite

Database lokal SQLite diinisialisasi secara otomatis oleh `DatabaseHelper` dengan tabel-tabel berikut:

- **Tabel `kategori`**: `id_kategori` (PK), `nama_kategori`
- **Tabel `buku`**: `id_buku` (PK), `judul`, `penulis`, `tahun_terbit`, `id_kategori` (FK), `status`
- **Tabel `peminjaman`**: `id_peminjaman` (PK), `id_buku` (FK), `nama_peminjam`, `tanggal_pinjam`, `tanggal_kembali`, `status`

---

## 🚀 Cara Menjalankan Aplikasi

1. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

2. **Jalankan Aplikasi:**
   - **Windows Desktop:**
     ```bash
     flutter run -d windows
     ```
   - **Android Emulator / Device:**
     ```bash
     flutter run
     ```
