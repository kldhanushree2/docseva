class ReminderModel {
  final String id;
  final String userId;
  final String title;
  final String category;
  final String priority;
  final String notes;
  final int expiryDate;
  final int reminderDate;
  final String status;
  final String repeat;
  final int createdAt;

  ReminderModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.priority,
    required this.notes,
    required this.expiryDate,
    required this.reminderDate,
    required this.status,
    required this.repeat,
    required this.createdAt,
  });

  factory ReminderModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReminderModel(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      priority: map['priority'] ?? '',
      notes: map['notes'] ?? '',
      expiryDate: map['expiryDate'] ?? 0,
      reminderDate: map['reminderDate'] ?? 0,
      status: map['status'] ?? '',
      repeat: map['repeat'] ?? '',
      createdAt: map['createdAt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'category': category,
      'priority': priority,
      'notes': notes,
      'expiryDate': expiryDate,
      'reminderDate': reminderDate,
      'status': status,
      'repeat': repeat,
      'createdAt': createdAt,
    };
  }
}
