import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_item.dart';

/// Service untuk mengelola Hive sebagai alternatif teknologi Local Storage NoSQL
class HiveService {
  static final HiveService instance = HiveService._init();
  HiveService._init();

  static const String boxName = 'tasks_box';
  Box? _box;

  /// Inisialisasi Hive (dipanggil di main.dart)
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(boxName);
  }

  /// Mendapatkan box yang sudah terbuka
  Box get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('Hive box "$boxName" belum diinisialisasi atau ditutup.');
    }
    return _box!;
  }

  // ==========================================
  // OPERASI CRUD PADA HIVE (NoSQL Key-Value)
  // ==========================================

  /// 1. CREATE: Menambahkan task ke Hive Box menggunakan key id
  Future<void> addTask(TaskItem task) async {
    await box.put(task.id, task.toMap());
  }

  /// 2. READ: Mengambil seluruh data task dari Box
  List<TaskItem> getAllTasks() {
    final List<TaskItem> tasks = [];
    for (var i = 0; i < box.length; i++) {
      final value = box.getAt(i);
      if (value != null && value is Map) {
        tasks.add(TaskItem.fromMap(value));
      }
    }
    // Urutkan berdasarkan waktu pembuatan terbaru
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  /// 2. READ: Mengambil satu item berdasarkan ID (O(1) direct lookup)
  TaskItem? getTaskById(String id) {
    final value = box.get(id);
    if (value != null && value is Map) {
      return TaskItem.fromMap(value);
    }
    return null;
  }

  /// 3. UPDATE: Memperbarui data task
  Future<void> updateTask(TaskItem task) async {
    await box.put(task.id, task.toMap());
  }

  /// 3. UPDATE: Toggle status penyelesaian (isCompleted)
  Future<void> toggleTaskStatus(String id) async {
    final task = getTaskById(id);
    if (task != null) {
      final updated = task.copyWith(isCompleted: !task.isCompleted);
      await box.put(id, updated.toMap());
    }
  }

  /// 4. DELETE: Menghapus task berdasarkan key id
  Future<void> deleteTask(String id) async {
    await box.delete(id);
  }

  /// 4. DELETE: Menghapus seluruh data dalam box
  Future<void> clearAllTasks() async {
    await box.clear();
  }

  /// Total item
  int get taskCount => box.length;
}

