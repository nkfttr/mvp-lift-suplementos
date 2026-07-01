
import 'package:flutter/material.dart';

import '../models/clientes.dart';
import '../models/produtos.dart';
import '../models/venda.dart';
import '../services/supabase_service.dart';

class AddVendasTela extends StatefulWidget {
  const AddVendasTela({super.key});

  @override
  State<AddVendasTela> createState() => _AddVendasTelaState();
}

class _AddVendasTelaState extends State<AddVendasTela> {
  Client? selectedClient;
  Product? selectedProduct;

  final quantityController = TextEditingController(text: "1");
  final durationController = TextEditingController(text: "1");

  List<Client> clientes = [];
  List<Product> produtos = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    try {
      final supabase = SupabaseService();

      final clientesResponse = await supabase.getClients();
      final produtosResponse = await supabase.getProducts();

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao carregar dados: $e"),
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

  Future<void> save() async {
    final quantity = int.tryParse(quantityController.text) ?? 0;
    final durationDays = int.tryParse(durationController.text) ?? 0;

    if (selectedClient == null ||
        selectedProduct == null ||
        quantity <= 0 ||
        durationDays <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Preencha todos os campos corretamente",
          ),
        ),
      );
      return;
    }

    try {
      final venda = Venda(
        quantidade: quantity,
        cliente: selectedClient!,
        produto: selectedProduct!,
        dataVenda: DateTime.now(),
        duracao: Duration(days: durationDays),
      );

      await SupabaseService().addSale(
        clientId: venda.cliente.id,
        productId: venda.produto.id,
        quantity: venda.quantidade,
        durationDays: venda.duracao.inDays,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Venda salva com sucesso!"),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao salvar venda: $e"),
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
        title: const Text("Adicionar Venda"),
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
              child: ElevatedButton(
                onPressed: save,
                child: const Text("Salvar Venda"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

