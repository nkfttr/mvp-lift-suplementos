import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provedor.dart';
import 'providers/theme_provider.dart';
import 'screens/tela_principal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qxdneklvjnpxehvfordf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF4ZG5la2x2am5weGVodmZvcmRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MjU0ODIsImV4cCI6MjA5NDIwMTQ4Mn0.pCQrlPNhZPXeKL3XJMVlkbvC0jlabiHBWpp7VMUmDrE',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {

        return MaterialApp(
          debugShowCheckedModeBanner: false,

          title: 'Lift Suplementos MVP',

          themeMode: themeProvider.themeMode,

          theme: ThemeData(
            brightness: Brightness.light,
            colorSchemeSeed: Colors.deepPurple,
          ),

          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.deepPurple,
          ),

          home: const MainScreen(),
        );
      },
    );
  }
}