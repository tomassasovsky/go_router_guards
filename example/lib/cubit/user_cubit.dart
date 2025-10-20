// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:bloc/bloc.dart';

/// User state with roles and permissions
class UserState {
  const UserState({
    required this.roles,
    required this.permissions,
  });

  final Set<String> roles;
  final Set<String> permissions;

  bool hasRole(String role) => roles.contains(role);
  bool hasPermission(String permission) => permissions.contains(permission);
}

/// User Cubit
class UserCubit extends Cubit<UserState> {
  UserCubit() : super(const UserState(roles: {'user'}, permissions: {}));

  void toggleRole(String role) {
    final newRoles = Set<String>.from(state.roles);
    if (newRoles.contains(role)) {
      newRoles.remove(role);
    } else {
      newRoles.add(role);
    }
    emit(UserState(roles: newRoles, permissions: state.permissions));
  }

  void togglePermission(String permission) {
    final newPermissions = Set<String>.from(state.permissions);
    if (newPermissions.contains(permission)) {
      newPermissions.remove(permission);
    } else {
      newPermissions.add(permission);
    }
    emit(UserState(roles: state.roles, permissions: newPermissions));
  }
}
