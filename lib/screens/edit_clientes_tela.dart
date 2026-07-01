
import 'package:flutter/material.dart';

import '../models/clientes.dart';
import '../services/supabase_service.dart';

class EditClientScreen extends StatefulWidget {
  final Client client;

  const EditClientScreen({
    super.key,
    required this.client,
  });

  @override
  State<EditClientScreen> createState() =>
      _EditClientScreenState();
}

class _EditClientScreenState
    extends State<EditClientScreen> {

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController addressController;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.client.name,
    );

    phoneController = TextEditingController(
      text: widget.client.phone,
    );

    addressController = TextEditingController(
      text: widget.client.address ?? '',
    );
  }

  Future<void> save() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nome e telefone são obrigatórios.',
          ),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await SupabaseService().updateClient(
        id: widget.client.id,
        name: name,
        phone: phone,
        address: addressController.text.trim().isEmpty
            ? null
            : addressController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cliente atualizado com sucesso!',
            ),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao atualizar cliente: $e',
            ),
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
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Cliente"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nome",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Telefone",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: "Endereço (opcional)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : save,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Salvar Alterações",
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

