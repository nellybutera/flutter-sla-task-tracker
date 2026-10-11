import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/credential.dart';

class PasswordHasher {
  static const _saltBytes = 16;

  /// A new random salt for each password, so two people with the same
  /// password still get different hashes.
  static Credential create(String password, {Random? random}) {
    final generator = random ?? Random.secure();
    final bytes = List<int>.generate(_saltBytes, (_) => generator.nextInt(256));
    final salt = base64Url.encode(bytes);
    return Credential(salt: salt, hash: _hash(salt, password));
  }

  static bool verify(String password, Credential credential) =>
      _hash(credential.salt, password) == credential.hash;

  static String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
}
