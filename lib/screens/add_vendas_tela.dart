import 'package:flutter/material.dart';

import '../models/clientes.dart';
import '../models/produtos.dart';
import '../models/venda.dart';
import '../services/supabase_service.dart';
import '../services/fiscal_service.dart'; //  interface
import '../services/mock_fiscal_service.dart'; //  Mock
import '../utils/pdf_helper.dart';

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

  // Instância do serviço fiscal
  final FiscalService _fiscalService = MockFiscalService();

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
          content: Text("Preencha todos os campos corretamente"),
        ),
      );
      return;
    }

    // Exibe o Loading que bloqueará a tela durante as operações
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final venda = Venda(
        quantidade: quantity,
        cliente: selectedClient!,
        produto: selectedProduct!,
        dataVenda: DateTime.now(),
        duracao: Duration(days: durationDays),
      );

      // 1. Salva no banco de dados primeiro
      await SupabaseService().addSale(
        clientId: venda.cliente.id,
        productId: venda.produto.id,
        quantity: venda.quantidade,
        durationDays: venda.duracao.inDays,
      );

      // 2. Monta os dados para a API Fiscal
      final dadosVenda = {
        'total': (selectedProduct!.price * quantity),
        'cliente': selectedClient!.name,
        'produto': selectedProduct!.name,
        'quantidade': quantity,
      };

      // 3. Chama o mock de emissão de NFC-e
      final resultadoFiscal = await _fiscalService.emitirNFCe(dadosVenda);

      // Fecha o modal de Loading
      if (mounted) Navigator.pop(context); 

      // 4. Analisa a resposta fiscal
      if (resultadoFiscal.isSuccess) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("Sucesso!"),
            content: Text("Venda salva e NFC-e emitida.\n\nChave: ${resultadoFiscal.chaveNota}"),
            actions: [
              if (resultadoFiscal.pdfUrl != null)
                TextButton(
                  onPressed: () {
                    // Chamada do método utilitário
                    PdfHelper.abrirPdf(resultadoFiscal.pdfUrl!);
                  },
                  child: const Text("Visualizar PDF"),
                ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text("Concluir"),
              ),
            ],
          ),
        );
      } else {
        // Falhou na emissão, mas a venda já foi salva no Supabase
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Venda salva, mas falha na NF: ${resultadoFiscal.errorMessage}")),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Garante que o loading feche em caso de erro no Supabase
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar venda: $e")),
        );
      }
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
                child: const Text("Salvar Venda e Emitir NF"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}