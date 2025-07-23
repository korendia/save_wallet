import 'package:flutter/material.dart';
import 'models/transaction.dart';
import 'screens/manual_entry_screen.dart';
import 'screens/ocr_entry_screen.dart';

void main() => runApp(AccountBookApp());

class AccountBookApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '가계부',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> transactions = [];

  void _addTransaction(Transaction tx) {
    setState(() => transactions.add(tx));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('가계부')),
      body: ListView(
        children: transactions.map((tx) {
          return ListTile(
            title: Text('${tx.type}: ${tx.category}'),
            subtitle: Text('${tx.amount}원 (${tx.date.toLocal().toIso8601String().substring(0, 10)})'),
          );
        }).toList(),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'manual',
            child: Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ManualEntryScreen(onAdd: _addTransaction),
              ),
            ),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'ocr',
            child: Icon(Icons.camera_alt),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OCREntryScreen(onAdd: _addTransaction),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
