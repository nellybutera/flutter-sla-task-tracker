class User {
  final String id;
  final String name;
  final String role;
  final String email;

  const User({
    required this.id,
    required this.name,
    this.role = 'Developer',
    this.email = '',
  });

  String get initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) {
      return '?';
    }
    return words
        .take(2)
        .map((word) => String.fromCharCode(word.runes.first).toUpperCase())
        .join();
  }

  User copyWith({String? name, String? role, String? email}) {
    return User(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'email': email,
  };

  // email is optional so users saved before accounts existed still load
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    role: (json['role'] as String?) ?? 'Developer',
    email: (json['email'] as String?) ?? '',
  );
}
