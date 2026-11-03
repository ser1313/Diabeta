import 'package:diabeta/api_client.dart';
import 'package:diabeta/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login valida campos y no llama a la API con datos vacíos',
      (tester) async {
    var authenticateCalls = 0;
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(
        onAuthenticate: ({
          required String email,
          required String password,
          required bool register,
          String? firstName,
        }) async {
          authenticateCalls++;
        },
        onLogin: () {},
      ),
    ));

    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pump();

    expect(find.text('Introduce tu correo electrónico.'), findsOneWidget);
    expect(find.text('Introduce tu contraseña.'), findsOneWidget);
    expect(authenticateCalls, 0);
  });

  testWidgets('login normaliza email y no envía firstName', (tester) async {
    final request = <String, dynamic>{};
    var loginSuccesses = 0;
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(
        onAuthenticate: ({
          required String email,
          required String password,
          required bool register,
          String? firstName,
        }) async {
          request
            ..['email'] = email
            ..['password'] = password
            ..['register'] = register
            ..['firstName'] = firstName;
        },
        onLogin: () => loginSuccesses++,
      ),
    ));

    await tester.enterText(
      find.byKey(const Key('auth-email')),
      '  SERGIO@example.com ',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password')),
      'password-segura',
    );
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();

    expect(request['email'], 'sergio@example.com');
    expect(request['password'], 'password-segura');
    expect(request['register'], isFalse);
    expect(request['firstName'], isNull);
    expect(loginSuccesses, 1);
  });

  testWidgets('registro exige nombre y contraseña de al menos ocho caracteres',
      (tester) async {
    var authenticateCalls = 0;
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(
        onAuthenticate: ({
          required String email,
          required String password,
          required bool register,
          String? firstName,
        }) async {
          authenticateCalls++;
        },
        onLogin: () {},
      ),
    ));

    await tester.tap(find.byKey(const Key('auth-toggle-mode')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'sergio@example.com',
    );
    await tester.enterText(find.byKey(const Key('auth-password')), 'abc');
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pump();

    expect(find.text('Introduce tu nombre.'), findsOneWidget);
    expect(
      find.text('La contraseña debe tener al menos 8 caracteres.'),
      findsOneWidget,
    );
    expect(authenticateCalls, 0);
  });

  testWidgets('registro envía el nombre y muestra error de límite de intentos',
      (tester) async {
    final request = <String, dynamic>{};
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(
        onAuthenticate: ({
          required String email,
          required String password,
          required bool register,
          String? firstName,
        }) async {
          request
            ..['email'] = email
            ..['password'] = password
            ..['register'] = register
            ..['firstName'] = firstName;
          throw const ApiException(429, 'rate limited');
        },
        onLogin: () {},
      ),
    ));

    await tester.tap(find.byKey(const Key('auth-toggle-mode')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('auth-first-name')),
      'Sergio',
    );
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'sergio@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password')),
      'password-segura',
    );
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();

    expect(request['register'], isTrue);
    expect(request['firstName'], 'Sergio');
    expect(
      find.text(
        'Demasiados intentos. Espera un minuto antes de volver a intentarlo.',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('auth-submit'))).onPressed,
      isNotNull,
    );
  });
}
