import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'pages/page_accueil.dart';
import 'pages/page_navigation.dart';
import 'pages/page_authentification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<User?>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    // Delay listening to auth state changes to ensure Firebase connection is fully established
    Future.delayed(const Duration(milliseconds: 500), () {
      _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((
        User? user,
      ) {
        print("Auth state changed: user = ${user?.uid ?? 'null'}");
        // Force refresh app state
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Chti Face Bouc',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Print auth state info for debugging
          print(
            "StreamBuilder: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}",
          );

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text("Loading application..."),
                  ],
                ),
              ),
            );
          }

          // Add a brief delay to ensure Firebase connection is fully established
          if (snapshot.hasData) {
            // User is logged in, show navigation page
            return FutureBuilder(
              future: Future.delayed(const Duration(milliseconds: 300)),
              builder: (context, _) => const PageNavigation(),
            );
          } else {
            // User is not logged in, show authentication page
            return const PageAuthentification();
          }
        },
      ),
    );
  }
}
