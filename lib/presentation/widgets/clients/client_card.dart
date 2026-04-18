import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ClientCard extends StatelessWidget {
  final Map<String, dynamic> client;
  final VoidCallback onEdit;

  const ClientCard({super.key, required this.client, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // --- AVATAR CIRCULAR ---
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // --- DATOS DEL CLIENTE ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    client['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if ((client['phone'] ?? '').isNotEmpty)
                    Text(
                      "📞 ${client['phone']}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  if ((client['email'] ?? '').isNotEmpty)
                    Text(
                      "✉️ ${client['email']}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),

            // --- BOTÓN DE EDITAR ---
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
              tooltip: 'Editar Cliente',
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}
