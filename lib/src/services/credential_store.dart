import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models.dart';

class CredentialStore {
  CredentialStore() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> savePassword(String ref, String password) async {
    await _storage.write(key: '$ref.password', value: password);
    await _storage.delete(key: '$ref.privateKey');
    await _storage.delete(key: '$ref.passphrase');
  }

  Future<void> savePrivateKey(
    String ref,
    String privateKey,
    String passphrase,
  ) async {
    await _storage.write(key: '$ref.privateKey', value: privateKey);
    await _storage.write(key: '$ref.passphrase', value: passphrase);
    await _storage.delete(key: '$ref.password');
  }

  Future<HostCredential> read(String ref) async {
    return HostCredential(
      password: await _storage.read(key: '$ref.password'),
      privateKey: await _storage.read(key: '$ref.privateKey'),
      passphrase: await _storage.read(key: '$ref.passphrase'),
    );
  }

  Future<void> delete(String ref) async {
    await _storage.delete(key: '$ref.password');
    await _storage.delete(key: '$ref.privateKey');
    await _storage.delete(key: '$ref.passphrase');
  }
}
