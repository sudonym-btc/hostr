import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../../util/custom_logger.dart';
import '../listings/listings.dart';
import '../metadata/metadata.dart';
import '../user_subscriptions/user_subscriptions.dart';

abstract class CalendarPort {
  Future<void> ensureCalendar({required String name});

  Future<void> upsert(CalendarEntry entry);
}

class NoopCalendarPort implements CalendarPort {
  const NoopCalendarPort();

  @override
  Future<void> ensureCalendar({required String name}) async {}

  @override
  Future<void> upsert(CalendarEntry entry) async {}
}

class CalendarEntry extends Equatable {
  static const defaultReminders = [Duration(days: 7), Duration(days: 1)];

  final String tradeId;
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  final bool isAllDay;
  final List<Duration> reminders;

  const CalendarEntry({
    required this.tradeId,
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    this.isAllDay = true,
    this.reminders = defaultReminders,
  });

  @override
  List<Object?> get props => [
    tradeId,
    title,
    description,
    start,
    end,
    isAllDay,
    reminders,
  ];
}

/// Pure-Dart calendar sync planner.
///
/// This class depends on Hostr internals for lifecycle and event derivation,
/// but delegates all platform-specific calendar work to [CalendarPort].
@singleton
class Calendar {
  final UserSubscriptions _userSubscriptions;
  final Listings _listings;
  final MetadataUseCase _metadata;
  final CustomLogger _logger;
  final CalendarPort? _port;

  final Map<String, CalendarEntry> _publishedEntries = {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _started = false;

  static const _calendarName = 'Hostr';

  Calendar({
    required UserSubscriptions userSubscriptions,
    required Listings listings,
    required MetadataUseCase metadata,
    required CustomLogger logger,
    CalendarPort? port,
  }) : _userSubscriptions = userSubscriptions,
       _listings = listings,
       _metadata = metadata,
       _logger = logger,
       _port = port;

  Future<void> start() => _logger.span('start', () async {
    if (_started || _port == null) return;

    _started = true;
    _logger.d('Calendar: starting');

    try {
      await _port.ensureCalendar(name: _calendarName);
    } catch (e, st) {
      _logger.e(
        'Calendar: failed to initialise calendar port',
        error: e,
        stackTrace: st,
      );
      _started = false;
      return;
    }

    _logger.d('Calendar: subscribed to hosting and trip updates');

    _subscriptions.add(
      _userSubscriptions.myHostings$.itemsStream.listen(
        _onHostingSnapshot,
        onError: (e, st) => _logger.w(
          'Calendar: hostings stream error',
          error: e,
          stackTrace: st,
        ),
      ),
    );

    _subscriptions.add(
      _userSubscriptions.myTrips$.itemsStream.listen(
        _onTripSnapshot,
        onError: (e, st) =>
            _logger.w('Calendar: trips stream error', error: e, stackTrace: st),
      ),
    );
  });

  Future<void> stop() => _logger.span('stop', () async {
    if (!_started) return;
    _started = false;
    _logger.d('Calendar: stopping');

    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _publishedEntries.clear();
  });

  Future<void> _onHosting(Validation<ReservationPair> validation) =>
      _logger.span('_onHosting', () async {
        if (validation is! Valid<ReservationPair>) return;
        final pair = validation.event;
        if (!_isFuture(pair)) return;

        try {
          final guestPubkey = _resolveGuestPubkey(pair);
          String guestName = 'Guest';
          if (guestPubkey != null) {
            final profile = await _metadata.loadMetadata(guestPubkey);
            guestName = profile?.metadata.getName() ?? _shortKey(guestPubkey);
          }

          final listingName = await _resolveListingName(pair.listingAnchor);
          final entry = _buildEntry(
            tradeId: pair.tradeId,
            pair: pair,
            baseTitle: 'Hosting $guestName at $listingName',
          );
          await _publishEntry(entry);
        } catch (e, st) {
          _logger.w(
            'Calendar: failed to sync hosting ${pair.tradeId}',
            error: e,
            stackTrace: st,
          );
        }
      });

  Future<void> _onTrip(Validation<ReservationPair> validation) =>
      _logger.span('_onTrip', () async {
        if (validation is! Valid<ReservationPair>) return;
        final pair = validation.event;
        if (!_isFuture(pair)) return;

        try {
          final hostProfile = await _metadata.loadMetadata(pair.hostPubkey);
          final hostName =
              hostProfile?.metadata.getName() ?? _shortKey(pair.hostPubkey);

          final listingName = await _resolveListingName(pair.listingAnchor);
          final entry = _buildEntry(
            tradeId: pair.tradeId,
            pair: pair,
            baseTitle: 'Visiting $listingName hosted by $hostName',
          );
          await _publishEntry(entry);
        } catch (e, st) {
          _logger.w(
            'Calendar: failed to sync trip ${pair.tradeId}',
            error: e,
            stackTrace: st,
          );
        }
      });

  Future<void> _onHostingSnapshot(
    List<Validation<ReservationPair>> validations,
  ) => _logger.span('_onHostingSnapshot', () async {
    for (final validation in validations) {
      await _onHosting(validation);
    }
  });

  Future<void> _onTripSnapshot(List<Validation<ReservationPair>> validations) =>
      _logger.span('_onTripSnapshot', () async {
        for (final validation in validations) {
          await _onTrip(validation);
        }
      });

  Future<void> _publishEntry(CalendarEntry entry) =>
      _logger.span('_publishEntry', () async {
        final port = _port;
        if (port == null) return;

        final previous = _publishedEntries[entry.tradeId];
        if (previous == entry) {
          return;
        }

        await port.upsert(entry);
        _publishedEntries[entry.tradeId] = entry;
      });

  CalendarEntry _buildEntry({
    required String tradeId,
    required ReservationPair pair,
    required String baseTitle,
  }) {
    final start = pair.start;
    final end = pair.end;
    if (start == null || end == null) {
      throw StateError('Calendar entry requires both start and end dates');
    }

    return CalendarEntry(
      tradeId: tradeId,
      title: _buildTitle(pair: pair, baseTitle: baseTitle),
      description: _buildDescription(tradeId: tradeId, start: start, end: end),
      start: start,
      end: end,
      isAllDay: true,
      reminders: CalendarEntry.defaultReminders,
    );
  }

  Future<String> _resolveListingName(String listingAnchor) =>
      _logger.span('_resolveListingName', () async {
        try {
          final listing = await _listings.getOneByAnchor(listingAnchor);
          return listing?.title ?? 'Unknown listing';
        } catch (_) {
          return 'Unknown listing';
        }
      });

  String? _resolveGuestPubkey(ReservationPair pair) {
    final tweakedPubkey =
        pair.buyerReservation?.recipient ?? pair.buyerReservation?.pubKey;
    final tweakMaterial = pair.buyerReservation?.tweakMaterial;
    final salt = tweakMaterial?.salt;
    final parity = tweakMaterial?.parity;
    if (tweakedPubkey == null ||
        salt == null ||
        salt.isEmpty ||
        parity == null) {
      return null;
    }

    return untweakPublicKey(
      tweakedPublicKey: tweakedPubkey,
      tweakedPublicKeyParity: parity,
      salt: salt,
    );
  }

  bool _isFuture(ReservationPair pair) {
    final start = pair.start;
    final end = pair.end;
    if (start == null || end == null) return false;

    return start.isAfter(DateTime.now().toUtc());
  }

  String _buildTitle({
    required ReservationPair pair,
    required String baseTitle,
  }) {
    if (pair.cancelled) {
      return 'CANCELLED: $baseTitle';
    }
    return baseTitle;
  }

  String _buildDescription({
    required String tradeId,
    required DateTime start,
    required DateTime end,
  }) {
    return [
      'hostr_trade_id:$tradeId',
      'Start: ${_formatDateTime(start)}',
      'End: ${_formatDateTime(end)}',
    ].join('\n');
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

  String _shortKey(String pubkey) {
    if (pubkey.length <= 8) return pubkey;
    return '${pubkey.substring(0, 8)}…';
  }
}
