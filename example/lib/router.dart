import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

import 'screens.dart';

part 'router.g.dart';

@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData with _$HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const HomeScreen();
  }
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with _$LoginRoute {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LoginScreen();
  }
}

@TypedGoRoute<ProtectedRoute>(path: '/protected')
class ProtectedRoute extends GoRouteData with _$ProtectedRoute, GuardedRoute {
  const ProtectedRoute();

  @override
  GuardExpression get guards => Guards.guard(AuthenticationGuard());

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ProtectedScreen();
  }
}

@TypedGoRoute<AdminRoute>(path: '/admin')
class AdminRoute extends GoRouteData with _$AdminRoute, GuardedRoute {
  const AdminRoute();

  @override
  GuardExpression get guards => Guards.all([
    Guards.guard(AuthenticationGuard()),
    Guards.guard(RoleBasedGuard(['admin'])),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AdminScreen();
  }
}

@TypedGoRoute<UnauthorizedRoute>(path: '/unauthorized')
class UnauthorizedRoute extends GoRouteData with _$UnauthorizedRoute {
  const UnauthorizedRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const UnauthorizedScreen();
  }
}

// Example guards
class AuthenticationGuard implements RouteGuard {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
    final authState = context.read<AuthCubit>().state;
    if (!authState.isAuthenticated) {
      return LoginRoute().location;
    }
    return null;
  }
}

class RoleBasedGuard implements RouteGuard {
  final List<String> requiredRoles;

  RoleBasedGuard(this.requiredRoles);

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
    final userState = context.read<UserCubit>().state;
    if (!requiredRoles.any((role) => userState.roles.contains(role))) {
      return UnauthorizedRoute().location;
    }
    return null;
  }
}

final router = GoRouter(routes: $appRoutes);
