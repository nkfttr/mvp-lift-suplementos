class Client {
  final String id;
  final String name;
  final String phone;
  final String? address; // O '?' indica que o endereço pode ser nulo

  Client({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
  });

  // O CONSTRUTOR QUE FALTAVA PARA O PRIMEIRO ERRO:
  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id']?.toString() ?? '',
      // O '??' resolve o segundo erro: se o nome vier nulo, ele assume um valor padrão
      name: map['name']?.toString() ?? 'Sem Nome',
      phone: map['phone']?.toString() ?? '',
      address: map['address']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
    };
  }
}