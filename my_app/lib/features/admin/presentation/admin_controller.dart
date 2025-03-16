import 'package:flutter/foundation.dart';

import '../data/admin_repository.dart';
import '../domain/admin_models.dart';

enum AdminLoadState { idle, loading, success, forbidden, unauthorized, error }

class AdminController extends ChangeNotifier {
  final AdminRepository _repository;

  AdminController({AdminRepository? repository})
      : _repository = repository ?? AdminRepository();

  AdminLoadState state = AdminLoadState.idle;
  String? error;
  UserAccount? me;
  AdminSummary? adminSummary;
  SuperAdminSummary? superAdminSummary;
  List<UserAccount> users = const [];
  bool roleUpdateInProgress = false;

  Future<void> loadAdminDashboard() async {
    state = AdminLoadState.loading;
    error = null;
    notifyListeners();

    try {
      me = await _repository.fetchMe();
      adminSummary = await _repository.fetchAdminSummary();
      users = await _repository.fetchUsers();
      state = AdminLoadState.success;
    } on AdminUnauthorizedException {
      state = AdminLoadState.unauthorized;
    } on AdminForbiddenException {
      state = AdminLoadState.forbidden;
    } catch (e) {
      state = AdminLoadState.error;
      error = 'Failed to load admin dashboard: $e';
    }

    notifyListeners();
  }

  Future<void> loadSuperAdminDashboard() async {
    state = AdminLoadState.loading;
    error = null;
    notifyListeners();

    try {
      me = await _repository.fetchMe();
      superAdminSummary = await _repository.fetchSuperAdminSummary();
      users = await _repository.fetchUsers();
      state = AdminLoadState.success;
    } on AdminUnauthorizedException {
      state = AdminLoadState.unauthorized;
    } on AdminForbiddenException {
      state = AdminLoadState.forbidden;
    } catch (e) {
      state = AdminLoadState.error;
      error = 'Failed to load superadmin dashboard: $e';
    }

    notifyListeners();
  }

  Future<void> changeRole({required int userId, required String role}) async {
    roleUpdateInProgress = true;
    error = null;
    notifyListeners();

    try {
      await _repository.updateUserRole(userId: userId, role: role);
      users = users
          .map((u) => u.id == userId
              ? UserAccount(
                  id: u.id,
                  email: u.email,
                  role: role,
                  createdAt: u.createdAt,
                )
              : u)
          .toList();
    } catch (e) {
      error = 'Failed to update role: $e';
    } finally {
      roleUpdateInProgress = false;
      notifyListeners();
    }
  }
}
