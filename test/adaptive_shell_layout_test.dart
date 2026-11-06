import 'package:cloudmail_player/app/shell.dart';
import 'package:cloudmail_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 393.0, 600.0, 719.0, 1024.0]) {
    testWidgets('adaptive navigation at ${width.toInt()} dp', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AppShell(),
          ),
        ),
      );
      await tester.pump();
      if (width >= 720) {
        expect(find.byKey(const ValueKey('navigation-rail')), findsOneWidget);
        expect(find.byKey(const ValueKey('navigation-bar')), findsNothing);
      } else {
        expect(find.byKey(const ValueKey('navigation-rail')), findsNothing);
        expect(find.byKey(const ValueKey('navigation-bar')), findsOneWidget);
        expect(find.byType(NavigationDestination), findsNWidgets(4));
      }
      expect(tester.takeException(), isNull);
    });
  }
}
