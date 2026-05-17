/// Network quality for weak-internet optimization.
enum ConnectivityQuality {
  offline,
  weak,
  online,
}

extension ConnectivityQualityX on ConnectivityQuality {
  bool get canAttemptCloud => this != ConnectivityQuality.offline;
  bool get preferSmsFallback => this == ConnectivityQuality.offline;
  bool get deferHeavyUploads => this == ConnectivityQuality.weak;
}
