// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import 'package:simple_example/cubit/user_cubit.dart';

/// Role Guard
/// Checks if user has at least one of the required roles
/// Blocks navigation if requirements not met
class RoleGuard extends RouteGuard {
  const RoleGuard(this.requiredRoles);

  final List<String> requiredRoles;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    final userState = context.read<UserCubit>().state;
    final hasRole = requiredRoles.any(userState.hasRole);

    if (!hasRole) {
      // Block navigation - user will stay on current page
      resolver.block();
    } else {
      resolver.next();
    }
  }
}
