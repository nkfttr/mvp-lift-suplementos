import 'package:flutter/material.dart';
import '../models/produtos.dart';
import '../services/supabase_service.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({
    super.key,
    required this.product,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _service = SupabaseService();

  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController quantityController;
  // NOVO: Controller para a URL da imagem
  late TextEditingController imageUrlController; 

  bool loading = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.product.name);
    priceController = TextEditingController(text: widget.product.price.toString());
    quantityController = TextEditingController(text: widget.product.quantity.toString());
    // Inicializa o controller com a URL da imagem que já está salva no banco
    imageUrlController = TextEditingController(text: widget.product.imagePath ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text) ?? 0;
    final quantity = int.tryParse(quantityController.text) ?? 0;
    final imageUrl = imageUrlController.text.trim();

    if (name.isEmpty || price <= 0 || quantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, preencha todos os campos corretamente."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      // CORRIGIDO: Agora chama diretamente o SupabaseService para persistir a alteração
      await _service.updateProduct(
        id: widget.product.id,
        name: name,
        price: price,
        quantity: quantity,
        imagePath: imageUrl.isEmpty ? null : imageUrl, // Atualiza a URL
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Produto atualizado com sucesso! 🎉"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retorna sinalizando que houve alteração
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao atualizar produto: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Editar Produto",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 139, 71, 68),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // CARD PREVIEW VISUAL DA IMAGEM ATUALIZADA EM TEMPO REAL
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: imageUrlController,
                      builder: (context, value, child) {
                        final url = value.text.trim();
                        if (url.isEmpty || url.startsWith('blob:')) {
                          return const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.link, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                "Sem imagem (Insira uma URL válida abaixo)",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text(
                                  "URL de imagem inválida ou inacessível",
                                  style: TextStyle(color: Colors.red),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // CAMPO PARA EDITAR A URL DA IMAGEM
                  TextField(
                    controller: imageUrlController,
                    decoration: const InputDecoration(
                      labelText: "URL da Imagem do Produto",
                      hintText: "https://exemplo.com/foto-produto.jpg",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.image),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Nome",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_bag),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Preço (R\$)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Quantidade em Estoque",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.analytics),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 139, 71, 68),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Salvar Alterações",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}