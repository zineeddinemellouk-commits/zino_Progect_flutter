// ignore_for_file: deprecated_member_use
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/firebase_options.dart';
import 'package:test/main.dart' show HodooriLoginScreen;
import 'package:test/pages/departement/ViewStudent.dart';
import 'package:test/pages/departement/groups_screen.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';
import 'package:test/pages/departement/students_screen.dart';
import 'package:test/features/teachers/presentation/pages/teacher_profile_page.dart';
import 'package:test/features/students/presentation/pages/students_page.dart';



import 'package:test/pages/department_settings_page.dart';

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
        title: 'Hodoori - Smart Attendance',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Inter',
          brightness: Brightness.light,
        ),
        initialRoute: '/login',
        routes: {
          '/login': (_) => const HodooriLoginScreen(),
          '/': (_) => const HodooriLoginScreen(),
          ViewStudent.routeName: (_) => const ViewStudent(),
          DepartmentSettingsPage.routeName: (_) =>
              const DepartmentSettingsPage(),
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
          if (settings.name == TeacherProfilePage.routeName) {
            final args = settings.arguments as Map<String, String>?;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => TeacherProfilePage(
                teacherId: args?['teacherId'],
                teacherEmail: args?['teacherEmail'],
              ),
            );
          }
          if (settings.name == StudentsPage.routeName) {
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => StudentsPage(
                studentDocumentId: args?['studentDocumentId'] as String?,
                studentEmail: args?['studentEmail'] as String?,
                selfViewOnly: args?['selfViewOnly'] as bool? ?? false,
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
