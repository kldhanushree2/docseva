class ApplicationModel {
  final String id;
  final String applicationNumber;
  final String userId;
  final String userName;
  final String documentName;
  final String department;
  final String status;
  final String appliedDate;
  final String expectedDate;
  final String remarks;
  final int createdAt;
  final String acknowledgementPdf;
  final List<Map<String, dynamic>> timeline;

  ApplicationModel({
    required this.id,
    required this.applicationNumber,
    required this.userId,
    required this.userName,
    required this.documentName,
    required this.department,
    required this.status,
    required this.appliedDate,
    required this.expectedDate,
    required this.remarks,
    required this.createdAt,
    this.acknowledgementPdf = '',
    required this.timeline,
  });

  factory ApplicationModel.fromMap(Map<String, dynamic> map, String docId) {
    return ApplicationModel(
      id: docId,
      applicationNumber: map['applicationNumber'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      documentName: map['documentName'] ?? '',
      department: map['department'] ?? '',
      status: map['status'] ?? '',
      appliedDate: map['appliedDate'] ?? '',
      expectedDate: map['expectedDate'] ?? '',
      remarks: map['remarks'] ?? '',
      createdAt: map['createdAt'] ?? 0,
      acknowledgementPdf: map['acknowledgementPdf'] ?? '',
      timeline: List<Map<String, dynamic>>.from(map['timeline'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'applicationNumber': applicationNumber,
      'userId': userId,
      'userName': userName,
      'documentName': documentName,
      'department': department,
      'status': status,
      'appliedDate': appliedDate,
      'expectedDate': expectedDate,
      'remarks': remarks,
      'createdAt': createdAt,
      'acknowledgementPdf': acknowledgementPdf,
      'timeline': timeline,
    };
  }
}
