import 'dart:async';

import 'package:cloudmail_player/cloud/cloud_connection_service.dart';
import 'package:cloudmail_player/data/library/cloud_music_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _DelayedVault implements CloudCredentialVault {
  final Completer<String?> firstRead = Completer<String?>();
  bool first = true;

  @override
  Future<String?> read(String key) {
    if (first) {
      first = false;
      return firstRead.future;
    }
    return Future<String?>.value('fake-app-password');
  }

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}
}

void main() {
  test(
    'closed service rejects credentials returned by an in-flight vault read',
    () async {
      final vault = _DelayedVault();
      final service = CloudMusicService(vault: vault);
      final pending = service.readCachedCatalog();
      service.close();
      vault.firstRead.complete('fake@example.invalid');

      await expectLater(pending, throwsStateError);
    },
  );
}
