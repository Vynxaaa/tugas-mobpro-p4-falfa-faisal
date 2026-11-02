# Praktikum Mobile P4 - Local Storage (SQFlite & Hive)

Proyek ini dibuat untuk memenuhi tugas **Praktikum Pemrograman Mobile - Modul 4 (Local Storage)** Laboratorium Ilmu Komputer, Universitas Pakuan.

## Fitur Aplikasi
1. **SQFlite Database CRUD (`lib/screens/sqflite_screen.dart`):**
   - Inisialisasi SQLite database `notes_app.db` dengan skema tabel `notes`.
   - **Create**: Tambah catatan baru dengan judul, isi, kategori, dan tingkat prioritas.
   - **Read**: Tampilkan daftar catatan terurut ID DESC & fitur pencarian (*search with LIKE query*).
   - **Update**: Edit data catatan secara langsung melalui bottom sheet.
   - **Delete**: Hapus item catatan satuan atau hapus seluruh catatan (*clear all*).
2. **Alternatif Local Storage NoSQL: Hive (`lib/screens/hive_screen.dart`):**
   - Inisialisasi Hive Box `tasks_box`.
   - CRUD data task NoSQL murni berbasis bahasa Dart.
   - Status checklist (toggle complete) instan.
3. **Komparasi & Live Benchmark (`lib/screens/comparison_screen.dart`):**
   - Tombol pengujian live benchmark untuk mengukur waktu baca dan tulis (ms) antara SQFlite vs Hive.
   - Tabel ringkasan komparasi arsitektur, kelebihan, kekurangan, dan panduan pemilihan teknologi.
4. **Dokumentasi Lengkap:**
   - Tersedia di file [`LAPORAN_PRAKTIKUM.md`](LAPORAN_PRAKTIKUM.md).

## Struktur Direktori
```
lib/
├── main.dart                      # Inisialisasi binding, Hive, & Root Widget
├── models/
│   ├── note.dart                  # Model data Catatan untuk SQFlite (toMap & fromMap)
│   └── task_item.dart             # Model data Task untuk Hive Box
├── services/
│   ├── database_helper.dart       # Helper Singleton SQFlite (DDL & CRUD SQL)
│   └── hive_service.dart          # Service Hive Box (CRUD NoSQL)
└── screens/
    ├── home_screen.dart           # Navigasi utama (BottomNavigationBar)
    ├── sqflite_screen.dart        # Tampilan UI CRUD SQFlite
    ├── hive_screen.dart           # Tampilan UI CRUD Hive
    └── comparison_screen.dart     # Tampilan Komparasi & Live Benchmark
```

## Cara Menjalankan
```bash
flutter pub get
flutter run
```

