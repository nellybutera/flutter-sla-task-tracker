class User {
  final String id;
  final String name;
  final String role;

  const User({required this.id, required this.name, this.role = 'Developer'});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'role': role};

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        role: (json['role'] as String?) ?? 'Developer',
      );
}
