// ignore_for_file: deprecated_member_use

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test/firebase_options.dart';
import 'package:test/services/role_manager.dart';
import 'package:test/services/auth_service.dart';
import 'package:test/pages/protected_dashboards.dart';
import 'package:test/pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // RoleManager - maintains current user's role
        // This is a ChangeNotifier, so UI rebuilds when role changes
        ChangeNotifierProvider(
          create: (_) => RoleManager(),
        ),

        // AuthService - handles authentication operations
        Provider(
          create: (_) => AuthService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Hodoori - Smart Attendance',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Inter',
          brightness: Brightness.light,
          primarySwatch: Colors.blue,
        ),
        // Home determines the initial route based on auth state
        home: const _AuthGate(),
        // Named routes for protected navigation
        routes: {
          '/login': (_) => const LoginPage(),
          '/student-dashboard': (_) => const StudentDashboard(),
          '/teacher-dashboard': (_) => const TeacherDashboard(),
          '/department-dashboard': (_) => const DepartmentDashboard(),
        },
        // Fallback for any undefined routes
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Route Not Found')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Route not found: ${settings.name}'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      ),
                      child: const Text('Go to Login'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Auth gate - determines if user is logged in and has role
/// Shows login or dashboard based on auth state and role
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late Stream<User?> _authStateStream;

  @override
  void initState() {
    super.initState();
    _authStateStream = FirebaseAuth.instance.authStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        // Still checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        // No user logged in
        if (snapshot.data == null) {
          // Clear role when user logs out
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<RoleManager>().clearRole();
            }
          });
          return const LoginPage();
        }

        // User is logged in - show the role-aware router
        return const _RoleAwareRouter();
      },
    );
  }
}

/// Router that shows appropriate dashboard based on user role
class _RoleAwareRouter extends StatefulWidget {
  const _RoleAwareRouter();

  @override
  State<_RoleAwareRouter> createState() => _RoleAwareRouterState();
}

class _RoleAwareRouterState extends State<_RoleAwareRouter> {
  @override
  void initState() {
    super.initState();
    // Initialize role from Firestore when user logs in
    _initializeRole();
  }

  Future<void> _initializeRole() async {
    try {
      final roleManager = context.read<RoleManager>();
      await roleManager.initializeFromFirestore();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load user role: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoleManager>(
      builder: (context, roleManager, _) {
        // Role not yet initialized
        if (!roleManager.isInitialized) {
          return const _LoadingScreen();
        }

        // Role initialization failed
        if (roleManager.error != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 60, color: Colors.red),
                  const SizedBox(height: 20),
                  const Text('Failed to initialize user role'),
                  const SizedBox(height: 10),
                  Text(roleManager.error ?? '', textAlign: TextAlign.center),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () async {
                      await context.read<AuthService>().logout(
                        roleManager: roleManager,
                      );
                      if (mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      }
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          );
        }

        // Route to appropriate dashboard based on role
        return _getDashboardForRole(roleManager.currentRole);
      },
    );
  }

  Widget _getDashboardForRole(UserRole? role) {
    switch (role) {
      case UserRole.student:
        return const StudentDashboard();
      case UserRole.teacher:
        return const TeacherDashboard();
      case UserRole.department:
        return const DepartmentDashboard();
      case UserRole.unknown:
      case null:
        return Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 60, color: Colors.red),
                const SizedBox(height: 20),
                const Text('Unknown user role'),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    await context.read<AuthService>().logout(
                      roleManager: context.read<RoleManager>(),
                    );
                    if (mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('Logout and try again'),
                ),
              ],
            ),
          ),
        );
    }
  }
}

/// Loading screen shown while initializing
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Initializing...'),
          ],
        ),
      ),
    );
  }
}
