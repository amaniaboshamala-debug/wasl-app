import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wasl/app.dart';
import 'package:wasl/core/config/env.dart';
import 'package:wasl/core/di/injection.dart';
import 'package:wasl/core/storage/local_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Env.check();
  await Hive.initFlutter();
  await LocalCache.init();
  await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabaseAnonKey);
  await initDependencies();

  runApp(const WaslApp());
}
