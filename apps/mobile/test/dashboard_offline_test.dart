import 'dart:convert';

import 'package:diabeta/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('dashboard retains a failed write and retries with the same ID',
      (tester) async {
    final payload = base64Url.encode(utf8.encode('{"sub":"demo-account"}'));
    final token = 'e30.$payload.fake';
    FlutterSecureStorage.setMockInitialValues({'token': token});
    var connected = false;
    final posts = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer $token');
      if (request.method == 'POST') {
        expect(request.url.path, '/glucose');
        posts.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response('{}', connected ? 201 : 503);
      }
      if (request.url.path == '/glucose' && connected) {
        return http.Response(jsonEncode([posts.first]), 200);
      }
      return http.Response('[]', 200);
    });
    addTearDown(client.close);

    await http.runWithClient(() async {
      await tester
          .pumpWidget(MaterialApp(home: Dashboard(onLogout: () async {})));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Registrar glucosa'), 120);
      await tester.tap(find.text('Registrar glucosa'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '123');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(posts, hasLength(1));
      tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.text('Lecturas de glucosa pendientes de sincronizar: 1'),
          findsOneWidget);

      connected = true;
      final refresh =
          tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
      await refresh.onRefresh();
      await tester.pumpAndSettle();
      expect(posts, hasLength(2));
      expect(posts.last, posts.first);
      expect(find.text('Lecturas de glucosa pendientes de sincronizar: 1'),
          findsNothing);
      expect(find.text('123.0 mg/dL'), findsOneWidget);
    }, () => client);
  });
}
