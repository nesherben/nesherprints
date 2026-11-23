import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/features/clients/domain/client.dart';

/// Tarjeta de cliente con sus datos de contacto.
class ClientCard extends StatelessWidget {
  const ClientCard({super.key, required this.client, required this.onEdit});

  final Client client;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    const contactStyle = TextStyle(fontSize: 13, color: AppColors.textMuted);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    client.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (client.phone.isNotEmpty)
                    Text(
                      AppStrings.clientPhone(client.phone),
                      style: contactStyle,
                    ),
                  if (client.email.isNotEmpty)
                    Text(
                      AppStrings.clientEmail(client.email),
                      style: contactStyle,
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
              tooltip: AppStrings.editClient,
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}
