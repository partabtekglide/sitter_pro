import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './routes/app_routes.dart';
import './services/supabase_service.dart';
import './theme/app_theme.dart';
import 'core/app_export.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase - single initialization
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '', 
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Initialize our service wrapper
  SupabaseService.initialize();

  runApp(const SitterProManagerApp());
}

class SitterProManagerApp extends StatefulWidget {
  const SitterProManagerApp({super.key});

  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.system);

  @override
  State<SitterProManagerApp> createState() => _SitterProManagerAppState();
}

class _SitterProManagerAppState extends State<SitterProManagerApp> {
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: SitterProManagerApp.themeNotifier,
          builder: (_, ThemeMode currentMode, __) {
            return MaterialApp(
              title: 'Sitter Pro Manager',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: currentMode,
              initialRoute: AppRoutes.initial,
              routes: AppRoutes.routes,
              navigatorObservers: [routeObserver],
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.0)),
                  child: child!,
                );
              },
            );
          },
        );
      },
    );
  }
}
