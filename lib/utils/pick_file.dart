import 'package:bookstore_recommendation_system_fyp/utils/snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';

pickFile(List<String> allowedextensions, FileType filetype, int size,
    BuildContext context) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowedExtensions: allowedextensions,
      type: filetype,
      withData: true,
      withReadStream: true);

  if (result != null) {
    PlatformFile file = result.files.single;
    if (file.size < size) {
      return file;
    } else {
      print('upload less than 5  mb');
      print(file.size);
      if (size == 5000000) {
        showSnackBar(context, 'upload less than 5 mb file');
      } else if (size == 25000000) {
        showSnackBar(context, 'upload less than 25 mb file');
      }
      return;
    }
  } else {
    // User canceled the picker
    return null;
  }
}
