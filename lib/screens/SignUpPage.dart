import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:save_wallet/services/login_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // 유저의 아이디와 비밀번호의 정보 저장
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordVerifyingController =
  TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          // 아이디 입력 텍스트필드
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 300,
                    child: CupertinoTextField(
                      controller: userIdController, //이메일 입력한 문자열이 저장되는 부분. firebase에 저장할 때 쓰이므로 이 부분 유지할것.
                      placeholder: '아이디를 입력해주세요',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // 비밀번호 입력 텍스트필드
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 300,
                    child: CupertinoTextField(
                      controller: passwordController, //비밀번호 입력한 문자열이 저장되는 부분. firebase에 저장할 때 쓰이므로 이 부분 유지할것.
                      placeholder: '비밀번호를 입력해주세요',
                      textAlign: TextAlign.center,
                      obscureText: true,
                    ),
                  ),
                ),
                // 비밀번호 재확인 텍스트필드
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 300,
                    child: CupertinoTextField(
                      controller: passwordVerifyingController,//비밀번호 재확인용으로 입력한 문자열이 저장되는 부분. 처음 입력한 비밀번호와 확인 비밀번호가 같은지 판별하기 위해 쓰임.
                      placeholder: '비밀번호를 다시 입력해주세요',
                      textAlign: TextAlign.center,
                      obscureText: true,
                    ),
                  ),
                ),
                // 로그인 페이지로 돌아가기
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 95,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('뒤로 가기'),
                        ),
                      ),
                      Text('   '),
                      // 계정 생성 버튼
                      SizedBox(
                        width: 195,
                        child: ElevatedButton(
                          onPressed: () async{
                            var check = confirmIdCheck(context, passwordController.text, passwordVerifyingController.text); //입력한 비밀번호와 확인 비밀번호가 같은지 확인하고 같으면 1 틀리면 0 리턴.
                            if (check == 1){
                              await signup(context, userIdController.text, passwordController.text); //두 비밀번호가 같으면 파이어베이스에 정보 저장하는 함수. 자세한 설명은 login_service 참고.
                            }
                          },
                          child: Text('계정 생성'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
