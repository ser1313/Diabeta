import 'dart:async';

import 'package:diabeta/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient(baseUrl: 'https://example.invalid');

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'token': 'test-token'});
  });

  test('GET sends the same headers as writes and preserves JSON shapes',
      () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.headers['Accept'], 'application/json');
      expect(request.headers['Authorization'], 'Bearer test-token');
      return http.Response(
        request.url.path == '/list' ? '[{"value": 123}]' : '{"value": 123}',
        200,
      );
    });
    addTearDown(client.close);

    await http.runWithClient(() async {
      expect(await api.getList('/list'), [
        {'value': 123},
      ]);
      expect(await api.getMap('/map'), {'value': 123});
    }, () => client);
  });

  test('GET returns a structured API error without exposing a raw response',
      () async {
    final client = MockClient((request) async => http.Response(
          request.url.path == '/list'
              ? '{"message":["Error de prueba"],"internalDetails":"sensitive"}'
              : '<html>internal details</html>',
          401,
        ));
    addTearDown(client.close);

    await http.runWithClient(() async {
      await expectLater(
        api.getList('/list'),
        throwsA(isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having((error) => error.message, 'message', 'Error de prueba')),
      );
      await expectLater(
        api.getMap('/map'),
        throwsA(isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having((error) => error.message, 'message',
                'La petición no se ha podido completar.')),
      );
    }, () => client);
  });

  test('GET rejects malformed JSON and an unexpected JSON shape', () async {
    final client = MockClient((request) async => http.Response(
          request.url.path == '/list' ? '{"value": 123}' : 'invalid JSON',
          200,
        ));
    addTearDown(client.close);

    await http.runWithClient(() async {
      final badResponse = throwsA(
        isA<ApiException>().having((error) => error.statusCode, 'statusCode', 502),
      );
      await expectLater(api.getList('/list'), badResponse);
      await expectLater(api.getMap('/map'), badResponse);
    }, () => client);
  });

  test('Reads and writes can pin a session instead of using stored credentials',
      () async {
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer pinned-token');
      if (request.method == 'POST') {
        expect(request.body, '{"value":123}');
        return http.Response('{"value":123}', 201);
      }
      return http.Response(
        request.url.path == '/list' ? '[{"value":123}]' : '{"value":123}',
        200,
      );
    });
    addTearDown(client.close);

    await http.runWithClient(() async {
      expect(
        await api.post('/glucose', {'value': 123}, sessionToken: 'pinned-token'),
        {'value': 123},
      );
      expect(await api.getList('/list', sessionToken: 'pinned-token'), [
        {'value': 123},
      ]);
      expect(await api.getMap('/map', sessionToken: 'pinned-token'),
          {'value': 123});
    }, () => client);
  });

  testWidgets('GET list and map stop waiting after the request timeout',
      (tester) async {
    final pending = Completer<http.Response>();
    final client = MockClient((_) => pending.future);
    addTearDown(client.close);
    final failures = http.runWithClient(
      () => Future.wait([
        expectLater(api.getList('/list'), throwsA(isA<TimeoutException>())),
        expectLater(api.getMap('/map'), throwsA(isA<TimeoutException>())),
      ]),
      () => client,
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 15));
    await failures;
    pending.complete(http.Response('{}', 200));
  });
}
