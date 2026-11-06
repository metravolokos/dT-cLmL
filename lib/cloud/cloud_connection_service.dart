import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'cloud_mail_webdav.dart';

class SavedConnectionInfo {
  const SavedConnectionInfo({this.username, required this.hasCredentials});

  final String? username;
  final bool hasCredentials;
}

abstract interface class CloudCredentialVault {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureCredentialVault implements CloudCredentialVault {
  FlutterSecureCredentialVault({FlutterSecureStorage? storage})
    : _storage = storage ?? FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

abstract interface class CloudConnectionService {
  Future<SavedConnectionInfo> loadSavedConnection();

  Future<void> connect({
    required String username,
    required String appPassword,
    WebDavRequestCancellation? cancellation,
  });

  Future<void> disconnect();
}

class SecureCloudConnectionService implements CloudConnectionService {
  SecureCloudConnectionService({
    required CloudCredentialVault vault,
    required CloudConnectionVerifier verifier,
  }) : _vault = vault,
       _verifier = verifier;

  static const String _usernameKey = 'cloud_mail_username';
  static const String _passwordKey = 'cloud_mail_app_password';

  final CloudCredentialVault _vault;
  final CloudConnectionVerifier _verifier;

  @override
  Future<SavedConnectionInfo> loadSavedConnection() async {
    try {
      final username = await _vault.read(_usernameKey);
      final password = await _vault.read(_passwordKey);
      return SavedConnectionInfo(
        username: username,
        hasCredentials:
            username != null && username.isNotEmpty && password != null,
      );
    } catch (_) {
      throw const CloudMailException(
        CloudMailErrorCode.secureStorageUnavailable,
      );
    }
  }

  @override
  Future<void> connect({
    required String username,
    required String appPassword,
    WebDavRequestCancellation? cancellation,
  }) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) {
      throw const CloudMailException(CloudMailErrorCode.credentialsRequired);
    }

    var password = appPassword;
    if (password.isEmpty) {
      try {
        final savedUsername = await _vault.read(_usernameKey);
        final savedPassword = await _vault.read(_passwordKey);
        if (savedUsername == normalizedUsername && savedPassword != null) {
          password = savedPassword;
        }
      } catch (_) {
        throw const CloudMailException(
          CloudMailErrorCode.secureStorageUnavailable,
        );
      }
    }
    if (password.isEmpty) {
      throw const CloudMailException(CloudMailErrorCode.credentialsRequired);
    }

    final credentials = CloudCredentials(
      username: normalizedUsername,
      appPassword: password,
    );
    await _verifier.verifyConnection(credentials, cancellation: cancellation);
    try {
      await _vault.write(_usernameKey, normalizedUsername);
      await _vault.write(_passwordKey, password);
    } catch (_) {
      try {
        await Future.wait([
          _vault.delete(_usernameKey),
          _vault.delete(_passwordKey),
        ]);
      } catch (_) {
        // Preserve only the safe storage error below; never expose a plugin error.
      }
      throw const CloudMailException(
        CloudMailErrorCode.secureStorageUnavailable,
      );
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await Future.wait([
        _vault.delete(_usernameKey),
        _vault.delete(_passwordKey),
      ]);
    } catch (_) {
      throw const CloudMailException(
        CloudMailErrorCode.secureStorageUnavailable,
      );
    }
  }
}

final cloudConnectionServiceProvider = Provider<CloudConnectionService>((ref) {
  final client = CloudMailWebDavClient();
  ref.onDispose(client.close);
  return SecureCloudConnectionService(
    vault: FlutterSecureCredentialVault(),
    verifier: client,
  );
});
