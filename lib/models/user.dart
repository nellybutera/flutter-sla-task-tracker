class User {
  final String id;
  final String name;
  final String role;

  const User({required this.id, required this.name, this.role = 'Developer'});

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

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'role': role};

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    role: (json['role'] as String?) ?? 'Developer',
  );
}
