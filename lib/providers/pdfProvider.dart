import 'package:flutter/material.dart';
class PdfProvider extends ChangeNotifier {
  String pdfPath = '';

  // String get pdfPath => _pdfPath;

  void updatePdfPath(String path) {
    pdfPath = path;
    notifyListeners();
  }
}
