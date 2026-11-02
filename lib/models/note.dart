/// Model data Catatan untuk SQFlite
class Note {
  final int? id;
  final String title;
  final String content;
  final String category;
  final int priority; // 1 = Low, 2 = Medium, 3 = High
  final String createdAt;
  final String? updatedAt;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.category,
    this.priority = 1,
    required this.createdAt,
    this.updatedAt,
  });

  /// Mengonversi objek Note menjadi Map<String, dynamic> untuk disimpan ke tabel SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'priority': priority,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Membuat objek Note dari Map/Record hasil query SQLite
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      category: map['category'] as String? ?? 'Umum',
      priority: map['priority'] as int? ?? 1,
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String?,
    );
  }

  /// Salinan objek dengan beberapa atribut yang diperbarui
  Note copyWith({
    int? id,
    String? title,
    String? content,
    String? category,
    int? priority,
    String? createdAt,
    String? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

