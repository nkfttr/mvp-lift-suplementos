import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provedor.dart';
import '../models/lembretes.dart';
import 'dart:math';

class AddLembreteScreen extends StatefulWidget {
  const AddLembreteScreen({super.key});
  
  @override
  State<AddLembreteScreen> createState() => _AddLembreteScreenState();
}

class _AddLembreteScreenState extends State<AddLembreteScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final durationController = TextEditingController();
  
  void save() {
    final name = nameController.text;
    final description = descriptionController.text;
    final duration = int.tryParse(durationController.text) ?? 0;

    if (name.isEmpty || description.isEmpty || duration <= 0) return;

    final lembrete = Lembrete(
      id: Random().toString(),
      name: name,
      description: description,
      durationDays: duration,
    );

    Provider.of<AppProvider>(context, listen: false).addLembrete(lembrete);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Adicionar Lembrete")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nome"),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Descriçao"),
            ),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Duração (dias)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: save, child: const Text("Salver Lembrete")),
          ],
        ),
      ),
    );
  }
}