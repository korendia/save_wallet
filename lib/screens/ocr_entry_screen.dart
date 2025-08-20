import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:save_wallet/models/transaction.dart';


class OCREntryScreen extends StatefulWidget {
  final Function(Transaction_) onAdd;

  OCREntryScreen({required this.onAdd});

  @override
  State<OCREntryScreen> createState() => _OCREntryScreenState();
}

class _OCREntryScreenState extends State<OCREntryScreen> {
  File? _image;
  String _ocrResult = '';
  final picker = ImagePicker();

  //  카메라로 사진 찍기
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      await _processImage(_image!);
    }
  }

  //  OCR 처리
  Future<void> _processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);

    final recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close(); // 리소스 해제

    String text = recognizedText.text;
    setState(() => _ocrResult = text);

    // 디버깅 로그
    print("OCR 결과: $text");

    // 금액 추출 정규식 (12,000 원 / 12000원 모두 매칭)
    final regex = RegExp(r'([0-9]{1,3}(?:,[0-9]{3})*|[0-9]+)\s*원');
    final match = regex.firstMatch(text);
    int? amount = match != null
        ? int.tryParse(match.group(1)!.replaceAll(',', ''))
        : null;

    if (amount != null) {
      print("추출된 금액: $amount"); // ✅확인 로그
      widget.onAdd(Transaction_(
        type: '지출',
        category: '영수증 자동',
        amount: amount,
        date: DateTime.now(),
      ));
      Navigator.of(context).pop();
    } else {
      print("금액을 찾지 못했습니다.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("OCR로 지출 등록")),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text("카메라로 찍기"),
            ),
            if (_ocrResult.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "인식된 텍스트:\n$_ocrResult",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
