import 'package:flutter/foundation.dart';

enum LogLevel { info, warn, error }

class LogEntry {
  final DateTime time;
  final String tag;
  final String message;
  final LogLevel level;

  LogEntry(this.tag, this.message, this.level) : time = DateTime.now();
}

/// A simple in-app log so problems (a hung upload, every AI model call
/// failing) are visible inside the running app itself — on a phone or in a
/// browser tab a user won't have DevTools/adb logcat open, so a plain
/// debugPrint() was invisible to anyone except a developer attached to the
/// process. Ring-buffered to the last 300 entries so it can't grow forever.
class AppLogger {
  AppLogger._();
  static final ValueNotifier<List<LogEntry>> logs = ValueNotifier([]);
  static const int _maxEntries = 300;

  static void log(String tag, String message, {LogLevel level = LogLevel.info}) {
    final entry = LogEntry(tag, message, level);
    final updated = [...logs.value, entry];
    if (updated.length > _maxEntries) {
      updated.removeRange(0, updated.length - _maxEntries);
    }
    logs.value = updated;

    // Also mirror to the standard debug console for anyone who IS attached
    // (flutter run / browser DevTools).
    debugPrint('[$tag] $message');
  }

  static void info(String tag, String message) => log(tag, message, level: LogLevel.info);
  static void warn(String tag, String message) => log(tag, message, level: LogLevel.warn);
  static void error(String tag, String message) => log(tag, message, level: LogLevel.error);

  static void clear() => logs.value = [];
}
