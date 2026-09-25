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
