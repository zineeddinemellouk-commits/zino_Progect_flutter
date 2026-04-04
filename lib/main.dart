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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
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
        initialRoute: '/',
        routes: {
          '/': (_) => const LoginPage(),
          ViewStudent.routeName: (_) => const ViewStudent(),
        },
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
