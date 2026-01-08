import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class CalendarService {
  CalendarService._();
  static final CalendarService instance = CalendarService._();

  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();
  static const _prefSelectedCalendarId = 'calendar_integration_id';
  static const _prefEnabled = 'calendar_integration_enabled';

  ValueNotifier<bool> isEnabled = ValueNotifier(false);
  String? _selectedCalendarId;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isEnabled.value = prefs.getBool(_prefEnabled) ?? false;
    _selectedCalendarId = prefs.getString(_prefSelectedCalendarId);
  }

  Future<bool> requestPermissions() async {
    var permissionsGranted = await _plugin.hasPermissions();
    if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
      permissionsGranted = await _plugin.requestPermissions();
      if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
        return false;
      }
    }
    return true;
  }

  Future<List<Calendar>> retrieveCalendars() async {
    if (!(await requestPermissions())) return [];
    final calendarsResult = await _plugin.retrieveCalendars();
    return calendarsResult.data ?? [];
  }

  Future<void> setCalendar(String calendarId) async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCalendarId = calendarId;
    await prefs.setString(_prefSelectedCalendarId, calendarId);
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    isEnabled.value = enabled;
    await prefs.setBool(_prefEnabled, enabled);
  }

  Future<void> exportSession({
    required DateTime startTime,
    required DateTime endTime,
    required String title,
    String? description,
  }) async {
    if (!isEnabled.value || _selectedCalendarId == null) return;

    // Ensure permissions
    if (!(await requestPermissions())) return;

    final tzLocation = tz.local;

    final event = Event(
      _selectedCalendarId!,
      title: title,
      description: description,
      start: tz.TZDateTime.from(startTime, tzLocation),
      end: tz.TZDateTime.from(endTime, tzLocation),
    );

    await _plugin.createOrUpdateEvent(event);
  }
}
