

import 'package:flutter/material.dart';

class isDownloadingViewBookProvider extends ChangeNotifier {
  bool _isDownloading=false;

  bool get isDownloading => _isDownloading;

  set isDownloading(bool value) {
    _isDownloading = value;
    notifyListeners();
  }


}