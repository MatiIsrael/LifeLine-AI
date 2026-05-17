import "package:flutter/material.dart";

enum EmergencyType {
  medical(Icons.medical_services_outlined, "Medical"),
  fire(Icons.local_fire_department_outlined, "Fire"),
  police(Icons.local_police_outlined, "Police");

  const EmergencyType(this.icon, this.label);
  final IconData icon;
  final String label;

  String get apiValue => name;
}
