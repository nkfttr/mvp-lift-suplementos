import 'package:flutter/material.dart';

import '../models/clientes.dart';
import '../models/produtos.dart';
import '../services/supabase_service.dart';

class EditVendaTela extends StatefulWidget {
  final Map<String, dynamic> venda;

  const EditVendaTela({
    super.key,
    required this.venda,
  });

  @override
  State<EditVendaTela> createState() => _EditVendaTelaState();
}

class _EditVendaTelaState extends State<EditVendaTela> {
  Client? selectedClient;
  Product? selectedProduct;

  final quantityController = TextEditingController();
  final durationController = TextEditingController();

  List<Client> clientes = [];
  List<Product> produtos = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();

    quantityController.text =
        widget.venda['quantity'].toString();

    durationController.text =
        widget.venda['duration_days'].toString();

    carregarDados();
  }

  Future<void> carregarDados() async {
    try {
      final service = SupabaseService();

      final clientesResponse =
          await service.getClients();

      final produtosResponse =
          await service.getProducts();

      clientes = clientesResponse.map((e) {
        return Client(
          id: e['id'].toString(),
          name: e['name'],
          phone: e['phone'] ?? '',
          address: e['address'] ?? '',
        );
      }).toList();

      produtos = produtosResponse.map((e) {
        return Product(
          id: e['id'].toString(),
          name: e['name'],
          price: (e['price'] as num).toDouble(),
          quantity: e['quantity'],
          imagePath: e['image_path'],
        );
      }).toList();

      selectedClient = clientes.firstWhere(
        (c) =>
            c.id ==
            widget.venda['client_id'].toString(),
      );

      selectedProduct = produtos.firstWhere(
        (p) =>
            p.id ==
            widget.venda['product_id'].toString(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Erro ao carregar dados: $e"),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> salvarEdicao() async {
    final quantidade =
        int.tryParse(quantityController.text) ?? 0;

    final duracao =
        int.tryParse(durationController.text) ?? 0;

    if (selectedClient == null ||
        selectedProduct == null ||
        quantidade <= 0 ||
        duracao <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Preencha todos os campos."),
        ),
      );
      return;
    }

    try {
      await SupabaseService().updateSale(
        id: widget.venda['id'],
        clientId: selectedClient!.id,
        productId: selectedProduct!.id,
        quantity: quantidade,
        durationDays: duracao,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Venda atualizada com sucesso!"),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Erro ao atualizar venda: $e",
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    quantityController.dispose();
    durationController.dispose();
    super.dispose();
  }
    @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Venda"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<Client>(
              initialValue: selectedClient,
              decoration: const InputDecoration(
                labelText: "Cliente",
                border: OutlineInputBorder(),
              ),
              items: clientes.map((client) {
                return DropdownMenuItem<Client>(
                  value: client,
                  child: Text(client.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedClient = value;
                });
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<Product>(
              initialValue: selectedProduct,
              decoration: const InputDecoration(
                labelText: "Produto",
                border: OutlineInputBorder(),
              ),
              items: produtos.map((product) {
                return DropdownMenuItem<Product>(
                  value: product,
                  child: Text(
                    "${product.name} - R\$ ${product.price.toStringAsFixed(2)}",
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedProduct = value;
                });
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Quantidade",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Duração (dias)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: salvarEdicao,
                icon: const Icon(Icons.save),
                label: const Text(
                  "Salvar Alterações",
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
                label: const Text(
                  "Cancelar",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}