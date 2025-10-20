// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import 'package:simple_example/cubit/user_cubit.dart';

/// Permission Guard
/// Checks if user has specific permission
class PermissionGuard extends RouteGuard {
  const PermissionGuard(this.requiredPermission);

  final String requiredPermission;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    final userState = context.read<UserCubit>().state;

    if (!userState.hasPermission(requiredPermission)) {
      resolver.block();
    } else {
      resolver.next();
    }
  }
}
