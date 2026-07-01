import 'package:commerce_mvp/screens/edit_lembretes_tela.dart';
import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import 'add_lembretes_tela.dart';

class LembretesTela extends StatefulWidget {
  const LembretesTela({super.key});

  @override
  State<LembretesTela> createState() => _LembretesTelaState();
}

class _LembretesTelaState extends State<LembretesTela> {
  final SupabaseService _service = SupabaseService();

  List<Map<String, dynamic>> vendas = [];
  bool loading = true;
  List<Map<String, dynamic>> vendasFiltradas = [];

  final TextEditingController pesquisaController = TextEditingController();

  String? produtoSelecionado;
  int? diasSelecionados;

  @override
  void initState() {
    super.initState();
    carregarLembretes();
  }

  @override
  void dispose() {
    pesquisaController.dispose();
    super.dispose();
  }

  void aplicarFiltros() {
    final textoPesquisa = pesquisaController.text.toLowerCase();
    final agora = DateTime.now();

    final filtradas = vendas.where((venda) {
      final cliente = venda['clients']['name'].toString().toLowerCase();
      final produto = venda['products']['name'].toString();
      final saleDate = DateTime.parse(venda['sale_date']);

      final reminderDate = saleDate.add(
        Duration(days: venda['duration_days']),
      );

      final daysLeft = reminderDate.difference(agora).inDays;

      // Pesquisa por cliente
      if (textoPesquisa.isNotEmpty && !cliente.contains(textoPesquisa)) {
        return false;
      }

      // Produto
      if (produtoSelecionado != null && produto != produtoSelecionado) {
        return false;
      }

      // Dias restantes
      if (diasSelecionados != null && daysLeft > diasSelecionados!) {
        return false;
      }

      return true;
    }).toList();

    setState(() {
      vendasFiltradas = filtradas;
    });
  }

  Future<void> carregarLembretes() async {
    try {
      final response = await _service.getSales();

      response.sort((a, b) {
        final aReminder = DateTime.parse(a['sale_date']).add(
          Duration(days: a['duration_days']),
        );

        final bReminder = DateTime.parse(b['sale_date']).add(
          Duration(days: b['duration_days']),
        );

        return aReminder.compareTo(bReminder);
      });

      if (mounted) {
        setState(() {
          vendas = response;
          vendasFiltradas = response;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar lembretes: $e'),
          ),
        );
      }
    }
  }

  String formatarData(DateTime data) {
    return "${data.day.toString().padLeft(2, '0')}/"
        "${data.month.toString().padLeft(2, '0')}/"
        "${data.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Lembretes",
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
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : vendas.isEmpty
              ? const Center(
                  child: Text(
                    "Nenhum lembrete encontrado",
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: pesquisaController,
                            decoration: InputDecoration(
                              hintText: 'Pesquisar cliente...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: pesquisaController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        pesquisaController.clear();
                                        aplicarFiltros();
                                      },
                                    )
                                  : null,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (_) => aplicarFiltros(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: produtoSelecionado,
                                  decoration: const InputDecoration(
                                    labelText: 'Produto',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('Todos'),
                                    ),
                                    ...vendas
                                        .map((v) => v['products']['name'].toString())
                                        .toSet()
                                        .map(
                                          (produto) => DropdownMenuItem(
                                            value: produto,
                                            child: Text(produto),
                                          ),
                                        ),
                                  ],
                                  onChanged: (value) {
                                    produtoSelecionado = value;
                                    aplicarFiltros();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: diasSelecionados,
                                  decoration: const InputDecoration(
                                    labelText: 'Dias restantes',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: null,
                                      child: Text('Todos'),
                                    ),
                                    DropdownMenuItem(
                                      value: 3,
                                      child: Text('Até 3 dias'),
                                    ),
                                    DropdownMenuItem(
                                      value: 7,
                                      child: Text('Até 7 dias'),
                                    ),
                                    DropdownMenuItem(
                                      value: 30,
                                      child: Text('Até 30 dias'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    diasSelecionados = value;
                                    aplicarFiltros();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: vendasFiltradas.isEmpty
                          ? const Center(
                              child: Text(
                                'Nenhum lembrete encontrado.',
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: vendasFiltradas.length,
                              itemBuilder: (_, index) {
                                final venda = vendasFiltradas[index];
                                final saleDate = DateTime.parse(venda['sale_date']);
                                final reminderDate = saleDate.add(Duration(days: venda['duration_days']));
                                final daysLeft = reminderDate.difference(DateTime.now()).inDays;

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                  title: Text(venda['clients']['name'].toString()),
                                  subtitle: Text(
                                    'Produto: ${venda['products']['name']}\n'
                                    'Lembrete: ${formatarData(reminderDate)} (em $daysLeft dias)',
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'editar') {
                                        // 1. Abre a tela de edição passando a venda atual
                                        final atualizou = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EditLembreteTela(venda: venda),
                                          ),
                                        );

                                        // 2. Se ao voltar a tela sinalizar sucesso, recarrega a lista
                                        if (atualizou == true) {
                                          carregarLembretes();
                                        }
                                      } else if (value == 'feito') {
                                        // Lógica para marcar como feito...
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'editar',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit),
                                            SizedBox(width: 8),
                                            Text('Editar'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'feito',
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green),
                                            SizedBox(width: 8),
                                            Text('Marcar como feito'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  )
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final atualizou = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddLembreteScreen(),
            ),
          );

          if (atualizou == true) {
            carregarLembretes();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}