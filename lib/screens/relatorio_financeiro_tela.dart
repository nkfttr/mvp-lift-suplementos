import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class RelatorioFinanceiroTela extends StatefulWidget {
  const RelatorioFinanceiroTela({super.key});

  @override
  State<RelatorioFinanceiroTela> createState() => _RelatorioFinanceiroTelaState();
}

class _RelatorioFinanceiroTelaState extends State<RelatorioFinanceiroTela> {
  final SupabaseService _service = SupabaseService();
  bool loading = false;

  DateTime dataInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime dataFim = DateTime.now();

  double totalFaturamento = 0.0;
  int totalPedidos = 0;
  double ticketMedio = 0.0;
  List<Map<String, dynamic>> produtosMaisVendidos = [];

  @override
  void initState() {
    super.initState();
    carregarRelatorio();
  }

  Future<void> carregarRelatorio() async {
    setState(() => loading = true);
    try {
      // Exemplo de chamadas para o Supabase baseadas no intervalo de datas selecionado
      final dados = await _service.getRelatorioAvancado(dataInicio, dataFim);

      setState(() {
        totalFaturamento = dados['faturamento'] ?? 0.0;
        totalPedidos = dados['qtd_pedidos'] ?? 0;
        ticketMedio = totalPedidos > 0 ? (totalFaturamento / totalPedidos) : 0.0;
        produtosMaisVendidos = List<Map<String, dynamic>>.from(dados['top_produtos'] ?? []);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar relatório: $e')),
      );
    }
  }

  Future<void> _selecionarData(bool isInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isInicio ? dataInicio : dataFim,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isInicio) {
          dataInicio = picked;
        } else {
          dataFim = picked;
        }
      });
      carregarRelatorio();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = MaterialLocalizations.of(context).formatCompactDate;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Relatório Financeiro 📈", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 139, 71, 68),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // FILTRO DE DATAS
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text("De: ${dateFormat(dataInicio)}"),
                      onPressed: () => _selecionarData(true),
                    ),
                    const Text("-"),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text("Até: ${dateFormat(dataFim)}"),
                      onPressed: () => _selecionarData(false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            loading
                ? const Expanded(child: Center(child: CircularProgressIndicator()))
                : Expanded(
                    child: ListView(
                      children: [
                        // MÉTRICAS RESUMIDAS
                        Row(
                          children: [
                            Expanded(child: _metricCard("Faturamento", "R\$ ${totalFaturamento.toStringAsFixed(2)}", Colors.green)),
                            const SizedBox(width: 8),
                            Expanded(child: _metricCard("Total Pedidos", "$totalPedidos", Colors.blue)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _metricCard("Ticket Médio", "R\$ ${ticketMedio.toStringAsFixed(2)}", Colors.orange),

                        const SizedBox(height: 24),
                        const Text("Top Suplementos Mais Vendidos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),

                        // LISTA DE PRODUTOS MAIS VENDIDdOS
                        produtosMaisVendidos.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text("Nenhuma venda registrada no período.", style: TextStyle(color: Colors.grey)),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: produtosMaisVendidos.length,
                                itemBuilder: (context, index) {
                                  final item = produtosMaisVendidos[index];
                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.brown.shade100,
                                        child: Text("${index + 1}º", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                      title: Text(item['nome'] ?? 'Produto sem nome'),
                                      subtitle: Text("Qtd: ${item['quantidade']} unidades"),
                                      trailing: Text("R\$ ${(item['total'] ?? 0.0).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}