mixin RetryMixin {
  Future<void> loadWithRetry(Future<void> Function() fn) async {
    int attempts = 0;
    while (attempts < 3) {
      try {
        await fn();
        return;
      } catch (e) {
        attempts++;
        if (attempts == 3) rethrow;
        await Future.delayed(Duration(seconds: 2 * attempts));
      }
    }
  }
}
