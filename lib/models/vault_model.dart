class VaultModel {
  final String id;
  final String userId;
  final String documentName;
  final String category;
  final String fileUrl;
  final String storagePath;
  final String fileType;
  final int uploadedDate;

  VaultModel({
    required this.id,
    required this.userId,
    required this.documentName,
    required this.category,
    required this.fileUrl,
    required this.storagePath,
    required this.fileType,
    required this.uploadedDate,
  });

  /// True if this vault entry is a PDF document.
  bool get isPdf =>
      fileType.toLowerCase().contains('pdf') ||
      fileUrl.contains('application/pdf') ||
      fileUrl.toLowerCase().endsWith('.pdf');

  /// True if this vault entry is an image (jpg/jpeg/png).
  bool get isImage => !isPdf;

  /// True if the file bytes are embedded directly in [fileUrl] as a
  /// base64 data URI (the offline/no-Storage-access fallback), rather
  /// than living in Firebase Storage.
  bool get isDataUri => fileUrl.startsWith('data:');

  /// True if [fileUrl] is a real, fetchable network URL (Firebase
  /// Storage download URL).
  bool get isNetworkUrl => fileUrl.startsWith('http');

  /// Best-effort original file extension, used when saving a copy.
  String get fileExtension => isPdf ? 'pdf' : 'jpg';

  /// Best-effort MIME type. Reads the real type out of a `data:` URI when
  /// possible (e.g. `data:image/png;base64,...` → `image/png`), so a PNG
  /// isn't mislabeled as JPEG when opened in the browser.
  String get mimeType {
    if (isDataUri) {
      final match = RegExp(r'^data:([^;]+);').firstMatch(fileUrl);
      if (match != null) return match.group(1)!;
    }
    return isPdf ? 'application/pdf' : 'image/jpeg';
  }

  factory VaultModel.fromMap(Map<String, dynamic> map, String docId) {
    return VaultModel(
      id: docId,
      userId: map['userId'] ?? '',
      documentName: map['documentName'] ?? '',
      category: map['category'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      storagePath: map['storagePath'] ?? '',
      fileType: map['fileType'] ?? '',
      uploadedDate: map['uploadedDate'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'documentName': documentName,
      'category': category,
      'fileUrl': fileUrl,
      'storagePath': storagePath,
      'fileType': fileType,
      'uploadedDate': uploadedDate,
    };
  }
}
