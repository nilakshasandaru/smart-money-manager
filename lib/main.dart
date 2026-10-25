import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/money_database.dart';
import 'screens/shell_screen.dart';
import 'state/money_controller.dart';
import 'utils/money_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = MoneyController(MoneyDatabase());
  try {
    await controller.initialize();
    runApp(ChangeNotifierProvider.value(
      value: controller,
      child: const SmartMoneyApp(),
    ));
  } catch (error) {
    runApp(MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: redColor),
                  const SizedBox(height: 16),
                  const Text('Could not open local database',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('$error', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(onPressed: () => main(), child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

class SmartMoneyApp extends StatelessWidget {
  const SmartMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandBlue,
      primary: brandBlue,
      secondary: deepBlue,
      surface: Colors.white,
    );
    return MaterialApp(
      title: 'Smart Money Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: backgroundColor,
          foregroundColor: Color(0xFF152945),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF152945),
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFDCE5F3))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFDCE5F3))),
        ),
      ),
      home: const ShellScreen(),
    );
  }
}
