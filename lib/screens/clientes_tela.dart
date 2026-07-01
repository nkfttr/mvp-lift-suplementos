import 'package:commerce_mvp/screens/add_vendas_tela.dart';
import 'package:flutter/material.dart';

import '../models/clientes.dart';
import '../services/supabase_service.dart';

import 'ClienteDetalhesTela.dart';
import 'add_clientes_tela.dart';
import 'edit_clientes_tela.dart';

// 1. Criamos o Enum para os filtros
enum FiltroCliente { todos, top5, visitantes }

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String search = "";
  
  // 2. Variável para controlar qual filtro está selecionado
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
            // PESQUISA
            TextField(
              decoration: InputDecoration(
                hintText: "Pesquisar cliente...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  search = value;
                });
              },
            ),

            const SizedBox(height: 12),

            // 3. BARRA DE FILTROS (ChoiceChips)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFiltroChip('Todos', FiltroCliente.todos),
                  const SizedBox(width: 8),
                  _buildFiltroChip('Top 5 🏆', FiltroCliente.top5),
                  const SizedBox(width: 8),
                  _buildFiltroChip('Visitantes 🚶', FiltroCliente.visitantes),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: supabaseService.getClients(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Erro: ${snapshot.error}'),
                    );
                  }

                  final clients = snapshot.data ?? [];

                  // 4. LÓGICA DE FILTRAGEM E ORDENAÇÃO
                  // Primeiro, aplicamos o filtro de texto (Pesquisa)
                  var clientesFilter = clients.where((client) {
                    final name = client['name'].toString().toLowerCase();
                    return name.contains(search.toLowerCase());
                  }).toList();

                  // Em seguida, aplicamos o filtro selecionado nos botões (Top 5 ou Visitantes)
                  if (filtroAtual == FiltroCliente.top5) {
                    // Ordena do maior comprador para o menor (Certifique-se de que o campo 'total_comprado' exista no seu DB)
                    clientesFilter.sort((a, b) {
                      double valorA = (a['total_comprado'] ?? 0.0).toDouble();
                      double valorB = (b['total_comprado'] ?? 0.0).toDouble();
                      return valorB.compareTo(valorA);
                    });
                    // Pega apenas os 5 primeiros
                    clientesFilter = clientesFilter.take(5).toList();

                  } else if (filtroAtual == FiltroCliente.visitantes) {
                    // Filtra apenas clientes que têm total_comprado igual a 0 ou nulo
                    clientesFilter = clientesFilter.where((client) {
                      double valorComprado = (client['total_comprado'] ?? 0.0).toDouble();
                      return valorComprado == 0.0;
                    }).toList();
                  }

                  if (clientesFilter.isEmpty) {
                    return const Center(
                      child: Text("Nenhum cliente encontrado"),
                    );
                  }

                  return ListView.builder(
                    itemCount: clientesFilter.length,
                    itemBuilder: (_, index) {
                      final clientMap = clientesFilter[index];

                      final client = Client(
                        id: clientMap['id'],
                        name: clientMap['name'],
                        phone: clientMap['phone'],
                        address: clientMap['address'] as String?,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(client.name),
                          subtitle: Text(client.phone),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClienteDetalhesTela(
                                  client: client,
                                ),
                              ),
                            );
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditClientScreen(
                                    client: client,
                                  ),
                                ),
                              );
                            },
                          ),
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
                MaterialPageRoute(
                  builder: (_) => const AddClientScreen(),
                ),
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
                MaterialPageRoute(
                  builder: (_) => const AddVendasTela(),
                ),
              );
            },
            child: const Icon(Icons.point_of_sale),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para os botões de filtro
  Widget _buildFiltroChip(String label, FiltroCliente valor) {
    return ChoiceChip(
      label: Text(label),
      selected: filtroAtual == valor,
      selectedColor: const Color.fromARGB(255, 139, 71, 68).withOpacity(0.3),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            filtroAtual = valor;
          });
        }
      },
    );
  }
}