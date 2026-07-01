import 'package:commerce_mvp/screens/add_vendas_tela.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/supabase_service.dart';

class DashboardTela extends StatefulWidget {
  const DashboardTela({super.key});

  @override
  State<DashboardTela> createState() => _DashboardTelaState();
}

class _DashboardTelaState extends State<DashboardTela> {
  final SupabaseService _service = SupabaseService(); 

  double receitaPrevista = 0;
  String tituloReceitaPrevista = 'Receita Prevista';
  bool loading = true;

  int clientesAtivos = 0;
  int lembretesUrgentes = 0;
  double vendasMes = 0;
  
  // NOVAS VARIÁVEIS PARA A META FINANCEIRA
  double metaValor = 0;
  double valorVendidoAtual = 0;

  @override
  void initState() {
    super.initState();
    carregarDashboard();
  }

  Future<void> carregarDashboard() async {
    try {
      final ativos = await _service.getActiveClients();
      receitaPrevista = await _service.getNextMonthProjection();
      
      final now = DateTime.now();
      final nextMonth = now.month == 12 ? 1 : now.month + 1;

      const meses = [
        '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
        'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
      ];

      final nomeMes = meses[nextMonth];
      final urgentes = await _service.getUrgentReminders();
      final receita = await _service.getMonthlyRevenue();
      
      // CARREGANDO OS DADOS DA META FINANCEIRA
      final meta = await _service.getMetaFinanceiraDoMes();
      final valorAtual = await _service.getValorVendidoMesAtual();

      if (mounted) {
        setState(() {
          clientesAtivos = ativos;
          lembretesUrgentes = urgentes;
          vendasMes = receita;
          metaValor = meta;
          valorVendidoAtual = valorAtual;
          loading = false;
          tituloReceitaPrevista = 'Receita Prevista para $nomeMes';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { loading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dashboard: $e')),
        );
      }
    }
  }

  void _editarMeta() {
    TextEditingController controller = TextEditingController(text: metaValor.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Editar Meta Financeira"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: "Valor da meta (R\$)",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
            onPressed: () async {
                double novaMeta = double.tryParse(controller.text) ?? 0.0;
                
                // Fecha o modal antes de tentar salvar
                Navigator.pop(context);
                
                setState(() => loading = true);
                await _service.salvarMetaFinanceiraManual(novaMeta);
                await carregarDashboard();
              },
              child: const Text("Salvar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard📊", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
        ],
        flexibleSpace: Container(color: const Color.fromARGB(255, 139, 71, 68)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: carregarDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text("Visão Geral", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  // CARD DA META FINANCEIRA
                  _buildMetaCard(),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: dashboardCard(title: "Clientes Ativos", value: clientesAtivos.toString(), icon: Icons.people, color: Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: dashboardCard(title: "Lembretes Urgentes", value: lembretesUrgentes.toString(), icon: Icons.warning, color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  dashboardCard(title: "Vendas do Mês", value: "R\$ ${vendasMes.toStringAsFixed(2)}", icon: Icons.point_of_sale, color: Colors.green),
                  const SizedBox(height: 16),
                  dashboardCard(title: tituloReceitaPrevista, value: "R\$ ${receitaPrevista.toStringAsFixed(2)}", icon: Icons.trending_up, color: Colors.purple),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVendasTela()));
          carregarDashboard();
        },
        child: const Icon(Icons.point_of_sale),
      ),
    );
  }

  Widget _buildMetaCard() {
    double progresso = metaValor > 0 ? (valorVendidoAtual / metaValor) : 0.0;
    if (progresso > 1.0) progresso = 1.0;

    Color corProgresso = Colors.orange;
    if (progresso >= 1.0) corProgresso = Colors.green;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.flag, color: Colors.orange),
                  SizedBox(width: 8),
                  Text("Meta Financeira", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: _editarMeta)
            ],
          ),
          const SizedBox(height: 8),
          Text("R\$ ${valorVendidoAtual.toStringAsFixed(2)} de R\$ ${metaValor.toStringAsFixed(2)} vendidos", style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 12,
              backgroundColor: Colors.grey[300],
              color: corProgresso,
            ),
          ),
          if (progresso >= 1.0)
            const Padding(padding: EdgeInsets.only(top: 8), child: Text("Parabéns! Meta atingida! 🎉", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget dashboardCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}