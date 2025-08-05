import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:save_wallet/widgets/bottom_nav.dart';
import 'package:save_wallet/screens/manual_entry_screen.dart';
import 'package:save_wallet/screens/ocr_entry_screen.dart';
import 'package:save_wallet/screens/delete.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/transaction.dart';




class Transaction {
  final String title;
  final int amount;
  final String type;

  Transaction({required this.title, required this.amount, required this.type});
}

class HomePageScreen extends StatefulWidget {
  const HomePageScreen({Key? key}) : super(key: key);

  static String routeName = 'home_page';
  static String routePath = '/homepage';

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {

  String? userId;

  int _selectedIndex = 1;
  double _balance = 0;
  //TextEditingController _balanceController = TextEditingController();
  //TextEditingController _incomeController = TextEditingController();
  //TextEditingController _expenseController = TextEditingController();

  int _totalBudget = 0;
  Map<String, double> _expenseCategories = {};
  List<Transaction> _transactions = [];

  Future<void> getdata() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('MoneyList')
        .orderBy('date', descending: true)
        .get();

    final transactions = snapshot.docs.map((doc) {
      final data = doc.data();
      return Transaction(
        title: data['category'],
        amount: data['amount'],
        type: data['type'],
      );
    }).toList();

    setState(() {
      _transactions = transactions;
    });

  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _addCategoryDialog() async{
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('MoneyList')
        .orderBy('date', descending: true)
        .get();

    Map<String, double> updatedExpenses = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final category = data['category'];
      final amount = data['amount'];
      final type = data['type'];
      if (category != null && amount != null && type == '지출') {
        updatedExpenses[category] = amount;
      }
    }

    setState(() {
      _expenseCategories = updatedExpenses;
    });
  }

  Future<void> Updatebalance() async{
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('MoneyList')
        .orderBy('date', descending: true)
        .get();

    double newBalance = 0;

    for (var doc in snapshot.docs){
      final data = doc.data();

      if( data['type'] == "수입") {
        newBalance += data['amount'];
      }
      else{
        newBalance -= data['amount'];
      }
    }

    setState(() {
      _balance = newBalance + _totalBudget;
    });
  }

  Future<void> loadBudgetFromFirebase() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('budget')
        .get();

    if (doc.exists) {
      setState(() {
        _totalBudget = doc['totalBudget'];
      });
    }
  }


  Future<void> _showBudgetInputDialog() async{
    await loadBudgetFromFirebase();
    TextEditingController _budgetInputController = TextEditingController(text: _totalBudget.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('총 예산 수정'),
          content: TextField(
            controller: _budgetInputController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: '총 예산 입력'),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),

            ElevatedButton(
              onPressed: () async{
                setState(() {
                  _totalBudget = int.tryParse(_budgetInputController.text) ?? 0;
                });

                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('settings')
                      .doc('budget')
                      .set({
                    'totalBudget': _totalBudget,

                  });
                } catch(e){
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('오류. 사유 : $e'),
                        duration: Duration(seconds: 5),
                      )
                  );
                }

                Navigator.of(context).pop();
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }


  Future<void> onAdd(Transaction_ a) async{

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('MoneyList')
        .add({
      'type': a.type,
      'category': a.category,
      'amount': a.amount,
      'date': a.date,
    });
  }



  @override

  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      userId = user?.uid;
    });

    getdata();
    _addCategoryDialog();

  }


  Widget build(BuildContext context) {
    double currentBalance = _balance;
    double usedPercentage = _totalBudget == 0 ? 0.0 : (1 - (currentBalance / _totalBudget)).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('지갑을 부탁해'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          Center(child: Text('Statistics Page')),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('안녕하세요(Nickname)님', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  //이쪽의 Nickname을 사용자가 가입한 이름으로 바꿔줘야함 + 그러려면 가입할 때 사용자 이름도 받아야함 폼 만들어주면 추가할게
                  const SizedBox(height: 4),

                  Text('오늘도 현명한 소비하세요', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: Updatebalance,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('이번 달 총 예산 포함 총잔액(업데이트하려면 클릭)', style: TextStyle(color: Colors.white)),
                          Text('₩${_balance.toStringAsFixed(0)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 8),

                          LinearPercentIndicator(
                            lineHeight: 10.0,
                            percent: usedPercentage,
                            backgroundColor: Colors.white24,
                            progressColor: Colors.greenAccent,
                          ),
                          const SizedBox(height: 4),

                          GestureDetector(
                            onTap: _showBudgetInputDialog,
                            child: Text('총 예산: ₩$_totalBudget (클릭하여 수정/업데이트)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('최근 거래 내역', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                              onPressed: (){
                                getdata();
                              },
                              icon: Icon(Icons.refresh)
                          ),
                          IconButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ManualEntryScreen(
                                      userId: userId,
                                      onAdd: onAdd),
                              ),
                            );
                          },
                              icon: Icon(Icons.add)),
                          IconButton(onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => TransactionListScreen(userId: userId)),
                            );
                          },
                              icon: Icon(Icons.remove)),
                          IconButton(onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => OCREntryScreen(onAdd: onAdd)),
                            );

                          },
                              icon: Icon(Icons.camera))
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 8),

                  _transactions.isEmpty
                      ? Text('거래 내역이 없습니다.')
                      : Column(
                    children: _transactions.map((t) => _buildTransactionItem(t.title, t.amount, t.type)).toList(),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('지출 비율', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: _addCategoryDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  AspectRatio(
                    aspectRatio: 1.3,
                    child: PieChart(
                      PieChartData(
                        sections: _expenseCategories.entries.isEmpty
                            ? []
                            : _expenseCategories.entries.map((entry) {
                          return PieChartSectionData(
                            title: entry.key,
                            value: entry.value,
                            color: _getCategoryColor(entry.key),
                            titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            radius: 50,
                            //원 그래프에 이름 말고도 차지 퍼센트라던지 총합도 나오면 괜찮을 것 같은데 내가 이 함수를 모르네.... 여력 되면 추가 고려 바람
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        onTabSelected: (int index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/statistics');
              break;
            case 1:
              Navigator.pushNamed(context, '/home');
              break;
            case 2:
              Navigator.pushNamed(context, '/community');
              break;
          }
        },
      ),
    );
  }

  Widget _buildTransactionItem(String title, int amount, String type) {
    return ListTile(
      title: Text(title),
      subtitle: Text(type),
      trailing: Text('₩$amount'),
    );
  }

  Color _getCategoryColor(String category) {
    return Colors.primaries[_expenseCategories.keys.toList().indexOf(category) % Colors.primaries.length];
  }
}
