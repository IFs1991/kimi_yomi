import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  final FlutterSecureStorage _storage;
  User? _currentUser;
  bool _isLoading = false;

  AuthProvider({
    ApiService? apiService,
    FlutterSecureStorage? storage,
  })  : _apiService = apiService ?? ApiService(),
        _storage = storage ?? const FlutterSecureStorage();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _apiService.login(email, password);
      _currentUser = user;
      await _storage.write(key: 'userId', value: user.id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _apiService.register(email, password);
      _currentUser = user;
      await _storage.write(key: 'userId', value: user.id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _storage.delete(key: 'userId');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await _storage.read(key: 'userId');
      if (userId != null) {
        _currentUser = await _apiService.getUserProfile(userId);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.updateUserProfile(_currentUser!.id, data);
      _currentUser = await _apiService.getUserProfile(_currentUser!.id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}