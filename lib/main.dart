import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/firebase_options.dart';
import 'pages/login_page.dart';
import 'package:test/pages/departement/ViewStudent.dart';
import 'package:test/pages/departement/groups_screen.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';
import 'package:test/pages/departement/students_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (error) {
    runApp(FirebaseInitErrorApp(error: error.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudentManagementProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ScholarFlow Pro',
        theme: ThemeData(fontFamily: 'Inter'),
        home: const LoginPage(),
        routes: {ViewStudent.routeName: (_) => const ViewStudent()},
        onGenerateRoute: (settings) {
          if (settings.name == GroupsScreen.routeName) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const GroupsScreen(),
            );
          }

          if (settings.name == StudentsScreen.routeName) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const StudentsScreen(),
            );
          }

          return null;
        },
      ),
    );
  }
}

class FirebaseInitErrorApp extends StatelessWidget {
  const FirebaseInitErrorApp({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 42),
                const SizedBox(height: 12),
                const Text(
                  'Firebase initialization failed.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
