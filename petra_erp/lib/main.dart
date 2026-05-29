import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa dados de formatação de data para pt-BR (intl/table_calendar).
  await initializeDateFormatting('pt_BR', null);

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Validate in all build modes (asserts are stripped from release builds).
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    runApp(const _ConfigErrorApp());
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: PetraApp(),
    ),
  );
}

/// Shown when Supabase credentials are missing, so the app fails with a clear
/// message instead of crashing obscurely inside Supabase.initialize.
class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Configuração ausente: defina SUPABASE_URL e SUPABASE_ANON_KEY.\n\n'
              'Rode com:\n'
              'flutter run -d chrome '
              '--dart-define=SUPABASE_URL=https://xxx.supabase.co '
              '--dart-define=SUPABASE_ANON_KEY=sb_publishable_xxx',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
