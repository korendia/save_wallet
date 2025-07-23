import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


final FirebaseAuth _auth = FirebaseAuth.instance;

Future<void> login(BuildContext context, String email, String password)async {
  try {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('로그인 성공'),
        duration: Duration(seconds: 2),
      ),

        //Navigator.of(context).push(
        //  MaterialPageRoute(builder: (context) => NewPage()),
        //);
        //화면 전환 부분. 알아서 만들어주면 됨
    );
  } catch (e) {
    if (email.isEmpty || password.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('비밀번호 혹은 패스워드가 입력되지 않았습니다.'),
            duration: Duration(seconds: 2),
          )
      );
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류. 사유 : $e'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

Future<void> signup(BuildContext context, String email, String password)async {
  try {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('회원가입 성공'),
          duration: Duration(seconds: 2),
        )
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('회원가입 실패 : $e'),
          duration: Duration(seconds: 2),
        )
    );
  }
}

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


  //항목마다 합산 금액 나타내는 거.
/*
  Future<int> analizing_money(String item) async{
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('entries')
        .get();

    int totalSpending = 0;

    for (var doc in snapshot.docs) {
      if (doc['type'] == 'item') {
        totalSpending += doc['amount'] as int;
      }
    }

    return totalSpending;

  }
 */
