import 'package:flutter/material.dart';
import '../../models/transaction.dart';


class ManualEntryScreen extends StatefulWidget {
  final String? userId;
  final Future<void> Function(Transaction_) onAdd;

  const ManualEntryScreen({
    super.key,
    required this.userId,
    required this.onAdd,
  });




  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}


class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = '지출';
  String _category = '식비'; // 초기값 변경
  int _amount = 0;
  DateTime _selectedDate = DateTime.now();

  final List<String> _categoryOptions = [
    '식비', '취미-여가', '의료', '교통', '생활', '쇼핑',
  ];

  void _submit() async {
    try {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();
        await widget.onAdd(Transaction_(
          type: _type,
          category: _category,
          amount: _amount,
          date: _selectedDate,
        ));
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('성공적으로 저장되었음'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('실패. 사유 : $e'),
          duration: Duration(seconds: 10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("직접 입력")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            DropdownButtonFormField<String>(
              value: _type,
              items: ['수입', '지출'].map((label) => DropdownMenuItem(
                child: Text(label),
                value: label,
              )).toList(),
              onChanged: (value) => setState(() => _type = value!),
            ),

            DropdownButtonFormField<String>(
              value: _category,
              items: _categoryOptions.map((label) => DropdownMenuItem(
                child: Text(label),
                value: label,
              )).toList(),
              onChanged: (value) => setState(() => _category = value!),
              decoration: InputDecoration(labelText: "카테고리"),
            ),

            TextFormField(
              decoration: InputDecoration(labelText: "금액"),
              keyboardType: TextInputType.number,
              onSaved: (value) => _amount = int.parse(value!),
              validator: (value) => value!.isEmpty ? '금액 입력' : null,
            ),

            ElevatedButton(
              onPressed: _submit,
              child: Text("저장"),
            ),
          ]),
        ),
      ),
    );
  }
}
