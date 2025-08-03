import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final Function(int) onTabSelected;

  const CustomBottomNavBar({
    Key? key,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => onTabSelected(0), // 통계
          ),
          SizedBox(width: 48), // 가운데 홈 버튼 공간 비우기 (FAB 자리)
          IconButton(
            icon: const Icon(Icons.forum),
            onPressed: () => onTabSelected(2), // 커뮤니티
          ),
        ],
      ),
    );
  }
}
