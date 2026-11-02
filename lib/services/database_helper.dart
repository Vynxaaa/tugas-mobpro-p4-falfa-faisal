import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';

/// Helper class untuk mengelola Database SQFlite
/// Menggunakan pola Singleton agar koneksi database hanya dibuat satu kali.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Nama Database dan Versi
  static const String _dbName = 'notes_app.db';
  static const int _dbVersion = 1;

  // Nama Tabel dan Kolom
  static const String tableNotes = 'notes';
  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colContent = 'content';
  static const String colCategory = 'category';
  static const String colPriority = 'priority';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';

  /// Getter untuk instance database (Lazy Initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  /// Inisialisasi Database dan membuka koneksi
  Future<Database> _initDB(String filePath) async {
    // Mendapatkan path direktori database spesifik platform
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Membuka database, memicu onCreate jika belum ada
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgradeDB,
    );
  }

  /// Membuat skema tabel SQLite
  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL DEFAULT 1';

    await db.execute('''
      CREATE TABLE $tableNotes (
        $colId $idType,
        $colTitle $textType,
        $colContent $textType,
        $colCategory $textType,
        $colPriority $intType,
        $colCreatedAt $textType,
        $colUpdatedAt $textNullable
      )
    ''');
  }

  /// Handler untuk pembaruan versi skema database (migration)
  Future<void> _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      // Migrasi skema dapat ditambahkan di sini saat ada kenaikan versi
    }
  }

  // ==========================================
  // OPERASI CRUD (Create, Read, Update, Delete)
  // ==========================================

  /// 1. CREATE: Menambahkan catatan baru ke tabel
  Future<int> insertNote(Note note) async {
    final db = await database;
    // Menggunakan db.insert() dengan parameter conflictAlgorithm
    return await db.insert(
      tableNotes,
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 2. READ: Mengambil seluruh data catatan (diurutkan berdasarkan id DESC)
  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final result = await db.query(
      tableNotes,
      orderBy: '$colId DESC',
    );
    return result.map((json) => Note.fromMap(json)).toList();
  }

  /// 2. READ: Mengambil satu catatan berdasarkan ID
  Future<Note?> getNoteById(int id) async {
    final db = await database;
    final maps = await db.query(
      tableNotes,
      where: '$colId = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }

  /// 2. READ: Mencari catatan berdasarkan kata kunci pada judul atau isi
  Future<List<Note>> searchNotes(String query) async {
    final db = await database;
    final result = await db.query(
      tableNotes,
      where: '$colTitle LIKE ? OR $colContent LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: '$colId DESC',
    );
    return result.map((json) => Note.fromMap(json)).toList();
  }

  /// 3. UPDATE: Memperbarui data catatan yang sudah ada
  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update(
      tableNotes,
      note.toMap(),
      where: '$colId = ?',
      whereArgs: [note.id],
    );
  }

  /// 4. DELETE: Menghapus catatan berdasarkan ID
  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      tableNotes,
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  /// 4. DELETE: Menghapus seluruh data dalam tabel
  Future<int> deleteAllNotes() async {
    final db = await database;
    return await db.delete(tableNotes);
  }

  /// Mendapatkan total jumlah catatan
  Future<int> getNotesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $tableNotes');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Menutup koneksi database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

