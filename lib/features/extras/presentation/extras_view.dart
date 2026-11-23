import 'package:flutter/material.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/widgets/confirm_dialog.dart';
import 'package:nesherprints/core/widgets/page_header.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';
import 'package:nesherprints/features/extras/presentation/widgets/add_stock_dialog.dart';
import 'package:nesherprints/features/extras/presentation/widgets/extra_card.dart';
import 'package:nesherprints/features/extras/presentation/widgets/extra_dialog.dart';

/// Inventario de piezas extra (llaveros, clickers…).
class ExtrasView extends StatefulWidget {
  const ExtrasView({super.key});

  @override
  State<ExtrasView> createState() => _ExtrasViewState();
}

class _ExtrasViewState extends State<ExtrasView> {
  List<Extra> _extras = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ServiceLocator.extras.getAll();
    if (!mounted) return;
    setState(() {
      _extras = data;
      _isLoading = false;
    });
  }

  void _openDialog([Extra? extra]) {
    showDialog(
      context: context,
      builder: (_) => ExtraDialog(
        initial: extra,
        onSave: (saved) async {
          await ServiceLocator.extras.save(saved);
          await _load();
        },
      ),
    );
  }

  void _addStock(Extra extra) {
    showDialog(
      context: context,
      builder: (_) => AddStockDialog(
        extra: extra,
        onConfirm: (units, total) async {
          await ServiceLocator.extras.addStock(
            extra.id!,
            units: units,
            totalPrice: total,
          );
          await _load();
        },
      ),
    );
  }

  Future<void> _delete(Extra extra) async {
    final ok = await showConfirmDialog(
      context,
      title: AppStrings.confirmDeletionTitle,
      message: AppStrings.confirmDeletionMessage(extra.name),
      confirmText: AppStrings.delete,
    );
    if (!ok) return;
    await ServiceLocator.extras.delete(extra.id!);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: AppStrings.extrasTitle,
            action: ElevatedButton.icon(
              onPressed: _openDialog,
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addPieces),
              style: AppButtonStyles.primary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Scrollbar(
              child: ListView.separated(
                itemCount: _extras.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final extra = _extras[index];
                  return ExtraCard(
                    extra: extra,
                    onEdit: () => _openDialog(extra),
                    onAddStock: () => _addStock(extra),
                    onDelete: () => _delete(extra),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
