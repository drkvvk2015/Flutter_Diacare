// Only imported on web - modernized to use package:web
import 'package:web/web.dart' as web;
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:js_interop';

Future<void> pickAndUploadPhotoWeb(
  String userId,
  Function(String url) onUploaded,
) async {
  final uploadInput = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/*';
  uploadInput.click();

  // Use a more compatible event handling approach
  uploadInput.onchange = (web.Event e) {
    final target = e.target as web.HTMLInputElement;
    final files = target.files;
    if (files == null || files.length == 0) return;

    final file = files.item(0)!;
    final reader = web.FileReader();

    // Set up the onload callback
    reader.onload = (web.ProgressEvent e) {
      final result = reader.result as JSArrayBuffer;
      final buffer = result.toDart;
      final data = Uint8List.view(buffer);

      // Upload the file (fire and forget)
      _uploadFile(userId, data, onUploaded);
    }.toJS;

    reader.readAsArrayBuffer(file);
  }.toJS;
}

Future<void> _uploadFile(
  String userId,
  Uint8List data,
  Function(String url) onUploaded,
) async {
  final ref = FirebaseStorage.instance.ref().child(
    'profile_photos/$userId.jpg',
  );
  await ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));
  final url = await ref.getDownloadURL();
  onUploaded(url);
}
