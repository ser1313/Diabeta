import 'dart:async';

import 'package:diabeta/offline_glucose_queue.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final recordedAt = DateTime.utc(2026, 11, 21, 10);

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('persists stable UUIDs and isolates accounts and API origins', () async {
    final queue = OfflineGlucoseQueue.forAccount('api-one:account-one');
    final saved = await queue.enqueue(128, recordedAt);
    final reopened = OfflineGlucoseQueue.forAccount('api-one:account-one');
    final reading = (await reopened.pending()).single;

    expect(reading.toPayload(), saved.toPayload());
    expect(
      reading.clientRequestId,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(reading.toPayload()['recordedAt'], '2026-11-21T10:00:00.000Z');
    expect(
      await OfflineGlucoseQueue.forAccount('api-one:account-two').pending(),
      isEmpty,
    );
    expect(
      await OfflineGlucoseQueue.forAccount('api-two:account-one').pending(),
      isEmpty,
    );
  });

  test(
    'retains an ambiguous failure and allows other readings to sync',
    () async {
      final queue = OfflineGlucoseQueue.forAccount('account');
      final first = await queue.enqueue(120, recordedAt);
      final second = await queue.enqueue(121, recordedAt);
      final attempts = <String>[];

      final result = await queue.drain((entry) async {
        attempts.add(entry.clientRequestId);
        if (entry.clientRequestId == first.clientRequestId) {
          throw TimeoutException('No acknowledgement');
        }
      });

      expect(attempts, [first.clientRequestId, second.clientRequestId]);
      expect(result.synced, 1);
      expect(result.remaining, 1);
      expect((await queue.pending()).single.toPayload(), first.toPayload());

      await queue.drain((entry) async {
        expect(entry.toPayload(), first.toPayload());
      });
      expect(await queue.pending(), isEmpty);
    },
  );

  test(
    'allows enqueue during upload and serializes drains across instances',
    () async {
      final queue = OfflineGlucoseQueue.forAccount('account');
      final anotherInstance = OfflineGlucoseQueue.forAccount('account');
      final first = await queue.enqueue(120, recordedAt);
      final sending = Completer<void>();
      final acknowledge = Completer<void>();
      final attempted = <String>[];

      final firstDrain = queue.drain((entry) async {
        attempted.add(entry.clientRequestId);
        sending.complete();
        await acknowledge.future;
      });
      await sending.future;
      final secondDrain = anotherInstance.drain((entry) async {
        attempted.add(entry.clientRequestId);
      });
      final second = await anotherInstance.enqueue(121, recordedAt);
      expect(attempted, [first.clientRequestId]);
      acknowledge.complete();

      expect((await firstDrain).remaining, 1);
      expect((await secondDrain).remaining, 0);
      expect(attempted, [first.clientRequestId, second.clientRequestId]);
    },
  );

  test(
    'stops on session change and retains readings after a paused retry',
    () async {
      final queue = OfflineGlucoseQueue.forAccount('account');
      final first = await queue.enqueue(120, recordedAt);
      final second = await queue.enqueue(121, recordedAt);
      var sessionActive = true;

      final firstResult = await queue.drain((entry) async {
        expect(entry.clientRequestId, first.clientRequestId);
        sessionActive = false;
      }, shouldContinue: () => sessionActive);
      expect(firstResult.synced, 1);
      expect(firstResult.remaining, 1);

      final secondResult = await queue.drain((entry) async {
        throw TimeoutException('No connection');
      }, shouldPause: (error) => error is TimeoutException);
      expect(secondResult.synced, 0);
      expect(secondResult.remaining, 1);
      expect((await queue.pending()).single.toPayload(), second.toPayload());
    },
  );
}
