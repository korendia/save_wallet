import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/transaction.dart';

class OCREntryScreen extends StatefulWidget {
  final Function(Transaction) onAdd;

  OCREntryScreen({required this.onAdd});

  @override
  State<OCREntryScreen> createState() => _OCREntryScreenState();
}

class _OCREntryScreenState extends State<OCREntryScreen> {
  File? _image;
  String _ocrResult = '';
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      await _processImage(_image!);
    }
  }

  Future<void> _processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
    final recognizedText = await textRecognizer.processImage(inputImage);
    String text = recognizedText.text;

    setState(() => _ocrResult = text);

    // 금액 추출 예시
    final regex = RegExp(r'([0-9,]+)\s*원');
    final match = regex.firstMatch(text);
    int? amount = match != null ? int.tryParse(match.group(1)!.replaceAll(',', '')) : null;

    if (amount != null) {
      widget.onAdd(Transaction(
        type: '지출',
        category: '영수증 자동',
        amount: amount,
        date: DateTime.now(),
      ));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("OCR로 지출 등록")),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(onPressed: _pickImage, child: Text("카메라로 찍기")),
            if (_ocrResult.isNotEmpty) Padding(
              padding: const EdgeInsets.all(16),
              child: Text("인식된 텍스트:\n$_ocrResult"),
            ),
          ],
        ),
      ),
    );
  }
}
