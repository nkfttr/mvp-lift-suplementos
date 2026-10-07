import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class DreTela extends StatefulWidget {
  const DreTela({super.key});

  @override
  State<DreTela> createState() => _DreTelaState();
}

class _DreTelaState extends State<DreTela> {
  final SupabaseService _service = SupabaseService();
  bool loading = true;
  int mes = DateTime.now().month;
  int ano = DateTime.now().year;

  Map<String, double> dre = {};

  @override
  void initState() {
    super.initState();
    _carregarDRE();
  }

  Future<void> _carregarDRE() async {
    setState(() => loading = true);
    final dados = await _service.getDRE(mes: mes, ano: ano);
    setState(() {
      dre = dados;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DRE - Resultado Financeiro", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 139, 71, 68),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  _linhaDRE("(=) Receita Bruta de Vendas", dre['receitaBruta'], isDestaque: true),
                  _linhaDRE("(-) Impostos / Deduções", dre['impostos'], isNegativo: true),
                  const Divider(),
                  _linhaDRE("(=) Receita Líquida", dre['receitaLiquida'], isDestaque: true),
                  _linhaDRE("(-) Custo das Mercadorias Vendidas (CMV)", dre['cmv'], isNegativo: true),
                  const Divider(),
                  _linhaDRE("(=) Lucro Bruto", dre['lucroBruto'], isDestaque: true),
                  _linhaDRE("(-) Despesas Operacionais", dre['despesasOperacionais'], isNegativo: true),
                  const Divider(thickness: 2),
                  
                  // RESULTADO FINAL (LUCRO OU PREJUÍZO)
                  _linhaResultadoFinal(dre['lucroLiquido'] ?? 0.0),
                ],
              ),
            ),
    );
  }

  Widget _linhaDRE(String titulo, double? valor, {bool isDestaque = false, bool isNegativo = false}) {
    final v = valor ?? 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: TextStyle(fontSize: 15, fontWeight: isDestaque ? FontWeight.bold : FontWeight.normal)),
          Text(
            "${isNegativo && v > 0 ? '-' : ''} R\$ ${v.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 15,
              fontWeight: isDestaque ? FontWeight.bold : FontWeight.normal,
              color: isNegativo ? Colors.red.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaResultadoFinal(double valor) {
    final bool eLucro = valor >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: eLucro ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            eLucro ? "(=) LUCRO LÍQUIDO" : "(=) PREJUÍZO LÍQUIDO",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: eLucro ? Colors.green.shade900 : Colors.red.shade900,
            ),
          ),
          Text(
            "R\$ ${valor.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: eLucro ? Colors.green.shade900 : Colors.red.shade900,
            ),
          ),
        ],
      ),
    );
  }
}