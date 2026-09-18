/// Exponential backoff: 1s, 2s, 4s, … capped at 5 minutes.
/// No jitter by design: deterministic schedule = deterministic tests;
/// single-device MVP has no thundering-herd problem to solve.
Duration backoffForAttempt(int retryCount) {
  // Clamp the shift first (avoid 64-bit overflow), then the seconds cap.
  var seconds = 1 << retryCount.clamp(0, 9);
  if (seconds > 300) seconds = 300;
  return Duration(seconds: seconds);
}

/// Give up after this many attempts (~hours of backing off), then mark
/// failed so a human sees it instead of an infinite silent queue.
const maxAttempts = 25;
