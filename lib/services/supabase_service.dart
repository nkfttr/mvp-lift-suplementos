import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient supabase =
      Supabase.instance.client;

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
      'address': address?.trim().isEmpty ?? true
          ? null
          : address,
    });
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    // Agora o app busca da View que criamos, que já traz o 'total_comprado' pronto!
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
          'address': address?.trim().isEmpty ?? true
              ? null
              : address,
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
    final response =
        await supabase.from('products').select();

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
    await supabase
        .from('sales')
        .insert({
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

  // Função para apagar um registo de Venda
    Future<void> deleteSale(String saleId) async {
      await supabase.from('sales').delete().eq('id', saleId);
    }

  // =========================
  // DASHBOARD
  // =========================

  Future<int> getActiveClients() async {
    final sales =
        await supabase.from('sales').select('client_id');

    final uniqueClients = sales
        .map((e) => e['client_id'])
        .toSet();

    return uniqueClients.length;
  }

  Future<double> getMonthlyRevenue() async {
    final now = DateTime.now();

    final sales = await supabase
        .from('sales')
        .select('''
          quantity,
          sale_date,
          products(price)
        ''');

    double total = 0;

    for (final sale in sales) {
      final saleDate =
          DateTime.parse(sale['sale_date']);

      if (saleDate.month == now.month &&
          saleDate.year == now.year) {
        total +=
            (sale['quantity'] as int) *
            (sale['products']['price'] as num)
                .toDouble();
      }
    }

    return total;
  }

  Future<int> getUrgentReminders() async {
    final sales = await supabase
        .from('sales')
        .select();

    int count = 0;

    for (final sale in sales) {
      final saleDate =
          DateTime.parse(sale['sale_date']);

      final durationDays =
          sale['duration_days'] as int;

      final reminderDate =
          saleDate.add(
        Duration(days: durationDays),
      );

      final daysLeft =
          reminderDate
              .difference(DateTime.now())
              .inDays;

      if (daysLeft <= 3 && daysLeft >= 0) {
        count++;
      }
    }

    return count;
  }
 
  Future<List<Map<String, dynamic>>> getSalesByClient(
    String clientId,
  ) async {
    final response = await supabase
        .from('sales')
        .select('''
          *,
          products!fk_sales_product(*)
        ''')
        .eq('client_id', clientId)
        .order(
          'sale_date',
          ascending: false,
        );

    return List<Map<String, dynamic>>.from(
      response,
    );
  }

  Future<double> getNextMonthProjection() async {
    final sales = await supabase
        .from('sales')
        .select('''
          quantity,
          sale_date,
          duration_days,
          products!fk_sales_product(price)
        ''');

    final now = DateTime.now();

    final nextMonth = now.month == 12 ? 1 : now.month + 1;

    final nextYear = now.month == 12
        ? now.year + 1
        : now.year;

    double total = 0;

    for (final sale in sales) {
      final saleDate =
          DateTime.parse(sale['sale_date']);

      final reminderDate = saleDate.add(
        Duration(
          days: sale['duration_days'],
        ),
      );

      if (reminderDate.month == nextMonth &&
          reminderDate.year == nextYear) {
        final preco =
            (sale['products']['price'] as num)
                .toDouble();

        final quantidade =
            sale['quantity'] as int;

        total += preco * quantidade;
      }
    }
    
    return total;
  }

  // =========================
  // METAS DO MÊS
  // =========================

  // 1. Busca quantos itens já foram vendidos no mês ATUAL
 // 1. Busca o VALOR TOTAL vendido no mês ATUAL
  Future<double> getValorVendidoMesAtual() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59).toIso8601String();

    final response = await supabase
        .from('sales')
        .select('quantity, products!fk_sales_product(price)')
        .gte('sale_date', startOfMonth)
        .lte('sale_date', endOfMonth);

    double total = 0;
    for (var row in response) {
      final qtd = (row['quantity'] as num).toInt();
      final preco = (row['products']['price'] as num).toDouble();
      total += (qtd * preco);
    }
    return total;
  }

  // 2. Busca a Meta Financeira (manual ou total do mês passado)
  Future<double> getMetaFinanceiraDoMes() async {
    final now = DateTime.now();
    final mesAnoAtual = "${now.month.toString().padLeft(2, '0')}/${now.year}";

    final manual = await supabase
        .from('metas_manuais')
        .select('meta_valor') // Mude a coluna no seu banco se necessário
        .eq('mes_ano', mesAnoAtual)
        .maybeSingle();

    if (manual != null) {
      return (manual['meta_valor'] as num).toDouble();
    }

    final startOfLastMonth = DateTime(now.year, now.month - 1, 1).toIso8601String();
    final endOfLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59).toIso8601String();

    final response = await supabase
        .from('sales')
        .select('quantity, products!fk_sales_product(price)')
        .gte('sale_date', startOfLastMonth)
        .lte('sale_date', endOfLastMonth);

    double totalMesPassado = 0;
    for (var row in response) {
      final qtd = (row['quantity'] as num).toInt();
      final preco = (row['products']['price'] as num).toDouble();
      totalMesPassado += (qtd * preco);
    }

    return totalMesPassado > 0 ? totalMesPassado : 1000.0; // Meta padrão R$ 1000
  }

  // 3. Salva uma nova meta financeira manual
    Future<void> salvarMetaFinanceiraManual(double novaMeta) async {
        final now = DateTime.now();
        final mesAnoAtual = "${now.month.toString().padLeft(2, '0')}/${now.year}";

        try {
          await supabase.from('metas_manuais').upsert({
            'mes_ano': mesAnoAtual,
            'meta_valor': novaMeta,
          }, onConflict: 'mes_ano');
        } catch (e) {
          print("Erro ao salvar meta: $e");
          rethrow; // Isso ajuda a ver o erro no console do Flutter
        }
      }
    Future<void> updateSale({
      required String id, // Altere de int para String
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
          .eq('id', id); // Agora o id é String e vai bater com o UUID do Supabase
    }
      // Função para apagar um Produto
    Future<void> deleteProduct(String id) async {
      await supabase.from('products').delete().eq('id', id);
    }

    // Função para apagar um Cliente
    Future<void> deleteClient(String id) async {
      await supabase.from('clients').delete().eq('id', id);
    }
    // Adicione este método dentro da classe SupabaseService
    Future<List<Map<String, dynamic>>> getClientsWithSales() async {
      // .select('*, sales(*)') diz ao Supabase: 
      // "Me traga todos os clientes e todas as vendas relacionadas a eles"
      return await supabase
          .from('clients')
          .select('*, sales(*)');
    }
      
}