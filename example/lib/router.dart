import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

import 'screens.dart';

part 'router.g.dart';

// Simple authentication guard
class AuthenticationGuard extends RouteGuard {
  const AuthenticationGuard();

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
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

// Role-based guard
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
      resolver.redirect(UnauthorizedRoute().location);
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
  RouteGuard get guards => Guards.all([
    AuthenticationGuard(),
    RoleGuard(['admin']),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ProtectedScreen();
  }
}

/// Example of using UnguardedRoute to opt-out of global guards
/// This route will bypass any global guards applied to the router
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
  RouteGuard get guards => Guards.all([
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
