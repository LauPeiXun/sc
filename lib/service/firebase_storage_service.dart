import 'package:cross_file/cross_file.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadPdf({required String userId, required XFile xfile}) async {
    final bytes = await xfile.readAsBytes();
    final ref = FirebaseStorage.instance.ref('scanned_pdfs/$userId/${DateTime.now().millisecondsSinceEpoch}.pdf');
    await ref.putData(bytes, SettableMetadata(contentType: 'application/pdf'));
    return await ref.getDownloadURL();
  }
}