import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:save_wallet/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;


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
            //이메일, 비번 미입력이라면 이부분 실행
            content: Text('이메일 혹은 패스워드가 입력되지 않았습니다.'),
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

Future<void> signup(BuildContext context, String name, String email, String password) async {
  try {
    // Firebase Authentication으로 유저 생성
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 새로 생성된 유저의 UID 가져오기
    String userId = userCredential.user!.uid;

    // Firestore에 유저 정보 저장
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('userinfo')
        .set({
      'username': name,
      'email': email,
      'authorId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 성공 메시지
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('회원가입 성공'),
        duration: Duration(seconds: 2),
      ),
    );
  } catch (e) {
    // 실패 메시지
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('회원가입 실패: $e'),
        duration: Duration(seconds: 2),
      ),
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



