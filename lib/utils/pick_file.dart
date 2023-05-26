import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bookstore_recommendation_system_fyp/utils/snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
      if (size == 2000000) {
        final snackBar = SnackBar(
          /// need to set following properties for best effect of awesome_snackbar_content
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,

          content: AwesomeSnackbarContent(
            title: 'Error!',
            message:
            'upload less than 2 mb file',

            /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
            contentType: ContentType.failure,
          ),
        );

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      } else if (size == 1000000) {
        final snackBar = SnackBar(
          /// need to set following properties for best effect of awesome_snackbar_content
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,

          content: AwesomeSnackbarContent(
            title: 'Error!',
            message:
            'upload less than 1 mb file',

            /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
            contentType: ContentType.failure,
          ),
        );

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
      return;
    }
  } else {
    // User canceled the picker
    return null;
  }
}
