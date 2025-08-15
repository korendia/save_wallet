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

  // 카테고리별 색상 및 아이콘 정의
  Map<String, Color> categoryColors = {
    '식비': Colors.orange,
    '취미-여가': Colors.purple,
    '의료': Colors.red,
    '교통': Colors.blue,
    '생활': Colors.green,
    '쇼핑': Colors.pink,
  };

  Map<String, IconData> categoryIcons = {
    '식비': Icons.restaurant,
    '취미-여가': Icons.sports_esports,
    '의료': Icons.local_hospital,
    '교통': Icons.directions_car,
    '생활': Icons.home,
    '쇼핑': Icons.shopping_bag,
  };

  Future<DateTime> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('데이터 없음'),
              ],
            ),
            content: const Text('선택한 날짜에 해당하는 데이터가 없습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
    return "${total.toInt()}";
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

  Map<String, double> getTopExpenses() {
    Map<String, double> nonZeroExpenses = Map.fromEntries(
      eachitemmoney.entries.where((entry) => entry.value > 0),
    );

    List<MapEntry<String, double>> sortedExpenses = nonZeroExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedExpenses.take(3));
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

    return eachitemmoney.entries.where((entry) => entry.value > 0).map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        color: categoryColors[entry.key] ?? Colors.grey,
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '일일 지출 통계',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: a == null
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 선택 카드
            Card(
              elevation: 8,
              shadowColor: colorScheme.shadow.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '선택된 날짜',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('변경'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 총 지출 카드
            Card(
              elevation: 8,
              shadowColor: colorScheme.shadow.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.tertiaryContainer,
                      colorScheme.tertiaryContainer.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: colorScheme.tertiary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '오늘의 총 지출',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onTertiaryContainer.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<String>(
                      future: a != null ? writedaytotal(a!) : Future.value('0'),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('에러: ${snapshot.error}');
                        } else if (snapshot.hasData) {
                          return Text(
                            '${snapshot.data!}원',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onTertiaryContainer,
                            ),
                          );
                        } else {
                          return const Text('데이터 없음');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 카테고리별 상위 지출 리스트
            if (getTopExpenses().isNotEmpty) ...[
              Text(
                '카테고리별 지출 현황',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ...getTopExpenses().entries.map((entry) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: 4,
                  shadowColor: colorScheme.shadow.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: categoryColors[entry.key]?.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        categoryIcons[entry.key],
                        color: categoryColors[entry.key],
                        size: 24,
                      ),
                    ),
                    title: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Text(
                      '${entry.value.toInt()}원',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: categoryColors[entry.key],
                      ),
                    ),
                  ),
                ),
              )).toList(),

              const SizedBox(height: 24),
            ],

            // 파이 차트 카드
            Card(
              elevation: 8,
              shadowColor: colorScheme.shadow.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: colorScheme.surface,
                ),
                child: Column(
                  children: [
                    Text(
                      '지출 분포',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 250,
                      child: (eachitemmoney.isEmpty || eachitemmoney.values.every((v) => v == 0))
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pie_chart_outline,
                            size: 80,
                            color: colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '지출 데이터 없음',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      )
                          : PieChart(
                        PieChartData(
                          sections: buildPieChartData(),
                          centerSpaceRadius: 50,
                          sectionsSpace: 2,
                          startDegreeOffset: -90,
                        ),
                      ),
                    ),
                    if (buildPieChartData().isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: eachitemmoney.entries
                            .where((entry) => entry.value > 0)
                            .map((entry) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: categoryColors[entry.key],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 100), // 하단 네비게이션 바 여유 공간
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