import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository authRepository;

  bool isLoading = false;
  String? error;

  User? get user => authRepository.currentUser;
  bool get isLoggedIn => authRepository.currentUser != null;

  AuthProvider(this.authRepository);

  Future<void> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await authRepository.login(email, password);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await authRepository.register(email, password);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future <void> logout() async {
    isLoading = true;
    notifyListeners();
    try {
      await authRepository.logout();
      error = null;
      notifyListeners();
    } catch (e) {
      error = "Logout failed: $e";
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    error = null;
    isLoading = false;
    notifyListeners();
  }
}