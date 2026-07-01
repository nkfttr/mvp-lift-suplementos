
import 'package:flutter/material.dart';

import '../models/clientes.dart';
import '../services/supabase_service.dart';

class ClienteDetalhesTela extends StatefulWidget {
  final Client client;

  const ClienteDetalhesTela({
    super.key,
    required this.client,
  });

  @override
  State<ClienteDetalhesTela> createState() =>
      _ClienteDetalhesTelaState();
}

class _ClienteDetalhesTelaState
    extends State<ClienteDetalhesTela> {
final SupabaseService _service = SupabaseService();

late Client clienteAtual;

List<Map<String, dynamic>> clienteVendas = [];

bool loading = true;

double totalComprado = 0;

@override
void initState() {
  super.initState();

  clienteAtual = widget.client;

  carregarDados();
}

Future<void> carregarDados() async {
  try {
    loading = true;

    final clientes =
        await _service.getClients();

    final clienteMap = clientes.firstWhere(
      (c) => c['id'].toString() == widget.client.id,
    );

    clienteAtual = Client(
      id: clienteMap['id'].toString(),
      name: clienteMap['name'],
      phone: clienteMap['phone'] ?? '',
      address: clienteMap['address'],
    );

    final vendas =
        await _service.getSalesByClient(
      widget.client.id,
    );

    double total = 0;

    for (final venda in vendas) {
      total +=
          (venda['quantity'] as int) *
          (venda['products']['price'] as num)
              .toDouble();
    }

    if (mounted) {
      setState(() {
        clienteVendas = vendas;
        totalComprado = total;
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
          content: Text(
            'Erro ao carregar dados: $e',
          ),
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
        title: Text(widget.client.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              clienteAtual.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(clienteAtual.phone),

            const SizedBox(height: 4),

            Text(
              clienteAtual.address ?? 'Endereço não informado',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Compras:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Total comprado: "
              "R\$ ${totalComprado.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : clienteVendas.isEmpty
                      ? const Center(
                          child: Text(
                            "Nenhuma compra realizada.",
                          ),
                        )
                      : ListView.builder(
                          itemCount:
                              clienteVendas.length,
                          itemBuilder: (_, index) {
                            final venda =
                                clienteVendas[index];

                            final quantidade =
                                venda['quantity']
                                    as int;

                            final produto =
                                venda['products']
                                    ['name'];

                            final preco =
                                (venda['products']
                                            ['price']
                                        as num)
                                    .toDouble();

                            final total =
                                quantidade * preco;

                            final data =
                                DateTime.parse(
                              venda['sale_date'],
                            );

                            return Card(
                              margin:
                                  const EdgeInsets.only(
                                bottom: 12,
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons
                                      .shopping_cart,
                                ),

                                title: Text(
                                  produto,
                                ),

                                subtitle: Text(
                                  "Quantidade: "
                                  "$quantidade"
                                  " • Total: "
                                  "R\$ ${total.toStringAsFixed(2)}"
                                  "\nDuração: "
                                  "${venda['duration_days']} dias",
                                ),

                                trailing: Text(
                                  formatarData(
                                    data,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

