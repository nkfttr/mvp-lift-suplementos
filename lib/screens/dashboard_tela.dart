import 'package:commerce_mvp/screens/add_vendas_tela.dart';
import 'package:commerce_mvp/screens/relatorio_financeiro_tela.dart'; // Importe a nova tela
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:commerce_mvp/screens/dre_tela.dart'; // <-- Adicione esta linha
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
  
  double metaValor = 0;
  double valorVendidoAtual = 0;

  // NOVAS VARIaVEIS PARA FILTRO DE MES/ANOa
  late int mesSelecionado;
  late int anoSelecionado;

  final List<String> nomesMeses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    mesSelecionado = now.month;
    anoSelecionado = now.year;
    carregarDashboard();
  }

  Future<void> carregarDashboard() async {
    setState(() => loading = true);
    try {
      final ativos = await _service.getActiveClients();
      final urgentes = await _service.getUrgentReminders();
      
      
      final receita = await _service.getMonthlyRevenue(mes: mesSelecionado, ano: anoSelecionado);
      final meta = await _service.getMetaFinanceiraDoMes(mes: mesSelecionado, ano: anoSelecionado);
      final valorAtual = await _service.getValorVendidoMesAtual(mes: mesSelecionado, ano: anoSelecionado);
      
      
      final proximoMes = mesSelecionado == 12 ? 1 : mesSelecionado + 1;
      final proximoAno = mesSelecionado == 12 ? anoSelecionado + 1 : anoSelecionado;
      receitaPrevista = await _service.getNextMonthProjection(mes: proximoMes, ano: proximoAno);

      if (mounted) {
        setState(() {
          clientesAtivos = ativos;
          lembretesUrgentes = urgentes;
          vendasMes = receita;
          metaValor = meta;
          valorVendidoAtual = valorAtual;
          loading = false;
          tituloReceitaPrevista = 'Receita Prevista para ${nomesMeses[proximoMes - 1]}';
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
          title: Text("Editar Meta - ${nomesMeses[mesSelecionado - 1]}/$anoSelecionado"),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
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
                Navigator.pop(context);
                setState(() => loading = true);
                await _service.salvarMetaFinanceiraManual(novaMeta, mes: mesSelecionado, ano: anoSelecionado);
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
        title: const Text("Dashboard 📊", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          // ÍCONE PARA NAVEGAR ATÉ A TELA DE RELATÓRI
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.white),
            tooltip: "Relatório Financeiro Avançado",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RelatorioFinanceiroTela()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.request_quote, color: Colors.white),
            tooltip: "Demonstrativo (DRE)",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DreTela()),
              );
            },
          ),
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
                  // CABEÇALHO COM SELETOR DE MÊS E ANO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Visão Geral", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      _buildSeletorMesAno(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
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

  // SELETOR DE MÊS E ANO
  Widget _buildSeletorMesAno() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<int>(
            value: mesSelecionado,
            underline: const SizedBox(),
            items: List.generate(12, (index) {
              return DropdownMenuItem(
                value: index + 1,
                child: Text(nomesMeses[index], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              );
            }),
            onChanged: (novoMes) {
              if (novoMes != null) {
                setState(() => mesSelecionado = novoMes);
                carregarDashboard();
              }
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: anoSelecionado,
            underline: const SizedBox(),
            items: [DateTime.now().year - 1, DateTime.now().year, DateTime.now().year + 1].map((ano) {
              return DropdownMenuItem(
                value: ano,
                child: Text(ano.toString(), style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (novoAno) {
              if (novoAno != null) {
                setState(() => anoSelecionado = novoAno);
                carregarDashboard();
              }
            },
          ),
        ],
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
              Row(
                children: [
                  const Icon(Icons.flag, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text("Meta (${nomesMeses[mesSelecionado - 1]})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
//323
  Widget dashboardCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}