import 'package:flutter/material.dart';
import 'services/hive_service.dart';
import 'screens/home_screen.dart';

void main() async {
  // Memastikan binding Flutter terinisialisasi sebelum memanggil platform channel
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi storage alternatif (Hive)
  await HiveService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Praktikum Mobile P4 - Local Storage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

