import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = '지출';
  String _category = '식비'; // 초기값 변경
  int _amount = 0;
  DateTime _selectedDate = DateTime.now();

  final List<String> _categoryOptions = [
    '식비', '취미-여가', '의료', '교통', '생활', '쇼핑',
  ];

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onAdd(Transaction(
        type: _type,
        category: _category,
        amount: _amount,
        date: _selectedDate,
      ));
      Navigator.of(context).pop();
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
