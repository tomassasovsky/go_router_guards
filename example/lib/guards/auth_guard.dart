// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import 'package:simple_example/app_router.dart';
import 'package:simple_example/cubit/auth_cubit.dart';

/// Authentication Guard
/// Redirects to /login if user is not authenticated
class AuthGuard extends RouteGuard {
  const AuthGuard();

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    final isAuthenticated = context.read<AuthCubit>().state.isAuthenticated;

    if (!isAuthenticated) {
      resolver.redirect(const LoginRoute().location);
    } else {
      resolver.next();
    }
  }
}

/// Async Guard Example
/// Simulates checking authentication with a server
/// Demonstrates async guard operations
class AsyncAuthGuard extends RouteGuard {
  const AsyncAuthGuard();

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    // Get auth state before async operation
    final isAuthenticated = context.read<AuthCubit>().state.isAuthenticated;

    // Simulate async operation (e.g., checking token with server)
    await Future.delayed(const Duration(milliseconds: 100));

    if (!isAuthenticated) {
      resolver.redirect(const LoginRoute().location);
    } else {
      resolver.next();
    }
  }
}
