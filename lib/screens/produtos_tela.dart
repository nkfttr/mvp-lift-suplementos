import 'package:flutter/material.dart';

import '../models/produtos.dart';
import '../services/supabase_service.dart';

import 'add_produtos_tela.dart';
import 'edit_produto_tela.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String search = "";

  final supabaseService = SupabaseService();

  // FUNÇÃO AUXILIAR PARA EXIBIR A IMAGEM COM SEGURANÇA
  Widget _buildProductImage(String? imagePath) {
    const double size = 50.0;
    
    // Tratamento para links nulos, vazios ou blob temporários antigos
    if (imagePath == null || imagePath.trim().isEmpty || imagePath.startsWith('blob:')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 24),
      );
    }

    // Tenta carregar a imagem da internet de forma segura
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Caso o link quebre ou fique offline, renderiza um fallback em vez de travar o app
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.broken_image, color: Colors.grey, size: 24),
          );
        },
        // Mostra um indicador de carregamento leve enquanto baixa a imagem
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            color: Colors.grey[100],
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Produtos📦",
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Pesquisar produto...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  search = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: supabaseService.getProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Erro ao carregar: ${snapshot.error}"),
                    );
                  }

                  final data = snapshot.data ?? [];

                  if (data.isEmpty) {
                    return const Center(
                      child: Text("Nenhum produto cadastrado"),
                    );
                  }

                  // Transforma os dados em instâncias do modelo
                  final products = data.map((map) {
                    return Product.fromMap(map);
                  }).toList();

                  // Filtra com base no campo de pesquisa
                  final filteredProducts = products.where((product) {
                    return product.name
                        .toLowerCase()
                        .contains(search.toLowerCase());
                  }).toList();

                  if (filteredProducts.isEmpty) {
                    return const Center(
                      child: Text("Nenhum produto encontrado"),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProductScreen(product: product),
                          ),
                        ).then((_) {
                          setState(() {});
                        });
                      },
                      leading: _buildProductImage(product.imagePath),
                      title: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "R\$ ${product.price.toStringAsFixed(2)}\n"
                        "📦 ${product.quantity} unidades",
                      ),
                      isThreeLine: true,
                      
                      // ---> ADICIONE ESTE BLOCO TRAILING AQUI <---
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          // 1. Mostra caixa de confirmação
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Apagar Produto?"),
                              content: Text("Tem a certeza que deseja apagar '${product.name}'?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Cancelar"),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text("Apagar", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          // 2. Se o utilizador confirmar, tenta apagar
                          if (confirm == true) {
                            try {
                              await supabaseService.deleteProduct(product.id);
                              setState(() {}); // Recarrega a lista
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Produto apagado com sucesso!"), backgroundColor: Colors.green),
                                );
                              }
                            } catch (e) {
                              // 3. Tratamento de erro caso o produto já tenha vendas registadas
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Não é possível apagar: Este produto já está associado a vendas/lembretes."),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddProductScreen(),
            ),
          );

          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}