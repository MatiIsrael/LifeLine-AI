class UserProfile {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String bloodGroup;
  final String medicalNotes;

  UserProfile({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.bloodGroup,
    required this.medicalNotes,
  });

  Map<String, dynamic> toJson() => {
        "fullName": fullName,
        "email": email,
        "phoneNumber": phoneNumber,
        "bloodGroup": bloodGroup,
        "medicalNotes": medicalNotes,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        fullName: json["fullName"] ?? "",
        email: json["email"] ?? "",
        phoneNumber: json["phoneNumber"] ?? "",
        bloodGroup: json["bloodGroup"] ?? "",
        medicalNotes: json["medicalNotes"] ?? "",
      );
}
