import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nesherprints/app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // En escritorio SQLite va por FFI.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const NesherPrintsApp());
}
