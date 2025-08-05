import 'package:flutter/material.dart';
import 'package:save_wallet/services/login_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  static String routeName = 'signup_page';
  static String routePath = '/signup';

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordVerifyingController = TextEditingController();

  void _onSignUp() async {
    final check = confirmIdCheck(
      context,
      passwordController.text,
      passwordVerifyingController.text,
    );
    if (check == 1) {
      await signup(
        context,
        userIdController.text,
        passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("회원가입")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [

            const SizedBox(height: 60),

            Icon(Icons.account_circle, size: 80, color: Colors.blueAccent),

            const SizedBox(height: 16),

            Text(
                "계정을 생성하세요",
                style: Theme.of(context).textTheme.titleLarge
            ),

            const SizedBox(height: 32),

            TextFormField(
              controller: userIdController,
              decoration: const InputDecoration(
                labelText: '이메일',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: passwordVerifyingController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호 확인',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _onSignUp,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text("계정 생성"),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("← 로그인 화면으로 돌아가기"),
            ),
          ],
        ),
      ),
    );
  }
}
