// Stub for non-web platforms
Future<void> pickAndUploadPhotoWeb(
  String userId,
  Function(String url) onUploaded,
) async {
  // No-op on non-web platforms
}
