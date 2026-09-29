CREATE DATABASE IF NOT EXISTS mini_library
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE mini_library;

CREATE TABLE IF NOT EXISTS kategori (
  id_kategori INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nama_kategori VARCHAR(100) NOT NULL,
  PRIMARY KEY (id_kategori)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS buku (
  id_buku INT UNSIGNED NOT NULL AUTO_INCREMENT,
  judul VARCHAR(200) NOT NULL,
  penulis VARCHAR(150) NOT NULL,
  tahun_terbit YEAR NOT NULL,
  id_kategori INT UNSIGNED NOT NULL,
  status ENUM('Tersedia', 'Dipinjam') NOT NULL DEFAULT 'Tersedia',
  PRIMARY KEY (id_buku),
  KEY idx_buku_id_kategori (id_kategori),
  CONSTRAINT fk_buku_kategori
    FOREIGN KEY (id_kategori) REFERENCES kategori (id_kategori)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS peminjaman (
  id_peminjaman INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_buku INT UNSIGNED NOT NULL,
  nama_peminjam VARCHAR(150) NOT NULL,
  tanggal_pinjam DATE NOT NULL,
  tanggal_kembali DATE DEFAULT NULL,
  status ENUM('Dipinjam', 'Dikembalikan') NOT NULL DEFAULT 'Dipinjam',
  PRIMARY KEY (id_peminjaman),
  KEY idx_peminjaman_id_buku (id_buku),
  CONSTRAINT fk_peminjaman_buku
    FOREIGN KEY (id_buku) REFERENCES buku (id_buku)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

INSERT INTO kategori (nama_kategori) VALUES
  ('Fiksi'),
  ('Teknologi'),
  ('Pendidikan'),
  ('Sejarah');

INSERT INTO buku (judul, penulis, tahun_terbit, id_kategori, status) VALUES
  ('Laskar Pelangi', 'Andrea Hirata', 2005, 1, 'Tersedia'),
  ('Bumi Manusia', 'Pramoedya Ananta Toer', 1980, 1, 'Tersedia'),
  ('Belajar Basis Data', 'Fathansyah', 2015, 3, 'Tersedia'),
  ('Sejarah Indonesia Modern', 'M.C. Ricklefs', 2008, 4, 'Tersedia');