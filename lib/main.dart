import 'package:flutter/material.dart';
import 'package:save_wallet/screens/home_screen.dart';
import 'package:save_wallet/screens/login_screen.dart';  // 로그인 페이지 임포트
import 'package:firebase_core/firebase_core.dart';
import 'package:save_wallet/screens/SignUpPage.dart';
import 'package:save_wallet/services/firebase_options.dart';
import 'package:save_wallet/screens/community_screen.dart';
import 'package:save_wallet/screens/statistics_screen.dart';

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
        SignUpPage.routePath: (context) => const SignUpPage(), // 가입 페이지
        HomePageScreen.routePath: (context) => const HomePageScreen(), // 로그인 후 메인 페이지
        CommunityScreen.routePath: (context) => const CommunityScreen(), // 커뮤니티
        // StatisticsScreen.routePath: (context) => const StatisticsScreen(), // 통계 페이지 (완성 후 추가)

      },
      theme: ThemeData(
        primaryColor: const Color(0xFF2797FF),
      ),
    );
  }
}
