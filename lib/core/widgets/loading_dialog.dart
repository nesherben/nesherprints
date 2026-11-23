import 'package:flutter/material.dart';

/// Contenido de un diálogo mientras carga sus datos.
class LoadingDialog extends StatelessWidget {
  const LoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      content: SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
