import 'package:commerce_mvp/screens/add_vendas_tela.dart';
import 'package:flutter/material.dart';

import '../models/clientes.dart';
import '../services/supabase_service.dart';

import 'ClienteDetalhesTela.dart';
import 'add_clientes_tela.dart';
import 'edit_clientes_tela.dart';

// Enum para os filtros
enum FiltroCliente { todos, top5, visitantes }

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String search = "";
  FiltroCliente filtroAtual = FiltroCliente.todos;
  final supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Clientes👤",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          color: const Color.fromARGB(255, 139, 71, 68),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Pesquisar cliente...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => search = value),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _buildFiltroChip("Todos", FiltroCliente.todos),
                _buildFiltroChip("Top 5", FiltroCliente.top5),
                _buildFiltroChip("Visitantes", FiltroCliente.visitantes),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: supabaseService.getClientsWithSales(), // Use a nova função
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final data = snapshot.data ?? [];
                  
                  // 1. Converter Map para objeto Client e contar vendas
                  var listaProcessada = data.map((m) {
                    final cliente = Client.fromMap(m);
                    final vendas = (m['sales'] as List<dynamic>?) ?? [];
                    return {'client': cliente, 'vendas_count': vendas.length};
                  }).toList();

                  // 2. Aplicar os filtros
                  if (filtroAtual == FiltroCliente.top5) {
                    listaProcessada.sort((a, b) => (b['vendas_count'] as int).compareTo(a['vendas_count'] as int));
                    listaProcessada = listaProcessada.take(5).toList();
                  } else if (filtroAtual == FiltroCliente.visitantes) {
                    listaProcessada = listaProcessada.where((item) => (item['vendas_count'] as int) == 0).toList();
                  }

                  // 3. Filtrar por pesquisa de nome
                  listaProcessada = listaProcessada.where((item) {
                    final c = item['client'] as Client;
                    return c.name.toLowerCase().contains(search.toLowerCase());
                  }).toList();

                  return ListView.builder(
                    itemCount: listaProcessada.length,
                    itemBuilder: (context, index) {
                      final item = listaProcessada[index];
                      final cliente = item['client'] as Client;
                      final count = item['vendas_count'] as int;

                      return Card(
                        child: ListTile(
                          title: Text(cliente.name),
                          subtitle: Text("Compras realizadas: $count"),
                          trailing: count > 0 ? const Icon(Icons.star, color: Colors.amber) : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                // Esta é a tela que mostra o histórico de compras e permite editar
                                builder: (_) => ClienteDetalhesTela(client: cliente),
                              ),
                            ).then((_) {
                              // Ao voltar desta tela, recarrega a lista para mostrar mudanças (como nomes editados)
                              setState(() {});
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'addClient',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddClientScreen()),
              );
              setState(() {});
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'addVenda',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddVendasTela()),
              );
            },
            child: const Icon(Icons.point_of_sale),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String label, FiltroCliente valor) {
    return ChoiceChip(
      label: Text(label),
      selected: filtroAtual == valor,
      selectedColor: const Color.fromARGB(255, 139, 71, 68).withOpacity(0.3),
      onSelected: (selected) {
        if (selected) setState(() => filtroAtual = valor);
      },
    );
  }
}