/// Simple app state management using ChangeNotifier.
///
/// Tracks the active user role (citizen/admin) and the admin's signed-in
/// session. The admin session is persisted with `shared_preferences` so an
/// admin stays signed in across app launches until they explicitly log out.
///
/// Only a flag and the username are ever written to disk — the password is
/// never stored, and every sign-in is validated by the backend.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { citizen, admin }

class AppState extends ChangeNotifier {
  static const _adminSessionKey = 'nyayaai.admin_authenticated';
  static const _adminUsernameKey = 'nyayaai.admin_username';

  UserRole _role = UserRole.citizen;
  bool _isAdminAuthenticated = false;
  String? _adminUsername;

  UserRole get role => _role;
  bool get isAdmin => _role == UserRole.admin;
  bool get isCitizen => _role == UserRole.citizen;

  /// Whether an admin has signed in successfully. The admin area is gated on
  /// this, not on [isAdmin] — a role alone must never unlock the dashboard.
  bool get isAdminAuthenticated => _isAdminAuthenticated;

  /// Username of the signed-in admin, for display in the dashboard.
  String? get adminUsername => _adminUsername;

  void setRole(UserRole role) {
    _role = role;
    notifyListeners();
  }

  void switchToCitizen() => setRole(UserRole.citizen);

  /// Sets the role to admin **without** authenticating.
  ///
  /// This does NOT unlock the admin dashboard — `AdminGuard` gates on
  /// [isAdminAuthenticated], which only [loginAsAdmin] can set. Use
  /// [loginAsAdmin] to sign an admin in.
  void switchToAdmin() => setRole(UserRole.admin);

  /// Loads any previously saved admin session from disk.
  ///
  /// Called once during startup, before the first frame, so a returning admin
  /// never sees the login screen flash before the dashboard appears.
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAdminAuthenticated = prefs.getBool(_adminSessionKey) ?? false;
      _adminUsername = prefs.getString(_adminUsernameKey);
      if (_isAdminAuthenticated) _role = UserRole.admin;
    } catch (_) {
      // Storage unavailable — start as a signed-out citizen.
      _isAdminAuthenticated = false;
      _adminUsername = null;
      _role = UserRole.citizen;
    }
    notifyListeners();
  }

  /// Records a successful admin sign-in and persists it.
  ///
  /// Call this only after the backend has approved the credentials.
  Future<void> loginAsAdmin(String username) async {
    _isAdminAuthenticated = true;
    _adminUsername = username;
    _role = UserRole.admin;
    notifyListeners(); // Unlock the UI immediately; persist in the background.

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_adminSessionKey, true);
      await prefs.setString(_adminUsernameKey, username);
    } catch (_) {
      // Persistence failed; the session is still valid for this run.
    }
  }

  /// Ends the admin session, clearing it from memory and from disk.
  Future<void> logout() async {
    _isAdminAuthenticated = false;
    _adminUsername = null;
    _role = UserRole.citizen;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_adminSessionKey);
      await prefs.remove(_adminUsernameKey);
    } catch (_) {
      // Nothing recoverable to do — memory state is already cleared.
    }
  }
}
