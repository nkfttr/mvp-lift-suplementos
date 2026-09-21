import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  // =========================
  // CLIENTES
  // =========================

  Future<void> addClient({
    required String name,
    required String phone,
    String? address,
  }) async {
    await supabase.from('clients').insert({
      'name': name,
      'phone': phone,
      'address': address?.trim().isEmpty ?? true ? null : address,
    });
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    final response = await supabase.from('clientes_com_vendas').select();
    return response;
  }

  Future<void> updateClient({
    required String id,
    required String name,
    required String phone,
    String? address,
  }) async {
    await supabase
        .from('clients')
        .update({
          'name': name,
          'phone': phone,
          'address': address?.trim().isEmpty ?? true ? null : address,
        })
        .eq('id', id);
  }
  
  // =========================
  // PRODUTOS
  // =========================

  Future<void> addProduct({
    required String name,
    required double price,
    required int quantity,
    String? imagePath,
  }) async {
    await supabase.from('products').insert({
      'name': name,
      'price': price,
      'quantity': quantity,
      'image_path': imagePath,
    });
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await supabase.from('products').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required double price,
    required int quantity,
    String? imagePath,
  }) async {
    await supabase
        .from('products')
        .update({
          'name': name,
          'price': price,
          'quantity': quantity,
          'image_path': imagePath,
        })
        .eq('id', id);
  }

  // =========================
  // VENDAS
  // =========================

  Future<void> addSale({
    required String clientId,
    required String productId,
    required int quantity,
    required int durationDays,
  }) async {
    await supabase.from('sales').insert({
      'client_id': clientId,
      'product_id': productId,
      'quantity': quantity,
      'duration_days': durationDays,
      'sale_date': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getSales() async {
    final response = await supabase
        .from('sales')
        .select('''
          *,
          clients!fk_sales_client(*),
          products!fk_sales_product(*)
        ''')
        .neq('status', 'concluido');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> deleteSale(String saleId) async {
    await supabase.from('sales').delete().eq('id', saleId);
  }

  // =========================
  // DASHBOARD
  // =========================

  Future<int> getActiveClients() async {
    final sales = await supabase.from('sales').select('client_id');
    final uniqueClients = sales.map((e) => e['client_id']).toSet();
    return uniqueClients.length;
  }

  // ATUALIZADO PARA RECEBER MÊS E ANO
  Future<double> getMonthlyRevenue({required int mes, required int ano}) async {
    final startOfMonth = DateTime(ano, mes, 1).toIso8601String();
    final endOfMonth = DateTime(ano, mes + 1, 0, 23, 59, 59).toIso8601String();

    final sales = await supabase
        .from('sales')
        .select('''
          quantity,
          sale_date,
          products(price)
        ''')
        .gte('sale_date', startOfMonth)
        .lte('sale_date', endOfMonth);

    double total = 0;

    for (final sale in sales) {
      if (sale['products'] != null) {
        total += (sale['quantity'] as int) * (sale['products']['price'] as num).toDouble();
      }
    }

    return total;
  }

  Future<int> getUrgentReminders() async {
    final sales = await supabase.from('sales').select();
    int count = 0;

    for (final sale in sales) {
      final saleDate = DateTime.parse(sale['sale_date']);
      final durationDays = sale['duration_days'] as int;
      final reminderDate = saleDate.add(Duration(days: durationDays));
      final daysLeft = reminderDate.difference(DateTime.now()).inDays;

      if (daysLeft <= 3 && daysLeft >= 0) {
        count++;
      }
    }
    return count;
  }
 
  Future<List<Map<String, dynamic>>> getSalesByClient(String clientId) async {
    final response = await supabase
        .from('sales')
        .select('''
          *,
          products!fk_sales_product(*)
        ''')
        .eq('client_id', clientId)
        .order('sale_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ATUALIZADO PARA RECEBER MÊS E ANO (Projeção do mês fornecido)
  Future<double> getNextMonthProjection({required int mes, required int ano}) async {
    final sales = await supabase.from('sales').select('''
      quantity,
      sale_date,
      duration_days,
      products!fk_sales_product(price)
    ''');

    double total = 0;

    for (final sale in sales) {
      final saleDate = DateTime.parse(sale['sale_date']);
      final reminderDate = saleDate.add(Duration(days: sale['duration_days']));

      // Verifica se a data de lembrete (recompra) cai no mês e ano informados
      if (reminderDate.month == mes && reminderDate.year == ano) {
        final preco = (sale['products']['price'] as num).toDouble();
        final quantidade = sale['quantity'] as int;
        total += preco * quantidade;
      }
    }
    
    return total;
  }

  // =========================
  // METAS DO MÊS
  // =========================

  // ATUALIZADO PARA RECEBER MÊS E ANO
  Future<double> getValorVendidoMesAtual({required int mes, required int ano}) async {
    final startOfMonth = DateTime(ano, mes, 1).toIso8601String();
    final endOfMonth = DateTime(ano, mes + 1, 0, 23, 59, 59).toIso8601String();

    final response = await supabase
        .from('sales')
        .select('quantity, products!fk_sales_product(price)')
        .gte('sale_date', startOfMonth)
        .lte('sale_date', endOfMonth);

    double total = 0;
    for (var row in response) {
      if (row['products'] != null) {
        final qtd = (row['quantity'] as num).toInt();
        final preco = (row['products']['price'] as num).toDouble();
        total += (qtd * preco);
      }
    }
    return total;
  }

  // ATUALIZADO PARA RECEBER MÊS E ANO
  Future<double> getMetaFinanceiraDoMes({required int mes, required int ano}) async {
    final mesAnoSelecionado = "${mes.toString().padLeft(2, '0')}/$ano";

    final manual = await supabase
        .from('metas_manuais')
        .select('meta_valor')
        .eq('mes_ano', mesAnoSelecionado)
        .maybeSingle();

    if (manual != null) {
      return (manual['meta_valor'] as num).toDouble();
    }

    final startOfLastMonth = DateTime(ano, mes - 1, 1).toIso8601String();
    final endOfLastMonth = DateTime(ano, mes, 0, 23, 59, 59).toIso8601String();

    final response = await supabase
        .from('sales')
        .select('quantity, products!fk_sales_product(price)')
        .gte('sale_date', startOfLastMonth)
        .lte('sale_date', endOfLastMonth);

    double totalMesPassado = 0;
    for (var row in response) {
      if(row['products'] != null) {
        final qtd = (row['quantity'] as num).toInt();
        final preco = (row['products']['price'] as num).toDouble();
        totalMesPassado += (qtd * preco);
      }
    }

    return totalMesPassado > 0 ? totalMesPassado : 1000.0;
  }

  // ATUALIZADO PARA RECEBER MÊS E ANO
  Future<void> salvarMetaFinanceiraManual(double novaMeta, {required int mes, required int ano}) async {
    final mesAnoSelecionado = "${mes.toString().padLeft(2, '0')}/$ano";

    try {
      await supabase.from('metas_manuais').upsert({
        'mes_ano': mesAnoSelecionado,
        'meta_valor': novaMeta,
      }, onConflict: 'mes_ano');
    } catch (e) {
      print("Erro ao salvar meta: $e");
      rethrow; 
    }
  }

  Future<void> updateSale({
    required String id, 
    required String clientId,
    required String productId,
    required int quantity,
    required int durationDays,
  }) async { 
    await supabase
        .from('sales')
        .update({
          'client_id': clientId,
          'product_id': productId,
          'quantity': quantity,
          'duration_days': durationDays,
        })
        .eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await supabase.from('products').delete().eq('id', id);
  }

  Future<void> deleteClient(String id) async {
    await supabase.from('clients').delete().eq('id', id);
  }
    
  Future<List<Map<String, dynamic>>> getClientsWithSales() async {
    return await supabase
        .from('clients')
        .select('*, sales(*)');
  }

  Future<Map<String, dynamic>> getRelatorioAvancado(DateTime dataInicio, DateTime dataFim) async {
    try {
      final inicio = DateTime(dataInicio.year, dataInicio.month, dataInicio.day, 0, 0, 0).toIso8601String();
      final fim = DateTime(dataFim.year, dataFim.month, dataFim.day, 23, 59, 59).toIso8601String();

      // NOTA: Como a tua tabela parece chamar-se 'sales' e 'products', ajustei a query do relatório
      // para utilizar as tabelas que tu já tens no código
      final vendasResponse = await supabase
          .from('sales')
          .select('*, products!fk_sales_product(nome:name, preco:price)')
          .gte('sale_date', inicio)
          .lte('sale_date', fim);

      double totalFaturamento = 0.0;
      int qtdPedidos = vendasResponse.length;
      Map<String, Map<String, dynamic>> agrupado = {};

      for (var venda in vendasResponse) {
        // Cálculo do Faturamento
        double preco = 0.0;
        if (venda['products'] != null) {
          preco = (venda['products']['preco'] as num).toDouble();
        }
        int qtd = (venda['quantity'] as num).toInt();
        double valorTotalItem = preco * qtd;
        
        totalFaturamento += valorTotalItem;

        // Agrupamento de Produtos Mais Vendidos
        String nomeProduto = venda['products'] != null ? venda['products']['nome'] : 'Desconhecido';
        
        if (agrupado.containsKey(nomeProduto)) {
          agrupado[nomeProduto]!['quantidade'] += qtd;
          agrupado[nomeProduto]!['total'] += valorTotalItem;
        } else {
          agrupado[nomeProduto] = {
            'nome': nomeProduto,
            'quantidade': qtd,
            'total': valorTotalItem,
          };
        }
      }

      List<Map<String, dynamic>> topProdutos = agrupado.values.toList();
      topProdutos.sort((a, b) => (b['quantidade'] as int).compareTo(a['quantidade'] as int));

      return {
        'faturamento': totalFaturamento,
        'qtd_pedidos': qtdPedidos,
        'top_produtos': topProdutos,
      };
    } catch (e) {
      print('Erro ao obter relatório avançado: $e');
      return {
        'faturamento': 0.0,
        'qtd_pedidos': 0,
        'top_produtos': [],
      };
    }
  }
}