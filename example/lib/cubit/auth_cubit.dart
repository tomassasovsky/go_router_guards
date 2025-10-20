// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:bloc/bloc.dart';

/// Authentication state
class AuthState {
  const AuthState({required this.isAuthenticated});

  final bool isAuthenticated;
}

/// Authentication Cubit
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState(isAuthenticated: false));

  void login() => emit(const AuthState(isAuthenticated: true));
  void logout() => emit(const AuthState(isAuthenticated: false));
  void toggleAuth() => emit(AuthState(isAuthenticated: !state.isAuthenticated));
}
