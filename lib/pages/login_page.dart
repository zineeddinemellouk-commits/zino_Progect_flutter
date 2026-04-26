import 'package:flutter/material.dart';

/// Legacy compatibility shim.
///
/// The real login UI now lives in `main.dart` as `HodooriLoginScreen`.
/// This widget stays around so older routes/imports do not break.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _redirected = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_redirected) return;
    _redirected = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute != '/login') {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8F9FB),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
