/// A password as we store it: never the password itself, only a random salt
/// and the SHA-256 hash of salt + password.
class Credential {
  final String salt;
  final String hash;

  const Credential({required this.salt, required this.hash});

  Map<String, dynamic> toJson() => {'salt': salt, 'hash': hash};

  factory Credential.fromJson(Map<String, dynamic> json) =>
      Credential(salt: json['salt'] as String, hash: json['hash'] as String);
}
