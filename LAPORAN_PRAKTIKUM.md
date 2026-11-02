# LAPORAN PRAKTIKUM PEMROGRAMAN MOBILE
## MODUL 4: LOCAL STORAGE (SQFlite & TEKNOLOGI ALTERNATIF)
**Laboratorium Ilmu Komputer — Universitas Pakuan**

---

### IDENTITAS MAHASISWA & TUGAS
- **Mata Kuliah:** Pemrograman Mobile (Mobpro)
- **Modul Praktikum:** Praktikum 4 (P4) – Local Storage
- **Topik:** Implementasi CRUD Database SQLite dengan `sqflite` & Eksplorasi Alternatif Local Storage (`Hive`)

---

## 1. DASAR TEORI PACKAGE SQFLITE DI FLUTTER

### 1.1 Apa itu SQFlite?
`sqflite` adalah plugin resmi dan standar industri untuk Flutter yang menyediakan akses ke database relasional **SQLite** pada platform Android, iOS, dan macOS.

SQLite adalah mesin database berbasis file (serverless, zero-configuration) yang tertanam langsung di dalam sistem operasi mobile. Dengan SQFlite, aplikasi Flutter dapat menyimpan data terstruktur dalam jumlah besar secara persisten tanpa bergantung pada jaringan internet (offline-first).

### 1.2 Karakteristik Utama SQFlite
1. **Relasional (RDBMS):** Menggunakan tabel, baris, dan kolom dengan skema yang terdefinisi ketat.
2. **ACID Compliant:** Mendukung transaksi atomik (Atomicity, Consistency, Isolation, Durability) sehingga integritas data terjamin jika aplikasi tiba-tiba ditutup atau crash.
3. **Query SQL Lengkap:** Mendukung query SQL standar seperti `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `JOIN`, `WHERE`, `ORDER BY`, serta `GROUP BY`.
4. **Asinkron (Non-Blocking):** Seluruh pemanggilan database berjalan secara asinkron menggunakan Dart `Future` melalui background thread, mencegah UI freeze (jank).

### 1.3 Alur Kerja Penggunaan SQFlite
```
[Flutter UI / State]
        │
        ▼ (panggilan async method)
[DatabaseHelper (Singleton)]
        │
        ▼ (konversi Model <-> Map)
[sqflite Plugin (Platform Channel)]
        │
        ▼ (C / Native OS SQLite API)
[File Database: .db di Local Storage]
```

---

## 2. PEMBUATAN DATABASE DAN SKEMA TABEL

### 2.1 File Database & Lokasi Penyimpanan
Database diberi nama `notes_app.db` dan disimpan di direktori aman internal aplikasi menggunakan fungsi `getDatabasesPath()` dari paket `sqflite` dan `join()` dari paket `path`.

### 2.2 Skema Tabel `notes`
Tabel dirancang untuk mencatat data catatan / tugas dengan skema berikut:

| Nama Kolom | Tipe Data SQLite | Dart Type | Keterangan |
|---|---|---|---|
| `id` | `INTEGER` | `int?` | Primary Key, Auto Increment |
| `title` | `TEXT` | `String` | Judul catatan (NOT NULL) |
| `content` | `TEXT` | `String` | Isi atau deskripsi catatan (NOT NULL) |
| `category` | `TEXT` | `String` | Kategori (Kuliah, Tugas, Pribadi, dll) |
| `priority` | `INTEGER` | `int` | Level prioritas: 1 (Rendah), 2 (Sedang), 3 (Tinggi) |
| `created_at` | `TEXT` | `String` | Timestamp ISO8601 pembuatan catatan |
| `updated_at` | `TEXT` | `String?` | Timestamp ISO8601 perubahan terakhir |

### 2.3 Perintah DDL (Data Definition Language)
```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT NOT NULL,
  priority INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT
);
```

### 2.4 Model Dart (`lib/models/note.dart`)
SQLite menyimpan data dalam bentuk Map / Baris. Oleh karena itu, dibuat metode serialisasi:
- `toMap()`: Mengonversi objek Dart menjadi `Map<String, dynamic>` untuk disimpan ke tabel.
- `fromMap()`: Mengonversi data baris dari tabel SQLite menjadi instance objek `Note`.

---

## 3. IMPLEMENTASI OPERASI CRUD PADA SQFLITE

Implementasi dibungkus dalam class `DatabaseHelper` dengan pola **Singleton Pattern** agar koneksi database efisien dan tidak dibuka berulang kali.

### 3.1 Inisialisasi Database (Singleton)
```dart
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes_app.db');
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
}
```

### 3.2 Operasi CREATE (Menambahkan Data)
```dart
Future<int> insertNote(Note note) async {
  final db = await database;
  return await db.insert(
    'notes',
    note.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
```
*Penjelasan:* Menggunakan fungsi `db.insert()` yang secara otomatis mengonversi Map atribut menjadi perintah SQL `INSERT INTO`. Mengembalikan ID auto-increment dari baris baru.

### 3.3 Operasi READ (Membaca Data)
1. **Mengambil Seluruh Data (Read All):**
```dart
Future<List<Note>> getAllNotes() async {
  final db = await database;
  final result = await db.query('notes', orderBy: 'id DESC');
  return result.map((json) => Note.fromMap(json)).toList();
}
```
2. **Pencarian Data (Filter Search):**
```dart
Future<List<Note>> searchNotes(String query) async {
  final db = await database;
  final result = await db.query(
    'notes',
    where: 'title LIKE ? OR content LIKE ?',
    whereArgs: ['%$query%', '%$query%'],
    orderBy: 'id DESC',
  );
  return result.map((json) => Note.fromMap(json)).toList();
}
```

### 3.4 Operasi UPDATE (Memperbarui Data)
```dart
Future<int> updateNote(Note note) async {
  final db = await database;
  return await db.update(
    'notes',
    note.toMap(),
    where: 'id = ?',
    whereArgs: [note.id],
  );
}
```
*Penjelasan:* Menggunakan `whereArgs` untuk mencegah serangan SQL Injection secara terparameter.

### 3.5 Operasi DELETE (Menghapus Data)
```dart
Future<int> deleteNote(int id) async {
  final db = await database;
  return await db.delete(
    'notes',
    where: 'id = ?',
    whereArgs: [id],
  );
}
```

---

## 4. EKSPLORASI TEKNOLOGI LOCAL STORAGE ALTERNATIF: HIVE

Sebagai alternatif database relasional SQFlite, dieksplorasi teknologi **Hive** (`hive` dan `hive_flutter`).

### 4.1 Apa itu Hive?
**Hive** adalah database NoSQL bertipe *Key-Value* yang ditulis murni menggunakan bahasa **Dart** (Pure Dart). Hive dirancang khusus untuk Flutter dengan fokus utama pada kecepatan eksekusi, kesederhanaan penggunaan, dan portabilitas lintas platform (Android, iOS, Web, macOS, Windows, Linux).

### 4.2 Arsitektur Hive (Box System)
Hive menyimpan data di dalam wadah yang disebut **Box** (mirip dengan tabel pada SQL atau collection pada MongoDB).
- Seluruh index kunci (*keys*) disimpan di dalam memori (RAM), sehingga pencarian data beroperasi dengan kompleksitas waktu **$O(1)$**.
- Data disimpan dalam format biner yang sangat ringkas di storage fisik.

### 4.3 Implementasi CRUD pada Hive (`lib/services/hive_service.dart`)
1. **Inisialisasi:**
   ```dart
   await Hive.initFlutter();
   var box = await Hive.openBox('tasks_box');
   ```
2. **Create / Update:**
   ```dart
   await box.put(task.id, task.toMap());
   ```
3. **Read:**
   ```dart
   final item = box.get(task.id);
   ```
4. **Delete:**
   ```dart
   await box.delete(task.id);
   ```

---

## 5. RINGKASAN DAN HASIL UJI COBA KOMPARASI

### 5.1 Tabel Perbandingan: SQFlite vs Hive vs SharedPreferences

| Kriteria Evaluasi | SQFlite | Hive (Alternatif) | SharedPreferences |
|---|---|---|---|
| **Kategori / Paradigma** | Relasional (SQL RDBMS) | Dokumen / Key-Value NoSQL | Key-Value Sederhana |
| **Penyimpanan Objek** | Relasional (Baris & Kolom terstruktur) | Biner (Map / Objek via Adapter) | Tipe primitif (int, double, string, bool) |
| **Kecepatan Tulis (Write)** | Cepat (terikat I/O transaksi disk) | **Sangat Cepat** (buffer biner) | Cepat (hanya untuk data kecil) |
| **Kecepatan Baca (Read)** | Cepat (query SQLite) | **Sangat Cepat** ($O(1)$ in-memory index) | Cepat ($O(1)$) |
| **Relasi & JOIN** | **Sangat Baik** (`FOREIGN KEY`, `JOIN`) | Tidak mendukung secara native | Tidak mendukung |
| **Query Kompleks** | **Sangat Kuat** (SQL lengkap, WHERE, GROUP BY, SUM) | Terbatas (Filter via Dart collection) | Tidak ada |
| **Dukungan Platform** | Android, iOS, macOS (Native C) | **Semua Platform** (Android, iOS, Web, Desktop) | Semua Platform |
| **Setup & Boilerplate** | Sedang (Perlu DDL & SQL helper) | **Minimal** (Langsung buka Box) | Sangat Minimal |
| **Kebutuhan Migrasi** | Perlu script `onUpgrade` SQLite | Sangat fleksibel (tambah field default) | Tidak ada migrasi |

### 5.2 Hasil Uji Coba Performa (Benchmark Test 100 Record)
Dalam pengujian aplikasi pada tab *Komparasi*, dilakukan eksekusi 100 operasi tulis dan 100 operasi baca:
- **Hive Write & Read:** Mencatatkan waktu lebih singkat (latensi sangat rendah) karena menggunakan index memori internal dan format biner murni Dart tanpa overhead binding C.
- **SQFlite Write & Read:** Memiliki konsistensi transaksi ACID yang kuat, sangat ideal saat data melibatkan relasi antar tabel (misalnya tabel Mahasiswa dan Nilai Mata Kuliah).

### 5.3 Kesimpulan & Rekomendasi Pemilihan
1. **Pilih SQFlite jika:**
   - Membutuhkan integritas relasi antar data (One-to-Many, Many-to-Many).
   - Membutuhkan query SQL kompleks (agregasi, grouping, sorting kompleks).
   - Volume data sangat besar dan tidak efisien jika di-cache seluruhnya di RAM.
2. **Pilih Hive jika:**
   - Membutuhkan performa baca/tulis tercepat untuk data non-relasional.
   - Menyimpan caching respons REST API, shopping cart offline, atau list data independen.
   - Membutuhkan dukungan multiplatform termasuk Flutter Web dan Desktop.
3. **Pilih SharedPreferences jika:**
   - Hanya menyimpan preferensi sederhana (Theme Dark/Light, Language code, Session Token, Onboarding viewed flag).

---

## 6. CARA MENJALANKAN PROYEK

1. Pastikan Flutter SDK sudah terpasang di sistem.
2. Buka terminal pada direktori proyek:
   ```bash
   cd "mobpro P4"
   ```
3. Unduh seluruh dependensi:
   ```bash
   flutter pub get
   ```
4. Jalankan aplikasi pada emulator atau perangkat fisik:
   ```bash
   flutter run
   ```

