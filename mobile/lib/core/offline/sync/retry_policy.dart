/// Exponential backoff for cloud sync retries in low-connectivity areas.
class RetryPolicy {
  static const maxRetries = 12;

  static Duration delayForAttempt(int attempt) {
    final capped = attempt.clamp(0, maxRetries);
    final seconds = (5 * (1 << capped)).clamp(5, 3600);
    return Duration(seconds: seconds);
  }

  static bool shouldRetry(int attempt) => attempt < maxRetries;
}
