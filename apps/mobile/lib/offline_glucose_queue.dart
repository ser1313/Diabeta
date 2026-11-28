import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dashboard_history.dart';

class PendingGlucoseReading {
  final String clientRequestId;
  final double value;
  final DateTime recordedAt;

  const PendingGlucoseReading._(
    this.clientRequestId,
    this.value,
    this.recordedAt,
  );

  factory PendingGlucoseReading._fromPayload(Map<String, dynamic> payload) {
    return PendingGlucoseReading._(
      payload['clientRequestId'] as String,
      (payload['value'] as num).toDouble(),
      DateTime.parse(payload['recordedAt'] as String),
    );
  }

  Map<String, dynamic> toPayload() => {
    'clientRequestId': clientRequestId,
    'value': value,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
  };
}

class GlucoseSyncResult {
  final int synced;
  final int remaining;

  const GlucoseSyncResult({required this.synced, required this.remaining});
}

class OfflineGlucoseQueue {
  // Account IDs must include the API origin as well as the user ID. No session
  // token is stored here. Use the same account ID across sessions and restarts.
  OfflineGlucoseQueue.forAccount(
    String accountId, {
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _key = 'offline-glucose-v1:${base64Url.encode(utf8.encode(accountId))}',
       _storage = storage {
    if (accountId.trim().isEmpty) {
      throw ArgumentError.value(accountId, 'accountId', 'Required');
    }
  }

  final String _key;
  final FlutterSecureStorage _storage;
  static final _storageOperations = <String, Future<void>>{};
  static final _drains = <String, Future<void>>{};

  Future<PendingGlucoseReading> enqueue(double value, DateTime recordedAt) {
    if (!isValidGlucoseEntry(value)) {
      throw ArgumentError.value(value, 'value', 'Invalid glucose reading');
    }
    final reading = PendingGlucoseReading._(
      _uuidV4(),
      value,
      recordedAt.toUtc(),
    );
    return _serialize(_storageOperations, () async {
      final readings = await _read();
      await _write([...readings, reading]);
      return reading;
    });
  }

  Future<List<PendingGlucoseReading>> pending() =>
      _serialize(_storageOperations, _read);

  Future<void> clear() =>
      _serialize(_storageOperations, () => _storage.delete(key: _key));

  /// [send] must use the session for this queue and return only after server
  /// acknowledgement. Throw on every other outcome, including a timeout.
  /// [shouldContinue] can stop a drain after the session changes. [shouldPause]
  /// can stop it after a transient failure. Other failed items are kept while
  /// later items in the snapshot are still attempted.
  Future<GlucoseSyncResult> drain(
    Future<void> Function(PendingGlucoseReading) send, {
    bool Function()? shouldContinue,
    bool Function(Object error)? shouldPause,
  }) => _serialize(_drains, () async {
    var synced = 0;
    for (final reading in await pending()) {
      final stillPending = (await pending()).any(
        (entry) => entry.clientRequestId == reading.clientRequestId,
      );
      if (shouldContinue?.call() == false) break;
      if (!stillPending) continue;
      try {
        await send(reading);
      } catch (error) {
        if (shouldPause?.call(error) == true) break;
        continue;
      }
      await _serialize(_storageOperations, () async {
        final readings = await _read();
        final remaining =
            readings
                .where(
                  (entry) => entry.clientRequestId != reading.clientRequestId,
                )
                .toList();
        if (remaining.length != readings.length) await _write(remaining);
      });
      synced++;
    }
    return GlucoseSyncResult(
      synced: synced,
      remaining: (await pending()).length,
    );
  });

  Future<List<PendingGlucoseReading>> _read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return [];
    final entries = jsonDecode(raw) as List<dynamic>;
    return entries
        .map(
          (entry) =>
              PendingGlucoseReading._fromPayload(entry as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> _write(List<PendingGlucoseReading> readings) {
    if (readings.isEmpty) return _storage.delete(key: _key);
    return _storage.write(
      key: _key,
      value: jsonEncode(
        readings.map((reading) => reading.toPayload()).toList(),
      ),
    );
  }

  Future<T> _serialize<T>(
    Map<String, Future<void>> operations,
    Future<T> Function() work,
  ) {
    final previous = operations[_key] ?? Future<void>.value();
    final result = previous.then((_) => work());
    late final Future<void> tail;
    tail = result
        .then<void>((_) {}, onError: (Object _, StackTrace __) {})
        .whenComplete(() {
          if (identical(operations[_key], tail)) operations.remove(_key);
        });
    operations[_key] = tail;
    return result;
  }

  static String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
