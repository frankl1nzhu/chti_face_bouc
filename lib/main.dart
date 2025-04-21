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
    // 延迟监听认证状态变化，确保Firebase连接完全建立
    Future.delayed(const Duration(milliseconds: 500), () {
      _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((
        User? user,
      ) {
        print("Auth state changed: user = ${user?.uid ?? 'null'}");
        // 强制刷新应用状态
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
      ), // ThemeData
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 打印认证状态信息以便调试
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
                    Text("Chargement de l'application..."),
                  ],
                ),
              ),
            );
          }

          // 添加短暂延迟以确保Firebase连接完全建立
          if (snapshot.hasData) {
            // 用户已登录，显示导航页面
            return FutureBuilder(
              future: Future.delayed(const Duration(milliseconds: 300)),
              builder: (context, _) => const PageNavigation(),
            );
          } else {
            // 用户未登录，显示认证页面
            return const PageAuthentification();
          }
        },
      ),
    ); // MaterialApp
  }
}
