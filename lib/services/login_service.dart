import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:save_wallet/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final user = FirebaseAuth.instance.currentUser;

String? userId = user?.uid;

Future<void> login(BuildContext context, String email, String password)async {
  try {
    await _auth.signInWithEmailAndPassword(email: email, password: password); //firebase에 입력받은 정보 보내서 그쪽 데이터와 비교해보는 작업.
    //정상 실행되었으면 아래쪽 실행
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('로그인 성공'),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pushNamed(context, HomePageScreen.routePath);

  } catch (e) {
    //오류가 났으면 이 부분 실행
    if (email.isEmpty || password.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            //패스워드, 비번 미입력이라면 이부분 실행
            content: Text('비밀번호 혹은 패스워드가 입력되지 않았습니다.'),
            duration: Duration(seconds: 2),
          )
      );
    }
    else {
      //그 외 다른 에러라면 여기 실행(영어임)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류. 사유 : $e'),
          duration: Duration(seconds: 2),
        )
      );
    }
  }
}

Future<void> signup(BuildContext context, String name, String email, String password)async { //회원가입
  try {
    //입력받은 정보 firebase 전송
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('info')
        .set({
      'username' : name
    });
    //정상작동 이 부분 실행
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('회원가입 성공'),
          duration: Duration(seconds: 2),
        )
    );
  } catch (e) {
    //오류나면 이 부분 실행
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('회원가입 실패 : $e'),
          duration: Duration(seconds: 2),
        )
    );
  }
}

//얘는 그냥 비밀번호 재입력한거랑 처음 입력한 게 같은지 다른지 판별하는 용도
int confirmIdCheck(BuildContext context, String password, String passwordVerifying) {
  if (password != passwordVerifying){
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('입력하신 비밀번호가 같지 않습니다.'),
          duration: Duration(seconds: 2),
        )
    );
    return 0;
    }
  else{
    return 1;
  }
  }



