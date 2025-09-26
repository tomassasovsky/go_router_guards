// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

import 'screens.dart';

part 'router.g.dart';

// Configure global fallback for blocked navigation
void _configureGlobalFallback() {
  RouteGuardConfig.instance.fallbackPath = UnauthorizedRoute().location;
}

class AuthenticationGuard extends GoRouterGuard {
  const AuthenticationGuard();

  @override
  FutureOr<void> onGoRouterNavigation(
    GoRouterNavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final isAuthenticated = context.read<AuthCubit>().state.isAuthenticated;

    if (!isAuthenticated) {
      resolver.redirect(LoginRoute().location);
    } else {
      resolver.next();
    }
  }
}

// Role-based guard with simple blocking that defaults to root
class RoleGuard extends GoRouterGuard {
  const RoleGuard(this.requiredRoles);

  final List<String> requiredRoles;

  @override
  FutureOr<void> onGoRouterNavigation(
    GoRouterNavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final userRoles = context.read<UserCubit>().state.roles;

    final hasRequiredRole = requiredRoles.any(userRoles.contains);
    if (!hasRequiredRole) {
      // Block using global fallback
      resolver.block();
    } else {
      resolver.next();
    }
  }
}

@TypedGoRoute<HomeRoute>(
  path: '/',
  routes: [
    TypedGoRoute<ProtectedRoute>(path: '/protected'),
    TypedGoRoute<LoginRoute>(path: '/login'),
    TypedGoRoute<AdminRoute>(path: '/admin'),
    TypedGoRoute<UnauthorizedRoute>(path: '/unauthorized'),
  ],
)
class HomeRoute extends GoRouteData with _$HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const HomeScreen();
  }
}

class ProtectedRoute extends GoRouteData with _$ProtectedRoute, GuardedRoute {
  const ProtectedRoute();

  @override
  RouteGuard<Object, Object> get guards => Guards.all([
    AuthenticationGuard(),
    RoleGuard(['admin']),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ProtectedScreen();
  }
}

/// Example of using UnguardedRoute to opt-out of router-level guards
/// This route will bypass any router-level guards applied to the router
class LoginRoute extends GoRouteData with _$LoginRoute, UnguardedRoute {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LoginScreen();
  }
}

class AdminRoute extends GoRouteData with _$AdminRoute, GuardedRoute {
  const AdminRoute();

  @override
  RouteGuard<Object, Object> get guards => Guards.all([
    AuthenticationGuard(),
    RoleGuard(['admin']),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AdminScreen();
  }
}

class UnauthorizedRoute extends GoRouteData with _$UnauthorizedRoute {
  const UnauthorizedRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const UnauthorizedScreen();
  }
}

/// Router that excludes authentication from public and auth routes.
final router = (() {
  // Configure global fallback before creating router
  _configureGlobalFallback();

  return GoRouter(
    routes: $appRoutes,
    redirect: RouteGuardUtils.createGuardRedirect(
      ConditionalGuard(
        guard: AuthenticationGuard(),
        excludedPaths: ['/login', '/unauthorized'],
      ),
    ),
  );
})();
