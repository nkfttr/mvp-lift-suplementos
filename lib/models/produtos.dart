class Product {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String? imagePath;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.imagePath,
  });

  // O CONSTRUTOR QUE FALTAVA PARA PARAR O PRIMEIRO ERRO:
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toString() ?? '',
      // O '??' garante que se o nome for nulo no banco, ele vira texto vazio e não quebra (corrige o segundo erro)
      name: map['name']?.toString() ?? 'Produto sem nome', 
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      imagePath: map['image_path']?.toString(), // Mapeia a coluna do Supabase
    );
  }

  // Se você precisar converter de volta para enviar ao Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image_path': imagePath,
    };
  }
}