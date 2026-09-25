class GovServiceModel {
  final String id;
  final String title;
  final String description;
  final String eligibility;
  final String documentsRequired;
  final String officialWebsite;
  final String fees;
  final String processingTime;
  // Whether the application itself can be completed fully online without an
  // in-person visit / physical wet-ink signature. Shown as a badge in the
  // list and explained in the description on the detail screen.
  final bool onlineApplicable;
  final String onlineNote;

  GovServiceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.eligibility,
    required this.documentsRequired,
    required this.officialWebsite,
    required this.fees,
    required this.processingTime,
    this.onlineApplicable = false,
    this.onlineNote = '',
  });

  factory GovServiceModel.fromMap(Map<String, dynamic> map, String docId) {
    return GovServiceModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      eligibility: map['eligibility'] ?? '',
      documentsRequired: map['documentsRequired'] ?? '',
      officialWebsite: map['officialWebsite'] ?? '',
      fees: map['fees'] ?? '',
      processingTime: map['processingTime'] ?? '',
      onlineApplicable: map['onlineApplicable'] ?? false,
      onlineNote: map['onlineNote'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'eligibility': eligibility,
      'documentsRequired': documentsRequired,
      'officialWebsite': officialWebsite,
      'fees': fees,
      'processingTime': processingTime,
      'onlineApplicable': onlineApplicable,
      'onlineNote': onlineNote,
    };
  }
}
