
import 'package:flutter/material.dart';
import '../models/produtos.dart';
import '../models/clientes.dart';
import '../models/lembretes.dart';
import '../models/venda.dart';


class AppProvider extends ChangeNotifier {
  final List<Product> products = [];
  final List<Client> clientes = [];
  final List<Lembrete> lembretes = [];
  final List<Venda> vendas = [];

  void addProduct(Product product) {
    products.add(product);
    notifyListeners();
  }
    void addClient(Client client) {
    clientes.add(client);
    notifyListeners();
  }
   void addLembrete(Lembrete lembrete) {
    lembretes.add(lembrete);
    notifyListeners();
   }
   void addVenda(Venda venda) {
    // Aqui você pode adicionar a venda a uma lista de vendas, se necessário
    // Por exemplo: vendas.add(venda); (comentario gerado com o auxilio do vscode)
    vendas.add(venda);
    notifyListeners();
   }
   void updateProduct(Product updatedProduct) {
  final index = products.indexWhere(
    (p) => p.id == updatedProduct.id,
  );

  if (index != -1) {
    products[index] = updatedProduct;
    notifyListeners();
  }
  }

  void updateClient(Client updatedClient) {
    final index = clientes.indexWhere(
      (c) => c.id == updatedClient.id,
    );

    if (index != -1) {
      clientes[index] = updatedClient;
      notifyListeners();
    }
  }


}
