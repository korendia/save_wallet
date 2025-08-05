import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionListScreen extends StatefulWidget {
  final String? userId;

  const TransactionListScreen({required this.userId});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  List<Map<String, dynamic>> _transactions = [];

  Future<void> _fetchTransactions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('MoneyList')
        .orderBy('date', descending: true)
        .get();

    setState(() {
      _transactions = snapshot.docs.map((doc) {
        final data = doc.data();

        Timestamp timestamp = doc['date'];
        DateTime dateTime = timestamp.toDate();

        final formatter = DateFormat('yyyy-MM-dd HH:mm');  // 원하는 포맷 지정
        String formattedDate = formatter.format(dateTime);

        return {
          'id': doc.id,
          'category': data['category'],
          'amount': data['amount'],
          'type': data['type'],
          'date': formattedDate,
        };
      }).toList();
    });
  }

  Future<void> _deleteTransaction(String docId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('MoneyList')
        .doc(docId)
        .delete();

    _fetchTransactions(); // 삭제 후 다시 불러오기
  }

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('가계부 내역 지우기')),
      body: ListView.builder(
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final t = _transactions[index];
          return ListTile(
            title: Text(t['category']),
            subtitle: Text('${t['type']} | ${t['date']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('₩${t['amount']}'),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _confirmDelete(t['id']);
                  },
                )
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('삭제 확인'),
        content: Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteTransaction(docId);
            },
            child: Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
