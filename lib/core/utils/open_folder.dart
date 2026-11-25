import 'dart:io';

/// Abre una carpeta en el explorador del sistema (solo escritorio).
/// Devuelve `false` si no se pudo (por ejemplo, en Android).
Future<bool> openFolder(String path) async {
  try {
    if (Platform.isWindows) {
      await Process.run('explorer', [path]);
      return true;
    }
    if (Platform.isMacOS) {
      await Process.run('open', [path]);
      return true;
    }
    if (Platform.isLinux) {
      await Process.run('xdg-open', [path]);
      return true;
    }
  } on Object {
    return false;
  }
  return false;
}

/// Hay explorador de archivos al que enviar al usuario.
bool get canOpenFolders =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;
