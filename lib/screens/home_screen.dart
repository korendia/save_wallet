import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:save_wallet/widgets/bottom_nav.dart';


class Transaction {
  final String title;
  final String amount;
  final String date;

  Transaction({required this.title, required this.amount, required this.date});
}

class HomePageScreen extends StatefulWidget {
  const HomePageScreen({Key? key}) : super(key: key);

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  int _selectedIndex = 1;
  TextEditingController _balanceController = TextEditingController();
  //TextEditingController _incomeController = TextEditingController();
  //TextEditingController _expenseController = TextEditingController();

  int _totalBudget = 0;
  Map<String, double> _expenseCategories = {};
  List<Transaction> _transactions = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _addCategoryDialog() {
    TextEditingController _categoryNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('카테고리 추가'),
          content: TextField(
            controller: _categoryNameController,
            decoration: InputDecoration(hintText: '카테고리 이름 입력'),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _expenseCategories[_categoryNameController.text] = 0;
                });
                Navigator.of(context).pop();
              },
              child: Text('추가'),
            ),
          ],
        );
      },
    );
  }

  void _showBalanceInputDialog() {
    TextEditingController _balanceInputController = TextEditingController(text: _balanceController.text);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('잔액 수정'),
          content: TextField(
            controller: _balanceInputController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: '잔액 입력'),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _balanceController.text = _balanceInputController.text;
                });
                Navigator.of(context).pop();
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _showBudgetInputDialog() {
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
              onPressed: () {
                setState(() {
                  _totalBudget = int.tryParse(_budgetInputController.text) ?? 0;
                });
                Navigator.of(context).pop();
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _addTransaction() {
    TextEditingController _titleController = TextEditingController();
    TextEditingController _amountController = TextEditingController();
    TextEditingController _dateController = TextEditingController();
    String selectedCategory = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('거래 내역 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(hintText: '항목명 입력'),
              ),

              TextField(
                controller: _amountController,
                decoration: InputDecoration(hintText: '금액 입력'),
                keyboardType: TextInputType.number,
              ),

              TextField(
                controller: _dateController,
                decoration: InputDecoration(hintText: '날짜 입력'),
              ),

              DropdownButton<String>(
                value: selectedCategory.isEmpty ? null : selectedCategory,
                hint: Text('카테고리 선택'),
                isExpanded: true,
                items: _expenseCategories.keys.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue ?? '';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _transactions.insert(0, Transaction(
                    title: _titleController.text,
                    amount: '₩${_amountController.text}',
                    date: _dateController.text,
                  ));
                  double amountValue = double.tryParse(_amountController.text) ?? 0;
                  if (selectedCategory.isNotEmpty) {
                    _expenseCategories[selectedCategory] = (_expenseCategories[selectedCategory] ?? 0) + amountValue.abs();
                  }
                });
                Navigator.of(context).pop();
              },
              child: Text('추가'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double currentBalance = int.tryParse(_balanceController.text)!.toDouble();
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
                  //이쪽의 Nickname을 사용자가 가입한 이름으로 바꿔줘야함
                  const SizedBox(height: 4),

                  Text('오늘도 현명한 소비하세요', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: _showBalanceInputDialog,
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
                          Text('이번 달 총 잔액', style: TextStyle(color: Colors.white)),
                          Text('₩${_balanceController.text}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
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
                            child: Text('총 예산: ₩$_totalBudget (클릭하여 수정)', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: _addTransaction,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  _transactions.isEmpty
                      ? Text('거래 내역이 없습니다.')
                      : Column(
                    children: _transactions.map((t) => _buildTransactionItem(t.title, t.amount, t.date)).toList(),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('지출 비율 (클릭하여 수정)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.add),
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

  Widget _buildTransactionItem(String title, String amount, String date) {
    return ListTile(
      title: Text(title),
      subtitle: Text(date),
      trailing: Text(amount),
    );
  }

  Color _getCategoryColor(String category) {
    return Colors.primaries[_expenseCategories.keys.toList().indexOf(category) % Colors.primaries.length];
  }
}
