import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = false;

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  assert(
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty,
    'Faltam SUPABASE_URL e/ou SUPABASE_ANON_KEY. '
    'Rode com: flutter run -d chrome '
    '--dart-define=SUPABASE_URL=https://xxx.supabase.co '
    '--dart-define=SUPABASE_ANON_KEY=sb_publishable_xxx',
  );

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
