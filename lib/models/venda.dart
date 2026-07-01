import 'clientes.dart';
import 'produtos.dart'; 

class Venda {
  final int quantidade;
  final Client cliente;
  final Product produto;
  final DateTime dataVenda;
  final Duration duracao;

  Venda({
    required this.quantidade,
    required this.cliente,
    required this.produto,
    required this.dataVenda,
    required this.duracao,
  });

  double get valorTotal => quantidade * produto.price;

}
