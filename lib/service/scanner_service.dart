import 'package:flutter/services.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';


class Camera {
  Future<void> scanDocument() async {
    //by default way they fetch pdf for android and png for iOS
    dynamic scannedDocuments;
    try {
      scannedDocuments = await FlutterDocScanner().getScanDocuments(page: 3) ??
          'Unknown platform documents';
    } on PlatformException {
      scannedDocuments = 'Failed to get scanned documents.';
    }
    print(scannedDocuments.toString());
  }
}