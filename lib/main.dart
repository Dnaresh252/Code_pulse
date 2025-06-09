import 'package:code_assistant/screens/login_screen.dart';
import 'package:code_assistant/screens/profile_screen.dart';
import 'package:code_assistant/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // auto-generated
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Coding Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF1E1E2E),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF2E2E4E),
          elevation: 0,
        ),
      ),
      home: HomeScreen()
    );
  }
}
