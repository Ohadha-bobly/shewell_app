import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  // Guard the entire async startup so uncaught errors are logged clearly.
  runZonedGuarded<Future<void>>(
    () async {
      // Ensure bindings and error handlers are initialized inside the same zone
      // that will later call `runApp` to avoid Zone mismatch errors.
      WidgetsFlutterBinding.ensureInitialized();

      // Forward Flutter framework errors to the console so they appear in terminal
      // and browser DevTools.
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        // Print to make sure the flutter tool captures it.
        debugPrint('FlutterError: ${details.exceptionAsString()}');
        debugPrintStack(stackTrace: details.stack);
      };

      // Now perform async startup work

      const supabaseUrl = String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://nzabmhqaagsfahhrahsb.supabase.co',
      );
      const supabaseAnonKey = String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56YWJtaHFhYWdzZmFoaHJhaHNiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMxMDg5NzIsImV4cCI6MjA3ODY4NDk3Mn0.ZmIWEqUorlBsQMnDWgEKVSZh4ofPiXTfUjyvURyqrJU',
      );

      debugPrint('Starting Supabase.initialize');
      try {
        await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
        debugPrint('Supabase initialized');
      } catch (e, st) {
        debugPrint('Supabase.initialize failed: $e');
        debugPrintStack(stackTrace: st);
        rethrow;
      }

      debugPrint('Starting ThemeService.init');
      try {
        await ThemeService.init();
        debugPrint('ThemeService initialized');
      } catch (e, st) {
        debugPrint('ThemeService.init failed: $e');
        debugPrintStack(stackTrace: st);
        rethrow;
      }

      runApp(const MyApp());
    },
    (Object error, StackTrace stack) {
      // This will catch any uncaught synchronous or async errors during startup
      // and print them so they show up in terminal and browser console.
      debugPrint('Uncaught startup error: $error');
      debugPrintStack(stackTrace: stack);
      if (!kReleaseMode) {
        // Rethrow in non-release modes to make the failure obvious when running
        // locally. In release builds you might want to report this to a logging
        // service instead.
        // ignore: only_throw_errors
        throw error;
      }
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppTheme _currentTheme;

  @override
  void initState() {
    super.initState();
    _currentTheme = ThemeService.getTheme();
  }

  @override
  Widget build(BuildContext context) {
    return DeferredInputs(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SheWell',
        theme: ThemeService.getThemeData(_currentTheme),
        home: const AuthGate(),
      ),
    );
  }
}

/// A small wrapper that defers rendering the real app for one frame on Web.
///
/// This reduces Flutter Web text-input DOM races ("DOM element not active")
/// by ensuring the first frame finishes before the app builds interactive
/// TextFields. On non-web platforms this is a no-op.
class DeferredInputs extends StatefulWidget {
  final Widget child;
  const DeferredInputs({super.key, required this.child});

  @override
  State<DeferredInputs> createState() => _DeferredInputsState();
}

class _DeferredInputsState extends State<DeferredInputs> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // Only defer on web where the engine occasionally throws the text-editing
    // DOM assertion. On other platforms render immediately.
    if (!kIsWeb) {
      _ready = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _ready = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;
    // Show a single blank frame (or small loader) while deferring interactive
    // text inputs. This typically lasts one frame and avoids the DOM race.
    return const SizedBox.shrink();
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = Supabase.instance.client.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data!.session;

        if (session == null) {
          return const LoginScreen();
        }

        return const HomeScreen();
      },
    );
  }
}
