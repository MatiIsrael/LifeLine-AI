class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final String contactEmail;
  final String contactUid;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.contactEmail = "",
    this.contactUid = "",
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "phoneNumber": phoneNumber,
        "relationship": relationship,
        "contactEmail": contactEmail,
        "contactUid": contactUid,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json, {String id = ""}) =>
      EmergencyContact(
        id: id,
        name: json["name"] ?? "",
        phoneNumber: json["phoneNumber"] ?? "",
        relationship: json["relationship"] ?? "",
        contactEmail: json["contactEmail"] ?? "",
        contactUid: json["contactUid"] ?? "",
      );
}
