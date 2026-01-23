// Stub for non-web platforms
Future<void> pickAndUploadPhotoWeb(
  String userId,
  void Function(String url) onUploaded,
) async {
  // No-op on non-web platforms
}
