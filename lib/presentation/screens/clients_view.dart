import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/service_locator.dart';
import '../widgets/clients/client_form_dialog.dart';
import '../widgets/clients/client_card.dart';

class ClientsView extends StatefulWidget {
  const ClientsView({super.key});

  @override
  State<ClientsView> createState() => _ClientsViewState();
}

class _ClientsViewState extends State<ClientsView> {
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  // --- CARGAR CLIENTES DE LA BASE DE DATOS ---
  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    final data = await ServiceLocator.clientRepo.getAllClients();

    if (mounted) {
      setState(() {
        _clients = data;
        _isLoading = false;
      });
    }
  }

  // --- ABRIR LA VENTANA DE CREAR / EDITAR CLIENTE ---
  void _showClientDialog([Map<String, dynamic>? client]) {
    showDialog(
      context: context,
      builder: (context) => ClientFormDialog(
        initialClient: client,
        onSave: (clientData) async {
          // Si no tiene ID, es nuevo. Si tiene ID, lo actualizamos.
          if (clientData['id'] == null) {
            await ServiceLocator.clientRepo.insertClient(clientData);
          } else {
            await ServiceLocator.clientRepo.updateClient(clientData);
          }
          // Recargamos la lista para ver los cambios
          _loadClients();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- CABECERA ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agenda de Clientes',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  Text(
                    'Gestiona tus contactos y compradores recurrentes',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    _showClientDialog(), // Llama a la ventana sin cliente (Modo Crear)
                icon: const Icon(Icons.person_add),
                label: const Text('Nuevo Cliente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- LISTA DE TARJETAS (GRID) ---
          Expanded(
            child: _clients.isEmpty
                ? const Center(
                    child: Text(
                      "Aún no tienes clientes registrados.",
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 16,
                      ),
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: _clients.length,
                    itemBuilder: (context, index) {
                      final client = _clients[index];
                      return ClientCard(
                        client: client,
                        onEdit: () => _showClientDialog(client),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
