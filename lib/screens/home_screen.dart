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
  int _totalBudget = 0;
  Map<String, double> _expenseCategories = {};
  List<Transaction> _transactions = [];
  String nickname = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    userId = user?.uid;
    if (userId != null) {
      _initializeData();
    } else {
      setState(() {
        _error = '사용자 인증이 필요합니다.';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load all data concurrently
      final results = await Future.wait([
        _getFirebaseData(),
        _loadBudgetFromFirebase(),
        _getUserName(),
      ]);

      final snapshot = results[0] as QuerySnapshot<Map<String, dynamic>>;

      // Process all data
      await Future.wait([
        _updateTransactions(snapshot),
        _updateExpenseCategories(snapshot),
        _updateBalance(snapshot),
      ]);

    } catch (e) {
      setState(() {
        _error = '데이터 로딩 중 오류가 발생했습니다: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getFirebaseData() async {
    if (userId == null) throw Exception('사용자 ID가 없습니다.');

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstDayOfNextMonth = (now.month < 12)
        ? DateTime(now.year, now.month + 1, 1)
        : DateTime(now.year + 1, 1, 1);

    return await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('MoneyList')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(firstDayOfNextMonth))
        .orderBy('date', descending: true)
        .get();
  }

  Future<void> _updateTransactions(QuerySnapshot<Map<String, dynamic>> snapshot) async {
    final transactions = snapshot.docs.map((doc) {
      final data = doc.data();
      return Transaction(
        title: data['category'] ?? '미분류',
        amount: data['amount'] ?? 0,
        type: data['type'] ?? '기타',
      );
    }).toList();

    setState(() {
      _transactions = transactions;
    });
  }

  Future<void> _updateExpenseCategories(QuerySnapshot<Map<String, dynamic>> snapshot) async {
    final Map<String, double> updatedExpenses = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final category = data['category'];
      final amount = data['amount'];
      final type = data['type'];

      if (category != null && amount != null && type == '지출') {
        updatedExpenses[category] = (updatedExpenses[category] ?? 0) + amount.toDouble();
      }
    }

    setState(() {
      _expenseCategories = updatedExpenses;
    });
  }

  Future<void> _updateBalance(QuerySnapshot<Map<String, dynamic>> snapshot) async {
    double newBalance = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final type = data['type'];
      final amount = data['amount'];

      if (type == "수입") {
        newBalance += amount?.toDouble() ?? 0;
      } else if (type == "지출") {
        newBalance -= amount?.toDouble() ?? 0;
      }
    }

    setState(() {
      _balance = newBalance + _totalBudget;
    });
  }

  Future<void> _loadBudgetFromFirebase() async {
    if (userId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('budget')
          .get();

      if (doc.exists && doc.data()?['totalBudget'] != null) {
        setState(() {
          _totalBudget = doc.data()!['totalBudget'];
        });
      }
    } catch (e) {
      debugPrint('예산 로딩 오류: $e');
    }
  }

  Future<String> _getUserName() async {
    if (userId == null) return 'no-data';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('userinfo')
          .get();

      final username = doc.data()?['username'];
      setState(() {
        nickname = username ?? '사용자';
      });
      return username ?? 'no-data';
    } catch (e) {
      debugPrint('사용자명 로딩 오류: $e');
      setState(() {
        nickname = '사용자';
      });
      return 'no-data';
    }
  }

  Future<void> _showBudgetInputDialog() async {
    final controller = TextEditingController(text: _totalBudget.toString());

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('총 예산 수정'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '총 예산 입력',
                suffixText: '원',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newBudget = int.tryParse(controller.text);
                  if (newBudget != null && newBudget >= 0) {
                    Navigator.of(context).pop(true);
                  } else {
                    // 잘못된 입력 처리
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('올바른 숫자를 입력해주세요'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('확인'),
              ),
            ],
          );
        },
      );

      if (result == true && mounted) {
        final newBudget = int.tryParse(controller.text) ?? 0;
        await _updateBudget(newBudget);
      }
    } catch (e) {
      debugPrint('예산 다이얼로그 오류: $e');
    } finally {
      controller.dispose();
    }
  }

  Future<void> _updateBudget(int newBudget) async {
    if (userId == null) return;

    try {
      setState(() {
        _totalBudget = newBudget;
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('budget')
          .set({'totalBudget': _totalBudget});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예산이 성공적으로 업데이트되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예산 업데이트 오류: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onAdd(Transaction_ transaction) async {
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('MoneyList')
          .add({
        'type': transaction.type,
        'category': transaction.category,
        'amount': transaction.amount,
        'date': transaction.date,
      });

      // Refresh data after adding
      _refreshData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('거래 추가 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    try {
      final snapshot = await _getFirebaseData();
      await Future.wait([
        _updateTransactions(snapshot),
        _updateExpenseCategories(snapshot),
        _updateBalance(snapshot),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 새로고침 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('지갑을 부탁해'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : IndexedStack(
        index: _selectedIndex,
        children: [
          const Center(child: Text('Statistics Page')),
          _buildHomeContent(),
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

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeData,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    final currentBalance = _balance;
    final usedPercentage = _totalBudget == 0
        ? 0.0
        : (1 - (currentBalance / _totalBudget)).clamp(0.0, 1.0);

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 20),
              _buildBalanceCard(currentBalance, usedPercentage),
              const SizedBox(height: 20),
              _buildTransactionsSection(),
              _buildTransactionsList(),
              _buildExpenseRatioSection(),
              const SizedBox(height: 16),
              _buildPieChart(),
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '안녕하세요, $nickname님',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          '오늘도 현명한 소비하세요',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(double currentBalance, double usedPercentage) {
    return GestureDetector(
      onTap: _refreshData,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이번 달 총잔액',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '₩${currentBalance.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            LinearPercentIndicator(
              lineHeight: 12.0,
              percent: usedPercentage,
              backgroundColor: Colors.white24,
              progressColor: usedPercentage > 0.8 ? Colors.red : Colors.greenAccent,
              barRadius: const Radius.circular(6),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _showBudgetInputDialog,
                  child: Text(
                    '총 예산: ₩$_totalBudget',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                Text(
                  '${(usedPercentage * 100).toStringAsFixed(1)}% 사용',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '최근 거래 내역',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            IconButton(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              tooltip: '새로고침',
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ManualEntryScreen(
                      userId: userId,
                      onAdd: _onAdd,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              tooltip: '수동 입력',
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionListScreen(userId: userId),
                  ),
                );
              },
              icon: const Icon(Icons.list),
              tooltip: '전체 목록',
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OCREntryScreen(onAdd: _onAdd),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              tooltip: 'OCR 입력',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionsList() {
    return Container(
      height: 300,
      margin: const EdgeInsets.only(top: 8),
      child: _transactions.isEmpty
          ? const Center(
        child: Text(
          '이번 달 거래 내역이 없습니다',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      )
          : ListView.builder(
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return _buildTransactionItem(
            transaction.title,
            transaction.amount,
            transaction.type,
          );
        },
      ),
    );
  }

  Widget _buildExpenseRatioSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '지출 비율',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshData,
          tooltip: '새로고침',
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    if (_expenseCategories.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          '이번 달 지출 내역이 없습니다',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    final totalExpense = _expenseCategories.values.reduce((a, b) => a + b);
    final sortedCategories = _expenseCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // 금액 순으로 정렬

    return Column(
      children: [
        // 총 지출 정보
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '이번 달 총 지출',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '₩${totalExpense.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),

        // 차트와 범례를 나란히 배치
        Row(
          children: [
            // 파이 차트
            Expanded(
              flex: 3,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: sortedCategories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final categoryEntry = entry.value;
                      final percentage = (categoryEntry.value / totalExpense * 100);

                      return PieChartSectionData(
                        title: percentage >= 5.0 ? '${percentage.toStringAsFixed(1)}%' : '',
                        value: categoryEntry.value,
                        color: _getCategoryColor(categoryEntry.key, index),
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        radius: 70,
                        titlePositionPercentageOffset: 0.6,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // 범례
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sortedCategories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final categoryEntry = entry.value;
                  final percentage = (categoryEntry.value / totalExpense * 100);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(categoryEntry.key, index),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                categoryEntry.key,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '₩${categoryEntry.value.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 상세 지출 내역 리스트
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '카테고리별 상세 내역',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...sortedCategories.asMap().entries.map((entry) {
                final index = entry.key;
                final categoryEntry = entry.value;
                final percentage = (categoryEntry.value / totalExpense * 100);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(categoryEntry.key, index),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryEntry.key,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '전체의 ${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₩${categoryEntry.value.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 60,
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: Colors.grey.shade300,
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: percentage / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: _getCategoryColor(categoryEntry.key, index),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(String title, int amount, String type) {
    final isIncome = type == '수입';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.green : Colors.red,
          child: Icon(
            isIncome ? Icons.add : Icons.remove,
            color: Colors.white,
          ),
        ),
        title: Text(title),
        subtitle: Text(type),
        trailing: Text(
          '${isIncome ? '+' : '-'}₩${amount.abs()}',
          style: TextStyle(
            color: isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category, int index) {
    final colors = [
      Colors.blue.shade600,
      Colors.red.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.teal.shade600,
      Colors.pink.shade600,
      Colors.amber.shade600,
      Colors.indigo.shade600,
      Colors.brown.shade600,
      Colors.cyan.shade600,
      Colors.lime.shade600,
    ];

    return colors[index % colors.length];
  }
}