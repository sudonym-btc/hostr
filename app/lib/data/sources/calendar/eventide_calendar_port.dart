import 'dart:ui';

import 'package:eventide/eventide.dart';
import 'package:flutter/foundation.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:permission_handler/permission_handler.dart';

class EventideCalendarPort implements CalendarPort {
  final Eventide _eventide;
  final CustomLogger _logger;

  String? _calendarId;
  String? _calendarName;
  final Map<String, ETEvent> _eventsByTradeId = {};

  EventideCalendarPort({Eventide? eventide, required CustomLogger logger})
    : _eventide = eventide ?? Eventide(),
      _logger = logger;

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<void> ensureCalendar({required String name}) async {
    if (!_isSupportedPlatform) return;
    _calendarName = name;
  }

  @override
  Future<void> upsert(CalendarEntry entry) async {
    if (!_isSupportedPlatform) return;

    final calendarId = await _ensureCalendarReady();
    if (calendarId == null) return;

    final existing = _eventsByTradeId[entry.tradeId];
    if (existing != null) {
      final matchesExisting =
          existing.title == entry.title &&
          existing.description == entry.description &&
          existing.startDate == entry.start &&
          existing.endDate == entry.end &&
          existing.isAllDay == entry.isAllDay &&
          listEquals(existing.reminders.toList(), entry.reminders);

      if (matchesExisting) {
        return;
      }

      await _eventide.deleteEvent(eventId: existing.id);
      _eventsByTradeId.remove(entry.tradeId);
    }

    final event = await _eventide.createEvent(
      calendarId: calendarId,
      title: entry.title,
      startDate: entry.start,
      endDate: entry.end,
      isAllDay: entry.isAllDay,
      description: entry.description,
      reminders: entry.reminders,
    );
    _eventsByTradeId[entry.tradeId] = event;
    _logger.d('EventideCalendarPort: upserted ${entry.tradeId}');
  }

  Future<String?> _ensureCalendarReady() async {
    if (!await _ensureCalendarPermission()) return null;

    final calendarName = _calendarName;
    if (calendarName == null || calendarName.isEmpty) {
      _logger.w('EventideCalendarPort: calendar name is not configured');
      return null;
    }

    final existingCalendarId = _calendarId;
    if (existingCalendarId != null) {
      return existingCalendarId;
    }

    final calendars = await _eventide.retrieveCalendars();
    for (final cal in calendars) {
      if (cal.title == calendarName) {
        _calendarId = cal.id;
        await _indexExistingEvents(cal.id);
        return cal.id;
      }
    }

    final created = await _eventide.createCalendar(
      title: calendarName,
      color: const Color(0xFFFF6B00),
    );
    _calendarId = created.id;
    _eventsByTradeId.clear();
    _logger.d('EventideCalendarPort: created calendar ${created.id}');
    return created.id;
  }

  Future<bool> _ensureCalendarPermission() async {
    try {
      var status = await Permission.calendarFullAccess.status;
      if (status.isGranted || status.isLimited) {
        return true;
      }

      status = await Permission.calendarFullAccess.request();
      if (status.isGranted || status.isLimited) {
        return true;
      }

      _logger.i('EventideCalendarPort: calendar permission not granted');
      return false;
    } catch (e, st) {
      _logger.w(
        'EventideCalendarPort: failed to request calendar permission',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  Future<void> _indexExistingEvents(String calendarId) async {
    try {
      final events = await _eventide.retrieveEvents(
        calendarId: calendarId,
        startDate: DateTime.now().subtract(const Duration(days: 365)),
        endDate: DateTime.now().add(const Duration(days: 365)),
      );

      _eventsByTradeId.clear();
      for (final event in events) {
        final tradeId = _extractTradeId(event.description);
        if (tradeId != null) {
          _eventsByTradeId[tradeId] = event;
        }
      }
      _logger.d(
        'EventideCalendarPort: indexed ${_eventsByTradeId.length} existing events',
      );
    } catch (e, st) {
      _logger.w(
        'EventideCalendarPort: failed to index existing events',
        error: e,
        stackTrace: st,
      );
    }
  }

  String? _extractTradeId(String? description) {
    if (description == null) return null;

    final match = RegExp(
      r'hostr_trade_id:([a-fA-F0-9]+)',
    ).firstMatch(description);
    return match?.group(1);
  }
}
