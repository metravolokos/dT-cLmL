import 'package:cloudmail_player/app/app.dart';
import 'package:cloudmail_player/app/state.dart';
import 'package:cloudmail_player/cloud/cloud_connection_service.dart';
import 'package:cloudmail_player/cloud/cloud_mail_webdav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConnectionService implements CloudConnectionService {
  _FakeConnectionService({this.nextError});

  String? savedUsername;
  String? savedPassword;
  CloudMailErrorCode? nextError;

  @override
  Future<SavedConnectionInfo> loadSavedConnection() async =>
      SavedConnectionInfo(
        username: savedUsername,
        hasCredentials: savedUsername != null && savedPassword != null,
      );

  @override
  Future<void> connect({
    required String username,
    required String appPassword,
    WebDavRequestCancellation? cancellation,
  }) async {
    final error = nextError;
    if (error != null) throw CloudMailException(error);
    savedUsername = username;
    savedPassword = appPassword;
  }

  @override
  Future<void> disconnect() async {
    savedUsername = null;
    savedPassword = null;
  }
}

Future<void> launch(
  WidgetTester tester,
  Size size, {
  CloudConnectionService? service,
}) async {
  final connectionService = service ?? _FakeConnectionService();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cloudConnectionServiceProvider.overrideWithValue(connectionService),
      ],
      child: const CloudMailApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Russian narrow navigation switches every destination', (
    tester,
  ) async {
    await launch(tester, const Size(390, 844));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Библиотека не подключена'), findsOneWidget);
    for (final entry in {
      'Альбомы': 'albums',
      'Исполнители': 'artists',
      'Настройки': 'settings',
      'Треки': 'tracks',
    }.entries) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(entry.key),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('page-${entry.value}')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('wide rail navigates and retains selection across resizing', (
    tester,
  ) async {
    await launch(tester, const Size(1200, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.text('Альбомы'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('page-albums')), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      AppDestination.albums.index,
    );
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('page-albums')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme selector applies dark, light and system modes', (
    tester,
  ) async {
    await launch(tester, const Size(390, 844));
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    for (final entry in {
      'Тёмная': ThemeMode.dark,
      'Светлая': ThemeMode.light,
      'Как в системе': ThemeMode.system,
    }.entries) {
      await tester.tap(find.byKey(const ValueKey('theme-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.key).last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        entry.value,
      );
      if (entry.value != ThemeMode.system) {
        final context = tester.element(
          find.byKey(const ValueKey('page-settings')),
        );
        expect(
          Theme.of(context).brightness,
          entry.value == ThemeMode.dark ? Brightness.dark : Brightness.light,
        );
      }
    }
    expect(find.textContaining('Введите логин Cloud Mail.ru'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small window and enlarged text remain scrollable', (
    tester,
  ) async {
    await launch(tester, const Size(320, 480));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('theme-selector')), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings verifies, stores, and disconnects credentials', (
    tester,
  ) async {
    final service = _FakeConnectionService();
    await launch(tester, const Size(390, 844), service: service);
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('cloud-login-field')),
      'fake@example.invalid',
    );
    await tester.enterText(
      find.byKey(const ValueKey('cloud-password-field')),
      'test-app-password',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('cloud-password-field')))
          .obscureText,
      isTrue,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('connect-button')));
    await tester.tap(find.byKey(const ValueKey('connect-button')));
    await tester.pumpAndSettle();

    expect(service.savedUsername, 'fake@example.invalid');
    expect(service.savedPassword, 'test-app-password');
    // Connecting must reveal the library rather than leave the user on
    // Settings with a seemingly empty collection.
    expect(find.byKey(const ValueKey('page-tracks')), findsOneWidget);
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('cloud-password-field')))
          .controller!
          .text,
      isEmpty,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    // Reopening Settings creates a new screen; the transient success banner
    // is replaced by the persisted credentials hint.
    expect(find.textContaining('Учётные данные сохранены'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('disconnect-button')));
    await tester.tap(find.byKey(const ValueKey('disconnect-button')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(
      find.text('Сохранённые учётные данные удалены с устройства.'),
      findsOneWidget,
    );
    expect(service.savedUsername, isNull);
    expect(service.savedPassword, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings shows safe Russian authentication errors', (
    tester,
  ) async {
    final service = _FakeConnectionService(
      nextError: CloudMailErrorCode.invalidCredentials,
    );
    await launch(tester, const Size(390, 844), service: service);
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('cloud-login-field')),
      'fake@example.invalid',
    );
    await tester.enterText(
      find.byKey(const ValueKey('cloud-password-field')),
      'fake-password',
    );
    await tester.tap(find.byKey(const ValueKey('connect-button')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Не удалось войти. Проверьте логин и пароль для внешнего приложения.',
      ),
      findsOneWidget,
    );
    expect(find.text('fake-password'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
