import 'package:flutter/material.dart';
import '../models/task_item.dart';
import '../services/database_helper.dart';
import '../services/hive_service.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  bool _isBenchmarking = false;
  String _benchmarkStatus = 'Tekan tombol di bawah untuk menjalankan pengujian performa SQFlite vs Hive.';
  int? _sqfliteWriteTime;
  int? _sqfliteReadTime;
  int? _hiveWriteTime;
  int? _hiveReadTime;

  Future<void> _runBenchmark() async {
    setState(() {
      _isBenchmarking = true;
      _benchmarkStatus = 'Sedang menjalankan benchmark (100 records)...';
    });

    const testCount = 100;
    final now = DateTime.now().toIso8601String();

    try {
      // 1. BENCHMARK SQFLITE
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      // SQFlite Write (menggunakan Batch untuk efisiensi transaksi)
      final swSqfliteWrite = Stopwatch()..start();
      final batch = db.batch();
      for (int i = 0; i < testCount; i++) {
        batch.insert(DatabaseHelper.tableNotes, {
          DatabaseHelper.colTitle: 'Benchmark Item #$i',
          DatabaseHelper.colContent: 'Deskripsi konten pengujian benchmark SQFlite nomor $i',
          DatabaseHelper.colCategory: 'Benchmark',
          DatabaseHelper.colPriority: 1,
          DatabaseHelper.colCreatedAt: now,
        });
      }
      await batch.commit(noResult: true);
      swSqfliteWrite.stop();

      // SQFlite Read
      final swSqfliteRead = Stopwatch()..start();
      await dbHelper.getAllNotes();
      swSqfliteRead.stop();

      // 2. BENCHMARK HIVE
      final hive = HiveService.instance;

      // Hive Write
      final swHiveWrite = Stopwatch()..start();
      for (int i = 0; i < testCount; i++) {
        final id = 'bench_$i';
        await hive.addTask(TaskItem(
          id: id,
          title: 'Benchmark Task #$i',
          note: 'Deskripsi konten pengujian benchmark Hive nomor $i',
          isCompleted: false,
          createdAt: now,
        ));
      }
      swHiveWrite.stop();

      // Hive Read
      final swHiveRead = Stopwatch()..start();
      hive.getAllTasks();
      swHiveRead.stop();

      setState(() {
        _sqfliteWriteTime = swSqfliteWrite.elapsedMilliseconds;
        _sqfliteReadTime = swSqfliteRead.elapsedMilliseconds;
        _hiveWriteTime = swHiveWrite.elapsedMilliseconds;
        _hiveReadTime = swHiveRead.elapsedMilliseconds;
        _isBenchmarking = false;
        _benchmarkStatus = 'Uji coba $testCount data selesai!';
      });
    } catch (e) {
      setState(() {
        _isBenchmarking = false;
        _benchmarkStatus = 'Terjadi kesalahan saat benchmark: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Komparasi & Dokumentasi Storage'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Benchmark Interaktif
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: Colors.deepPurple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.speed, color: Colors.deepPurple, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Uji Coba Performa Langsung (Live Benchmark)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _benchmarkStatus,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 14),

                    if (_sqfliteWriteTime != null && _hiveWriteTime != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildResultCard(
                              title: 'SQFlite (SQLite)',
                              writeMs: _sqfliteWriteTime!,
                              readMs: _sqfliteReadTime!,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildResultCard(
                              title: 'Hive (NoSQL)',
                              writeMs: _hiveWriteTime!,
                              readMs: _hiveReadTime!,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isBenchmarking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.play_arrow),
                        label: Text(_isBenchmarking ? 'Menjalankan...' : 'Jalankan Benchmark (100 Record)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _isBenchmarking ? null : _runBenchmark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Heading Tabel Perbandingan
            const Text(
              'Tabel Ringkasan: SQFlite vs Hive vs Lainnya',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Table Comparison
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                columns: const [
                  DataColumn(label: Text('Parameter', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('SQFlite', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                  DataColumn(label: Text('Hive', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                  DataColumn(label: Text('SharedPreferences', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))),
                ],
                rows: const [
                  DataRow(cells: [
                    DataCell(Text('Tipe / Model Data')),
                    DataCell(Text('Relational (SQL Table)')),
                    DataCell(Text('NoSQL (Key-Value / Box)')),
                    DataCell(Text('Key-Value Sederhana')),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Bahasa Query')),
                    DataCell(Text('SQL (SELECT, WHERE, JOIN)')),
                    DataCell(Text('Dart API murni')),
                    DataCell(Text('Getter / Setter langsung')),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Kecepatan Baca / Tulis')),
                    DataCell(Text('Cepat (tergantung I/O disk)')),
                    DataCell(Text('Sangat Cepat (In-Memory Index)')),
                    DataCell(Text('Cepat untuk data kecil')),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Relasi & JOIN')),
                    DataCell(Text('Mendukung Foreign Key & JOIN')),
                    DataCell(Text('Tidak mendukung (manual link)')),
                    DataCell(Text('Tidak mendukung')),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Struktur Skema')),
                    DataCell(Text('Ketat (Strict Schema)')),
                    DataCell(Text('Fleksibel (Schemaless / Adapter)')),
                    DataCell(Text('Primitif (int, str, bool)')),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Dukungan Platform')),
                    DataCell(Text('Android & iOS murni')),
                    DataCell(Text('Semua Platform (Desktop/Web/Mobile)')),
                    DataCell(Text('Semua Platform')),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Kebutuhan Migrasi')),
                    DataCell(Text('Perlu onUpgrade SQLite')),
                    DataCell(Text('Mudah (tambah field default)')),
                    DataCell(Text('Tidak perlu')),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Analisis Kapan Menggunakan
            const Text(
              'Panduan Pemilihan Teknologi Local Storage',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _buildGuideCard(
              title: 'Kapan Menggunakan SQFlite?',
              icon: Icons.table_chart,
              color: Colors.indigo,
              points: [
                'Data memiliki relasi antar entitas yang kompleks (Many-to-Many, One-to-Many).',
                'Membutuhkan transaksi ACID yang ketat untuk integritas data finansial/inventaris.',
                'Perlu melakukan pencarian berbasis teks kompleks atau agregasi (SUM, AVG, GROUP BY).',
                'Volume data sangat besar dan tidak memungkinkan dimuat seluruhnya ke RAM.',
              ],
            ),
            const SizedBox(height: 12),

            _buildGuideCard(
              title: 'Kapan Menggunakan Hive?',
              icon: Icons.bolt,
              color: Colors.teal,
              points: [
                'Membutuhkan kecepatan baca/tulis super tinggi (benchmark membuktikan Hive lebih cepat).',
                'Menyimpan cache data API, session login, bookmark, keranjang belanja offline.',
                'Aplikasi cross-platform yang membutuhkan dukungan Web dan Desktop tanpa library C tambahan.',
                'Struktur data dokumen atau objek Dart yang sering berubah tanpa skema kaku.',
              ],
            ),
            const SizedBox(height: 12),

            _buildGuideCard(
              title: 'Kapan Menggunakan SharedPreferences?',
              icon: Icons.settings,
              color: Colors.orange,
              points: [
                'Menyimpan konfigurasi/preferensi user sederhana (Tema Gelap/Terang, Bahasa, Onboarding).',
                'Menyimpan token autentikasi sederhana atau preferensi notifikasi.',
                'Bukan untuk kumpulan data list atau objek bertingkat yang banyak.',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required int writeMs,
    required int readMs,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          const Divider(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tulis (Write):', style: TextStyle(fontSize: 12)),
              Text('$writeMs ms', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Baca (Read):', style: TextStyle(fontSize: 12)),
              Text('$readMs ms', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> points,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...points.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    Expanded(child: Text(p, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

