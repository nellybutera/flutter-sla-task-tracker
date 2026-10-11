import '../models/user.dart';
import 'password_hasher.dart';
import 'storage_service.dart';

/// A sign in or sign up problem the user can fix. [message] is shown on
/// screen as it is.
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Local accounts: no server, passwords are only ever stored hashed.
class AuthService {
  static const demoPassword = 'Demo1234';

  final StorageService _storage;

  AuthService({StorageService? storage})
    : _storage = storage ?? StorageService();

  /// Signs in and remembers the user, or throws [AuthException].
  Future<User> signIn({required String email, required String password}) async {
    await _ensureDemoAccounts();
    final user = _findByEmail(await _storage.loadUsers(), email);
    final credential = user == null
        ? null
        : (await _storage.loadCredentials())[user.id];
    // the same message for an unknown email and a wrong password, so the
    // screen doesn't reveal which emails have an account
    if (user == null ||
        credential == null ||
        !PasswordHasher.verify(password, credential)) {
      throw const AuthException('Email or password is incorrect.');
    }
    await _storage.setCurrentUser(user.id);
    return user;
  }

  /// Creates the account, joins the team and signs in.
  Future<User> signUp({
    required String name,
    required String email,
    required String role,
    required String password,
  }) async {
    await _ensureDemoAccounts();
    final users = await _storage.loadUsers();
    if (_findByEmail(users, email) != null) {
      throw const AuthException('An account with this email already exists.');
    }
    final user = User(
      id: 'u${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      role: role,
      email: _normalize(email),
    );
    await _storage.saveUser(user);
    await _storage.saveCredential(user.id, PasswordHasher.create(password));
    await _storage.setCurrentUser(user.id);
    return user;
  }

  /// Gives the sample users their demo email and password. Also covers
  /// phones that saved the sample users before accounts existed.
  Future<void> _ensureDemoAccounts() async {
    final users = await _storage.loadUsers();
    final credentials = await _storage.loadCredentials();
    for (final demo in StorageService.seedUsers) {
      final saved = _findById(users, demo.id);
      if (saved == null) continue;
      if (saved.email.isEmpty) {
        await _storage.saveUser(saved.copyWith(email: demo.email));
      }
      if (!credentials.containsKey(demo.id)) {
        await _storage.saveCredential(
          demo.id,
          PasswordHasher.create(demoPassword),
        );
      }
    }
  }

  static String _normalize(String email) => email.trim().toLowerCase();

  static User? _findByEmail(List<User> users, String email) {
    final wanted = _normalize(email);
    for (final user in users) {
      if (user.email == wanted) return user;
    }
    return null;
  }

  static User? _findById(List<User> users, String id) {
    for (final user in users) {
      if (user.id == id) return user;
    }
    return null;
  }
}
