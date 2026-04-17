import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/client_repository.dart';
import '../widgets/client_dialog.dart';

class ClientsView extends StatefulWidget {
  const ClientsView({super.key});

  @override
  State<ClientsView> createState() => _ClientsViewState();
}

class _ClientsViewState extends State<ClientsView> {
  final _clientRepo = ClientRepository();
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
    final data = await _clientRepo.getAllClients();

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
      builder: (context) => ClientDialog(
        initialClient:
            client, // Si le pasamos un cliente, se abre en modo "Editar"
        onSave: (clientData) async {
          // Si no tiene ID, es nuevo. Si tiene ID, lo actualizamos.
          if (clientData['id'] == null) {
            await _clientRepo.insertClient(clientData);
          } else {
            await _clientRepo.updateClient(clientData);
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
                          crossAxisCount: 3, // Muestra 3 tarjetas por fila
                          childAspectRatio:
                              2.5, // Hace las tarjetas más anchas que altas
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: _clients.length,
                    itemBuilder: (context, index) {
                      final c = _clients[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Icono circular
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.1,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Datos del cliente
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      c['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.textMain,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    if ((c['phone'] ?? '').isNotEmpty)
                                      Text(
                                        "📞 ${c['phone']}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    if ((c['email'] ?? '').isNotEmpty)
                                      Text(
                                        "✉️ ${c['email']}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Botón de editar
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: AppColors.textMuted,
                                ),
                                tooltip: 'Editar Cliente',
                                onPressed: () => _showClientDialog(
                                  c,
                                ), // Le pasamos el cliente actual para editarlo
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
