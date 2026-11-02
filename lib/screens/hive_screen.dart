import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../services/hive_service.dart';

class HiveScreen extends StatefulWidget {
  const HiveScreen({super.key});

  @override
  State<HiveScreen> createState() => _HiveScreenState();
}

class _HiveScreenState extends State<HiveScreen> {
  final HiveService _hiveService = HiveService.instance;
  List<TaskItem> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    setState(() => _isLoading = true);
    final data = _hiveService.getAllTasks();
    setState(() {
      _tasks = data;
      _isLoading = false;
    });
  }

  void _showTaskDialog([TaskItem? task]) {
    final isEditing = task != null;
    final titleController = TextEditingController(text: task?.title ?? '');
    final noteController = TextEditingController(text: task?.note ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Task (Hive NoSQL)' : 'Tambah Task (Hive NoSQL)',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Task / Kegiatan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.check_circle_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan Tambahan (Opsional)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: Icon(isEditing ? Icons.save : Icons.add_task),
                    label: Text(
                      isEditing ? 'Simpan Perubahan' : 'Simpan ke Hive Box',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final note = noteController.text.trim();
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      if (title.isEmpty) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Judul task tidak boleh kosong!')),
                        );
                        return;
                      }

                      final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

                      if (isEditing) {
                        // UPDATE
                        final updated = task.copyWith(
                          title: title,
                          note: note,
                        );
                        await _hiveService.updateTask(updated);
                      } else {
                        // CREATE
                        final newTask = TaskItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: title,
                          note: note,
                          isCompleted: false,
                          createdAt: now,
                        );
                        await _hiveService.addTask(newTask);
                      }

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      if (!mounted) return;
                      _loadTasks();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? 'Task berhasil diubah di Hive Box'
                                : 'Task baru berhasil disimpan ke Hive Box!',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteTask(String id) async {
    await _hiveService.deleteTask(id);
    _loadTasks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task berhasil dihapus dari Hive')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _tasks.where((t) => t.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alternatif Storage: Hive NoSQL'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Hapus Semua Data Hive',
            icon: const Icon(Icons.delete_sweep),
            onPressed: _tasks.isEmpty
                ? null
                : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Reset Hive Box'),
                        content: const Text('Hapus SEMUA data pada Hive Box?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _hiveService.clearAllTasks();
                      _loadTasks();
                    }
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Info Hive
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.teal.shade50,
            child: Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hive NoSQL Box: Key-Value cepat murni Dart\nSelesai: $completedCount / ${_tasks.length} task',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.teal, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Task List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada data di Hive Box.\nTekan tombol (+) untuk menambahkan task baru.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _tasks.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final task = _tasks[index];
                          return Card(
                            elevation: 1.5,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: task.isCompleted ? Colors.teal.shade200 : Colors.grey.shade300,
                              ),
                            ),
                            child: ListTile(
                              leading: Checkbox(
                                activeColor: Colors.teal,
                                value: task.isCompleted,
                                onChanged: (val) async {
                                  await _hiveService.toggleTaskStatus(task.id);
                                  _loadTasks();
                                },
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  color: task.isCompleted ? Colors.grey : Colors.black87,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (task.note.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      task.note,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    'Dibuat: ${task.createdAt}',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                    onPressed: () => _showTaskDialog(task),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _deleteTask(task.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task),
        label: const Text('Tambah Task'),
      ),
    );
  }
}

