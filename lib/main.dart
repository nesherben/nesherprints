import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nesherprints/core.dart';
import 'presentation/screens/main_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializamos SQLite para Windows/Desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const NesherPrintsApp());
}

class NesherPrintsApp extends StatelessWidget {
  const NesherPrintsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NesherPrints ERP',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.home,
      routes: {AppRoutes.home: (context) => const MainLayout()},
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        cardTheme: const CardThemeData(
          color: AppColors.surface,
          elevation: 4,
          margin: EdgeInsets.all(8),
        ),
        useMaterial3: true,
      ),
    );
  }
}
