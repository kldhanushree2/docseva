import 'package:flutter/material.dart';
import '../../models/gov_service_model.dart';
import 'service_detail_screen.dart';

class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  String _searchQuery = '';

  final List<GovServiceModel> _allServices = [
    GovServiceModel(
      id: "1",
      title: "Aadhaar Card",
      description: "12-digit Unique Identification Number issued by UIDAI.",
      eligibility: "All resident Indian citizens (including infants).",
      documentsRequired: "Proof of Identity (PAN/Voter ID), Proof of Address (Electricity bill/Passport), Proof of Date of Birth.",
      officialWebsite: "https://myaadhaar.uidai.gov.in/",
      fees: "Free for New Enrollment; ₹ 50 for Demographics update",
      processingTime: "15 to 90 Days",
      onlineApplicable: false,
      onlineNote: "Partly online: address/demographic updates and e-Aadhaar download can be done fully online via OTP on myaadhaar.uidai.gov.in. New enrollment or a biometric update needs an in-person visit to an Aadhaar Seva Kendra — it is not fully online.",
    ),
    GovServiceModel(
      id: "2",
      title: "PAN Card",
      description: "10-digit alphanumeric tax identifier issued by Income Tax Department.",
      eligibility: "All individual citizens, NRIs, businesses, and taxpayers.",
      documentsRequired: "Aadhaar Card, Passport size photos, Identity & Address Proof.",
      officialWebsite: "https://www.incometax.gov.in/iec/foportal/",
      fees: "Free (Instant e-PAN) / ₹ 107 (Physical card via Protean/UTIITSL)",
      processingTime: "Minutes (Instant e-PAN) / 7 to 15 Days (Physical card)",
      onlineApplicable: true,
      onlineNote: "Fully online: the Instant e-PAN facility on the Income Tax e-filing portal issues a valid e-PAN in minutes using only your Aadhaar number and an OTP — no physical or digital signature needed. (A laminated physical card via Protean/UTIITSL is a separate, paid, non-instant option.)",
    ),
    GovServiceModel(
      id: "3",
      title: "Passport",
      description: "Official travel document issued by Ministry of External Affairs.",
      eligibility: "Indian citizens of all ages.",
      documentsRequired: "Aadhaar Card, Birth Certificate, Educational Certificates, Address Proof.",
      officialWebsite: "https://www.passportindia.gov.in/",
      fees: "₹ 1,500 (Fresh 36 pages) / ₹ 2,000 (60 pages) / ₹ 3,500 (Tatkaal)",
      processingTime: "15 to 30 Days (Normal) / 3 to 7 Days (Tatkaal)",
      onlineApplicable: false,
      onlineNote: "Not fully online: you can fill and pay for the form online, but you must still visit a Passport Seva Kendra (PSK) in person for biometrics, document verification, and signature.",
    ),
    GovServiceModel(
      id: "4",
      title: "Voter ID (EPIC)",
      description: "Elector's Photo Identity Card for voting in elections.",
      eligibility: "Indian citizens aged 18 years or above on qualifying date.",
      documentsRequired: "Age Proof (Aadhaar/10th Marksheet), Address Proof, Passport size photo.",
      officialWebsite: "https://voters.eci.gov.in/",
      fees: "Free",
      processingTime: "15 to 30 Days",
      onlineApplicable: true,
      onlineNote: "Fully online submission: Form 6 (new registration) is filled and submitted entirely on voters.eci.gov.in with uploaded documents — no signature required at submission. A Booth Level Officer does a field visit afterward as part of verification, not application.",
    ),
    GovServiceModel(
      id: "5",
      title: "Driving License",
      description: "Official permit authorizing driving motorized vehicles on public roads.",
      eligibility: "Age 18+ for geard vehicles; Age 16+ for gearless 50cc; Must hold valid Learner License.",
      documentsRequired: "Learner License Number, Aadhaar Card, Medical Certificate Form 1A (if >40 yrs).",
      officialWebsite: "https://sarathi.parivahan.gov.in/",
      fees: "₹ 200 (Test) + ₹ 200 (Issue) + Smart Card fees",
      processingTime: "30 to 45 Days",
      onlineApplicable: false,
      onlineNote: "Partly online: the Learner's Licence application (and its test, in several states) can be completed fully online on the Sarathi portal. The permanent DL requires an in-person practical test and biometric capture at the RTO — not fully online.",
    ),
    GovServiceModel(
      id: "6",
      title: "Income Certificate (Tamil Nadu)",
      description: "Government certified record proving an individual or family's annual income issued by Revenue Dept.",
      eligibility: "Residents needing certificate for scholarships, tax exemption, or government schemes.",
      documentsRequired: "Salary slip / IT Return / Form 16, Aadhaar Card, Electricity bill, Self-declaration affidavit.",
      officialWebsite: "https://www.tnesevai.tn.gov.in/",
      fees: "₹ 60 (Application & Processing Fee)",
      processingTime: "10 to 15 Days",
      onlineApplicable: true,
      onlineNote: "Fully online via the TN e-Sevai portal: apply, upload documents, and download the signed digital certificate without visiting an office. (Listed as a \"Fully Online\" service on the National Government Services Portal.)",
    ),
    GovServiceModel(
      id: "7",
      title: "Caste / Community Certificate (Tamil Nadu)",
      description: "Official document certifying membership in SC/ST/OBC/BC community issued by Revenue Department.",
      eligibility: "Citizens belonging to recognized SC, ST, BC, or OBC communities in Tamil Nadu.",
      documentsRequired: "Father's Community Certificate, Applicant's School Leaving Certificate, Aadhaar, Affidavit.",
      officialWebsite: "https://www.tnesevai.tn.gov.in/",
      fees: "₹ 60",
      processingTime: "15 to 30 Days",
      onlineApplicable: true,
      onlineNote: "Fully online via the TN e-Sevai portal: application, document upload, and digitally signed certificate download all happen online, without a physical signature.",
    ),
    GovServiceModel(
      id: "8",
      title: "Smart Ration Card (Tamil Nadu TNPDS)",
      description: "Official smart card issued for subsidized food grains under Tamil Nadu Public Distribution System.",
      eligibility: "Resident households categorized under APL, BPL, or Antyodaya (AAY).",
      documentsRequired: "Head of Family Aadhaar, Family photo, Income certificate, Electricity bill, Gas connection bill.",
      officialWebsite: "https://www.tnpds.gov.in/",
      fees: "Free / ₹ 20 for card print",
      processingTime: "15 to 30 Days",
      onlineApplicable: false,
      onlineNote: "Not fully online: the application and field-verification request can be submitted online, but the physical smart card itself must be collected in person from the local ration shop / e-Sevai centre.",
    ),
    GovServiceModel(
      id: "9",
      title: "Patta / Chitta Land Records (Tamil Nadu)",
      description: "Certified document showing land ownership, survey number, and village land records in Tamil Nadu.",
      eligibility: "Agricultural land owners and property buyers in Tamil Nadu.",
      documentsRequired: "District, Taluk, Village, Survey Number, Sub-division Number.",
      officialWebsite: "https://eservices.tn.gov.in/eservicesnew/index.html",
      fees: "Free online view / ₹ 60 for certified copy",
      processingTime: "Instant Online View / 7 Days for Certified Copy",
      onlineApplicable: true,
      onlineNote: "Fully online for viewing/downloading: verified with OTP, no signature or office visit needed to view or download a Patta/Chitta/A-Register extract. Only a physically stamped certified copy requires an e-Sevai visit.",
    ),
    GovServiceModel(
      id: "10",
      title: "Marriage Certificate (Tamil Nadu STAR 2.0)",
      description: "Legal proof of marriage registered under Hindu Marriage Act or Special Marriage Act.",
      eligibility: "Groom age 21+, Bride age 18+, Marriage solemnized in Tamil Nadu.",
      documentsRequired: "Marriage Invitation card, Ceremony photos, Age & Address Proof of spouses, 3 Witnesses.",
      officialWebsite: "https://tnreginet.gov.in/",
      fees: "₹ 100 to ₹ 500 depending on registration Act",
      processingTime: "15 to 30 Days",
      onlineApplicable: false,
      onlineNote: "Not fully online: the application form can be filled online on TNREGINET, but registration legally requires both spouses and three witnesses to appear in person before the Registrar to sign the register — a physical signature is mandatory.",
    ),
    GovServiceModel(
      id: "11",
      title: "Encumbrance Certificate (EC) (Tamil Nadu)",
      description: "Official document showing property transaction history and legal encumbrance in Tamil Nadu.",
      eligibility: "Property buyers, owners, and bank loan applicants.",
      documentsRequired: "Zone, District, Sub-Registrar Office, Survey Number, Document Number, Date Range.",
      officialWebsite: "https://tnreginet.gov.in/",
      fees: "Free online search / Nominal fee for signed copy",
      processingTime: "Instant Search / 3 Days for Certified Copy",
      onlineApplicable: true,
      onlineNote: "Fully online: search and digitally-signed EC download are both done on TNREGINET without visiting a Sub-Registrar office or signing anything physically.",
    ),
    GovServiceModel(
      id: "12",
      title: "Birth Certificate",
      description: "Official record documenting the birth of a child issued by Civil Registration System.",
      eligibility: "Child born in India (Application submitted within 21 days of birth).",
      documentsRequired: "Hospital Discharge Summary / Birth Slip, Parent's Aadhaar & Marriage Certificate.",
      officialWebsite: "https://crsorgi.gov.in/",
      fees: "Free within 21 days; Nominal late fee thereafter",
      processingTime: "7 to 14 Days",
      onlineApplicable: false,
      onlineNote: "Not fully online: application can be initiated on the CRS portal, but the certificate is issued by the local Municipal/Panchayat registrar and typically needs in-person submission of the hospital birth slip for verification.",
    ),
    GovServiceModel(
      id: "13",
      title: "Ayushman Bharat Health Card (PM-JAY)",
      description: "Health insurance card offering up to ₹ 5 Lakh free hospitalization per family per year.",
      eligibility: "Low-income families listed in SECC 2011 database or Ration Card holders.",
      documentsRequired: "Aadhaar Card, Ration Card, Active Mobile Number.",
      officialWebsite: "https://beneficiary.nha.gov.in/",
      fees: "Free",
      processingTime: "Instant / 24 Hours",
      onlineApplicable: true,
      onlineNote: "Fully online for eligible beneficiaries: eKYC via Aadhaar OTP and instant e-card download, no signature or office visit required.",
    ),
    GovServiceModel(
      id: "14",
      title: "PF / UAN Member Passbook (EPFO)",
      description: "Employees Provident Fund account details, balance passbook, and claim status.",
      eligibility: "Salaried employees holding 12-digit UAN number.",
      documentsRequired: "UAN Number, Registered Mobile Number, Aadhaar.",
      officialWebsite: "https://unifiedportal-mem.epfindia.gov.in/memberinterface/",
      fees: "Free",
      processingTime: "Instant Passbook Download",
      onlineApplicable: true,
      onlineNote: "Fully online: login with your UAN and OTP to view or download your passbook — no signature or office visit needed.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredServices = _allServices.where((service) {
      final query = _searchQuery.toLowerCase();
      return service.title.toLowerCase().contains(query) ||
          service.description.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Government Guide')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search government services...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: filteredServices.isEmpty
                ? const Center(child: Text('No matching government services found'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredServices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final service = filteredServices[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: const Icon(Icons.description, color: Colors.green),
                          ),
                          title: Text(service.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(service.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: service.onlineApplicable ? Colors.green[50] : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: service.onlineApplicable ? Colors.green[300]! : Colors.orange[300]!,
                                  ),
                                ),
                                child: Text(
                                  service.onlineApplicable ? 'Fully Online' : 'Needs In-Person Visit',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: service.onlineApplicable ? Colors.green[800] : Colors.orange[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: service)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
