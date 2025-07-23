import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class ManualEntryScreen extends StatefulWidget {
  final Function(Transaction) onAdd;

  ManualEntryScreen({required this.onAdd});

  @override
  _ManualEntryScreenState createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = '지출';
  String _category = '';
  int _amount = 0;
  DateTime _selectedDate = DateTime.now();

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
              items: ['수입', '지출']
                  .map((label) => DropdownMenuItem(
                        child: Text(label),
                        value: label,
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _type = value!),
            ),
            TextFormField(
              decoration: InputDecoration(labelText: "항목"),
              onSaved: (value) => _category = value!,
              validator: (value) => value!.isEmpty ? '항목 입력' : null,
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
