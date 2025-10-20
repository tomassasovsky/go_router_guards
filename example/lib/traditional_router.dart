// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import 'package:go_router_guards_example/screens.dart';

class RoleGuard extends RouteGuard {
  const RoleGuard(this.requiredRoles);

  final List<String> requiredRoles;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final userRoles = context.read<UserCubit>().state.roles;
    final hasRequiredRole = requiredRoles.any(userRoles.contains);

    if (!hasRequiredRole) {
      resolver.block();
    } else {
      resolver.next();
    }
  }
}

/// Simple authentication guard that redirects to login if not authenticated
class AuthenticationGuard extends RouteGuard {
  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final isAuthenticated = context.read<AuthCubit>().state.isAuthenticated;

    if (!isAuthenticated) {
      resolver.redirect('/login');
    } else {
      resolver.next();
    }
  }
}

final traditionalRouter = GoRouter(
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'protected',
          builder: (context, state) => const ProtectedScreen(),
        ),
        GoRoute(
          path: 'admin',
          builder: (context, state) => const AdminScreen(),
        ),
      ],
    ),
  ],
  // Apply authentication globally, but exclude auth-related routes
  redirect: guardAll([
    ConditionalGuard(
      guard: AuthenticationGuard(),
      excludedPaths: ['/login', '/'],
    ),
    ConditionalGuard(
      guard: RoleGuard(['admin']),
      includedPatterns: [RegExp(r'^/admin.*')],
    ),
  ]).toRedirect(),
);
