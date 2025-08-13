import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:save_wallet/widgets/bottom_nav.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  static String routeName = 'statistics_page';
  static String routePath = '/statistics';

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String? userId;
  DateTime selectedDate = DateTime.now();
  QuerySnapshot<Map<String, dynamic>>? a;

  Map<String, double> eachitemmoney = {
    '식비': 0,
    '취미-여가': 0,
    '의료': 0,
    '교통': 0,
    '생활': 0,
    '쇼핑': 0,
  };

  Future<DateTime> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        a = null;
        eachitemmoney.updateAll((key, value) => 0);
      });
      await loadData(picked);
    }
    return picked ?? selectedDate;
  }

  Future<QuerySnapshot<Map<String, dynamic>>?> getfirebasedata(DateTime picked) async {
    DateTime pickedday = DateTime(picked.year, picked.month, picked.day);
    DateTime nextday = pickedday.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('MoneyList')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(pickedday))
        .where('date', isLessThan: Timestamp.fromDate(nextday))
        .orderBy('date', descending: true)
        .get();

    if (snapshot.docs.isEmpty) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('데이터 없음'),
            content: const Text('선택한 날짜에 해당하는 데이터가 없습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    }

    return snapshot;
  }

  Future<String> writedaytotal(QuerySnapshot<Map<String, dynamic>> snapshot) async {
    num total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['type'] == '지출') {
        total += (data['amount'] as num?) ?? 0;
      }
    }
    return "오늘의 총 지출은 ${total.toInt()}원입니다.";
  }

  Future<void> writeamountofitem(QuerySnapshot<Map<String, dynamic>> snapshot) async {
    eachitemmoney.updateAll((key, value) => 0);
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['type'] == '지출') {
        final category = data['category'];
        if (eachitemmoney.containsKey(category)) {
          eachitemmoney[category] = eachitemmoney[category]! + (data['amount'] as num).toDouble();
        }
      }
    }
  }

  String compareitem_max() {
    double max = -1;
    List<String> item = [];

    for (var entry in eachitemmoney.entries) {
      if (entry.value > max) {
        max = entry.value;
      }
    }

    for (var entry in eachitemmoney.entries) {
      if (entry.value == max && max > 0) {
        item.add(entry.key);
      }
    }

    final result = item.join(", ");
    return "가장 지출이 큰 항목: $result\n지출 금액: ${max.toInt()}원";
  }

  Future<void> loadData(DateTime picked) async {
    final snapshot = await getfirebasedata(picked);
    if (mounted) {
      setState(() {
        a = snapshot;
      });
      if (snapshot != null) {
        await writeamountofitem(snapshot);
      }
    }
  }

  List<PieChartSectionData> buildPieChartData() {
    if (eachitemmoney.isEmpty || eachitemmoney.values.every((v) => v == 0)) {
      return [];
    }

    double total = eachitemmoney.values.reduce((a, b) => a + b);

    return eachitemmoney.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        color: Colors.primaries[eachitemmoney.keys.toList().indexOf(entry.key) % Colors.primaries.length],
        value: entry.value,
        title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    userId = user?.uid;
    loadData(selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('일일 소득 / 지출 통계'),
      ),
      body: a == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(//상단 날짜 클릭 버튼 부분.
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',//선택 안했으면 기본적으로 오늘 날짜로 들어가있음
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _pickDate,
                    child: const Text('날짜 선택'),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.lightBlueAccent,
              width: double.infinity,
              height: 150,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(16),
              child: Text(
                compareitem_max(),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            Container(
              color: Colors.lightBlue,
              width: double.infinity,
              height: 150,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<String>(//데이터 가져오는 부분. 데이터 주고받는 부분이라 futurebuilder 임의 수정 X.
                future: a != null ? writedaytotal(a!) : Future.value(''),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('에러: ${snapshot.error}');
                  } else if (snapshot.hasData) {
                    return Text(
                      snapshot.data!,
                      style: const TextStyle(fontSize: 18),
                    );
                  } else {
                    return const Text('데이터 없음');
                  }
                },
              ),
            ),
            Container(
              color: CupertinoColors.activeBlue,
              width: double.infinity,
              height: 300,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              child: (eachitemmoney.isEmpty || eachitemmoney.values.every((v) => v == 0))
                  ? const Text(
                '지출 데이터 없음',
                style: TextStyle(fontSize: 18, color: Colors.white),
              )
                  : PieChart(
                PieChartData(
                  sections: buildPieChartData(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 4,
                ),
              ),
            ),
          ],
        ),
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
}
