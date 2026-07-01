
import 'package:flutter/material.dart';
import 'produtos_tela.dart';
import 'clientes_tela.dart';
import 'lembretes_tela.dart';
import 'dashboard_tela.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 3;

  final screens = const [
    ProductsScreen(),
    ClientsScreen(),
    LembretesTela(),
    DashboardTela(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Produtos"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Clientes"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Lembretes"),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
        ],
      ),
    );
  }
}
