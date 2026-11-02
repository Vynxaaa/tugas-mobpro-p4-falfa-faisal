/// Model data Item untuk teknologi Local Storage Alternatif (Hive)
class TaskItem {
  final String id;
  final String title;
  final String note;
  final bool isCompleted;
  final String createdAt;

  TaskItem({
    required this.id,
    required this.title,
    required this.note,
    this.isCompleted = false,
    required this.createdAt,
  });

  /// Konversi ke Map (digunakan untuk Hive Box tanpa perlu build_runner)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'isCompleted': isCompleted,
      'createdAt': createdAt,
    };
  }

  /// Konversi dari Map di Hive Box menjadi objek TaskItem
  factory TaskItem.fromMap(Map<dynamic, dynamic> map) {
    return TaskItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      isCompleted: map['isCompleted'] == true,
      createdAt: map['createdAt']?.toString() ?? '',
    );
  }

  TaskItem copyWith({
    String? id,
    String? title,
    String? note,
    bool? isCompleted,
    String? createdAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

