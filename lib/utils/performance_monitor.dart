import 'dart:developer' as developer;

class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, Duration> _durations = {};

  static void startTimer(String operation) {
    _startTimes[operation] = DateTime.now();
    developer.log('⏱️ Started: $operation', name: 'Performance');
  }

  static void endTimer(String operation) {
    final startTime = _startTimes[operation];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _durations[operation] = duration;
      developer.log('✅ Completed: $operation in ${duration.inMilliseconds}ms',
          name: 'Performance');
      _startTimes.remove(operation);
    }
  }

  static void logDuration(String operation, Duration duration) {
    _durations[operation] = duration;
    developer.log('📊 $operation took ${duration.inMilliseconds}ms',
        name: 'Performance');
  }

  static void printSummary() {
    developer.log('📈 Performance Summary:', name: 'Performance');
    _durations.forEach((operation, duration) {
      developer.log('  $operation: ${duration.inMilliseconds}ms',
          name: 'Performance');
    });
  }

  static void clear() {
    _startTimes.clear();
    _durations.clear();
  }
}
