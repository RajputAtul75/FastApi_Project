/// Simple app state management using ChangeNotifier.
/// Manages user role (citizen/admin) with no real auth.
library;

import 'package:flutter/material.dart';

enum UserRole { citizen, admin }

class AppState extends ChangeNotifier {
  UserRole _role = UserRole.citizen;

  UserRole get role => _role;
  bool get isAdmin => _role == UserRole.admin;
  bool get isCitizen => _role == UserRole.citizen;

  void setRole(UserRole role) {
    _role = role;
    notifyListeners();
  }

  void switchToCitizen() => setRole(UserRole.citizen);
  void switchToAdmin() => setRole(UserRole.admin);
}
