// ignore_for_file: deprecated_member_use
// ========================================
// Application Entry Point
// Boots Firebase, Supabase, localization,
// notifications, and the authenticated app shell.
// ========================================
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:google_fonts/google_fonts.dart';

import 'package:test/firebase_options.dart';
import 'package:test/core/constants/app_user_profile.dart';
import 'package:test/core/providers/locale_provider.dart';
import 'package:test/services/localization_service.dart';
import 'package:test/services/absence_notification_service.dart';
import 'package:test/services/push_notification_service.dart';
import 'package:test/features/auth/screens/login_screen.dart';
import 'package:test/core/widgets/restart_widget.dart';

// Feature imports
import 'package:test/features/students/screens/view_students_screen.dart';
import 'package:test/features/departments/screens/groups_screen.dart';
import 'package:test/features/students/providers/student_management_provider.dart';
import 'package:test/features/students/screens/students_screen.dart';
import 'package:test/features/teachers/presentation/pages/teacher_profile_page.dart';
import 'package:test/features/students/presentation/pages/students_page.dart';
import 'package:test/features/dashboard/screens/department_dashboard.dart' show DepartmentDashboard;
import 'package:test/features/roles/screens/role_home_screen.dart';
import 'package:test/services/department_auth_service.dart';
import 'package:test/features/departments/screens/department_settings_screen.dart';

// Initializes all platform services before the UI is rendered.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ybpmzffutavfwcbfkjcq.supabase.co', // ← PASTE YOUR URL HERE
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlicG16ZmZ1dGF2ZndjYmZramNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1MTYyMTMsImV4cCI6MjA5MjA5MjIxM30.7wB2kJww59dpgU751hzIyGE4R0SPPwatcH6Hx34fflU', // ← PASTE YOUR ANON KEY HERE
  );

  // Initialize localization service
  await LocalizationService.init();

  // Initialize notification service
  await AbsenceNotificationService().initialize();
  await PushNotificationService().initialize();

  runApp(
    RestartWidget(
      child: const MyApp(),
    ),
  );
}

// Resolves the first screen shown after the user profile is loaded.
Widget _destinationForProfile(AppUserProfile profile) {
  if (profile.role == 'Department') return const DepartmentDashboard();
  if (profile.role == 'Student') {
    return StudentsPage(
      selfViewOnly: true,
      studentDocumentId: profile.linkedDocumentId,
      studentEmail: profile.email,
    );
  }
  if (profile.role == 'Teacher') {
    return TeacherProfilePage(
      teacherId: profile.linkedDocumentId,
      teacherEmail: profile.email,
    );
  }
  return RoleHomePage(
    role: profile.role,
    email: profile.email,
    displayName: profile.displayName,
  );
}

// Root widget that wires providers, theming, localization, and routing.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StudentManagementProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Hodoori - Smart Attendance',
          // FIXED: Changed font from Inter to Poppins with Cairo fallback for Arabic
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: localeProvider.isRtl ? 'Cairo' : 'Poppins',
            textTheme: localeProvider.isRtl
                ? GoogleFonts.cairoTextTheme()
                : GoogleFonts.poppinsTextTheme(),
            brightness: Brightness.light,
          ),
          locale: localeProvider.currentLocale,
          supportedLocales: LocaleProvider.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) {
              return supportedLocales.first;
            }
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first;          },
          builder: (context, child) {
            return Directionality(
              textDirection: localeProvider.isRtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: child ?? const SizedBox(),
            );
          },
          home: const _StartupGate(),
          routes: {
            '/login': (_) => const HodooriLoginScreen(),
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
      ),
    );
  }
}

// Auth/session gate that chooses the correct landing screen.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

// Listens to Firebase and Supabase auth state changes and resolves the
// linked user profile before routing to the correct role-based screen.
class _StartupGateState extends State<_StartupGate> {
  StreamSubscription<User?>? _firebaseSubscription;
  StreamSubscription<AuthState>? _supabaseSubscription;
  Future<AppUserProfile?>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _syncSession();
    _firebaseSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (_) => _syncSession(),
    );
    _supabaseSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((_) => _syncSession());
  }

  @override
  void dispose() {
    _firebaseSubscription?.cancel();
    _supabaseSubscription?.cancel();
    super.dispose();
  }

  void _syncSession() {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final uid = session?.user.id ?? firebaseUser?.uid;

    if (!mounted) return;

    if (uid == null || uid.trim().isEmpty) {
      setState(() {
        _profileFuture = null;
      });
      return;
    }

    final normalizedUid = uid.trim();
    setState(() {
      _profileFuture = Future.delayed(
        const Duration(milliseconds: 300),
        () => DepartmentAuthService().getUserProfileByUid(normalizedUid),
      );
    });

    unawaited(PushNotificationService().registerCurrentUserToken());
  }

  Future<AppUserProfile?> _resolveProfile() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    final firebaseUser = FirebaseAuth.instance.currentUser;

    final uid = session?.user.id ?? firebaseUser?.uid;
    if (uid == null || uid.trim().isEmpty) {
      return null;
    }

    return DepartmentAuthService().getUserProfileByUid(uid);
  }

  @override
  Widget build(BuildContext context) {
    final supabaseSession = Supabase.instance.client.auth.currentSession;
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (supabaseSession == null && firebaseUser == null) {
      return const HodooriLoginScreen();
    }

    final future = _profileFuture ?? _resolveProfile();

    return FutureBuilder<AppUserProfile?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF3B82F6),
              ),
            ),
          );
        }

        final profile = snapshot.data;
        if (profile == null) {
          return const HodooriLoginScreen();
        }

        return _destinationForProfile(profile);
      },
    );
  }
}
