import 'package:cloudmail_player/cloud/cloud_connection_service.dart';
import 'package:cloudmail_player/cloud/cloud_mail_webdav.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryVault implements CloudCredentialVault {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

class _FakeVerifier implements CloudConnectionVerifier {
  CloudCredentials? lastCredentials;
  CloudMailErrorCode? nextError;

  @override
  Future<void> verifyConnection(
    CloudCredentials credentials, {
    WebDavRequestCancellation? cancellation,
  }) async {
    final error = nextError;
    if (error != null) throw CloudMailException(error);
    lastCredentials = credentials;
  }
}

void main() {
  test('credentials are stored only after a successful verification', () async {
    final vault = _MemoryVault();
    final verifier = _FakeVerifier();
    final service = SecureCloudConnectionService(
      vault: vault,
      verifier: verifier,
    );

    await service.connect(
      username: ' fake@example.invalid ',
      appPassword: 'fake-app-password',
    );

    expect(verifier.lastCredentials?.username, 'fake@example.invalid');
    expect(verifier.lastCredentials?.appPassword, 'fake-app-password');
    final saved = await service.loadSavedConnection();
    expect(saved.username, 'fake@example.invalid');
    expect(saved.hasCredentials, isTrue);
  });

  test(
    'failed verification never writes credentials to secure storage',
    () async {
      final vault = _MemoryVault();
      final verifier = _FakeVerifier()
        ..nextError = CloudMailErrorCode.invalidCredentials;
      final service = SecureCloudConnectionService(
        vault: vault,
        verifier: verifier,
      );

      await expectLater(
        service.connect(
          username: 'fake@example.invalid',
          appPassword: 'fake-password',
        ),
        throwsA(
          isA<CloudMailException>().having(
            (error) => error.code,
            'code',
            CloudMailErrorCode.invalidCredentials,
          ),
        ),
      );
      expect(vault.values, isEmpty);
    },
  );

  test(
    'saved app password can be reused without putting it back in the UI',
    () async {
      final vault = _MemoryVault();
      final verifier = _FakeVerifier();
      final service = SecureCloudConnectionService(
        vault: vault,
        verifier: verifier,
      );
      await service.connect(
        username: 'fake@example.invalid',
        appPassword: 'fake-app-password',
      );

      await service.connect(username: 'fake@example.invalid', appPassword: '');

      expect(verifier.lastCredentials?.appPassword, 'fake-app-password');
    },
  );

  test('disconnect deletes saved credentials', () async {
    final vault = _MemoryVault();
    final service = SecureCloudConnectionService(
      vault: vault,
      verifier: _FakeVerifier(),
    );
    await service.connect(
      username: 'fake@example.invalid',
      appPassword: 'fake-app-password',
    );

    await service.disconnect();

    final saved = await service.loadSavedConnection();
    expect(saved.username, isNull);
    expect(saved.hasCredentials, isFalse);
  });
}
