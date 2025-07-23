import 'package:flutter/material.dart';
import 'package:login_fin/login_screen.dart';  // 로그인 페이지 임포트
import 'package:firebase_core/firebase_core.dart';
import 'package:login_fin/SignUpPage.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '지갑을 부탁해',
      initialRoute: LoginPageWidget.routePath,  // 로그인 페이지를 초기화면으로 지정
      routes: {
        LoginPageWidget.routePath: (context) => const LoginPageWidget(),
        '/signup': (context) => const SignUpPage(), // 가입 페이지
        // '/home': (context) => const HomePage(), // 로그인 후 메인 페이지. 이후에 추가 바람.
      },
      theme: ThemeData(
        primaryColor: const Color(0xFF2797FF),
      ),
    );
  }
}
