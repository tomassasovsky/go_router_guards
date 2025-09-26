---
title: Role-Based Access Control
description: Implement comprehensive role-based access control with Go Router Guards
---

This example demonstrates a complete role-based access control (RBAC) system using hierarchical roles, permissions, and dynamic access control.

## Role System Design

```dart
// lib/models/role.dart
enum UserRole {
  guest,
  user,
  moderator,
  admin,
  superAdmin;

  // Role hierarchy - higher values have more permissions
  int get level {
    switch (this) {
      case guest: return 0;
      case user: return 1;
      case moderator: return 2;
      case admin: return 3;
      case superAdmin: return 4;
    }
  }

  bool hasPermissionLevel(UserRole requiredRole) {
    return level >= requiredRole.level;
  }

  List<String> get permissions {
    switch (this) {
      case guest:
        return ['read_public'];
      case user:
        return ['read_public', 'read_user', 'write_user'];
      case moderator:
        return [
          'read_public', 'read_user', 'write_user',
          'moderate_content', 'manage_users'
        ];
      case admin:
        return [
          'read_public', 'read_user', 'write_user',
          'moderate_content', 'manage_users',
          'admin_panel', 'system_config'
        ];
      case superAdmin:
        return ['*']; // All permissions
    }
  }
}
```

## Permission System

```dart
// lib/models/permission.dart
class Permission {
  final String name;
  final String description;
  final PermissionCategory category;

  const Permission({
    required this.name,
    required this.description,
    required this.category,
  });
}

enum PermissionCategory {
  content,
  user,
  system,
  financial,
}

class AppPermissions {
  // Content permissions
  static const readContent = Permission(
    name: 'read_content',
    description: 'View content',
    category: PermissionCategory.content,
  );
  
  static const writeContent = Permission(
    name: 'write_content',
    description: 'Create and edit content',
    category: PermissionCategory.content,
  );
  
  static const moderateContent = Permission(
    name: 'moderate_content',
    description: 'Moderate user-generated content',
    category: PermissionCategory.content,
  );

  // User permissions
  static const manageUsers = Permission(
    name: 'manage_users',
    description: 'Manage user accounts',
    category: PermissionCategory.user,
  );
  
  static const viewUserProfiles = Permission(
    name: 'view_user_profiles',
    description: 'View other user profiles',
    category: PermissionCategory.user,
  );

  // System permissions
  static const systemConfig = Permission(
    name: 'system_config',
    description: 'Configure system settings',
    category: PermissionCategory.system,
  );
  
  static const viewLogs = Permission(
    name: 'view_logs',
    description: 'View system logs',
    category: PermissionCategory.system,
  );

  // Financial permissions
  static const viewFinancials = Permission(
    name: 'view_financials',
    description: 'View financial reports',
    category: PermissionCategory.financial,
  );
  
  static const managePayments = Permission(
    name: 'manage_payments',
    description: 'Manage payment systems',
    category: PermissionCategory.financial,
  );

  static const List<Permission> all = [
    readContent, writeContent, moderateContent,
    manageUsers, viewUserProfiles,
    systemConfig, viewLogs,
    viewFinancials, managePayments,
  ];
}
```

## Role Guards

```dart
// lib/guards/role_guards.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_guards/go_router_guards.dart';

// Basic role guard
class RoleGuard extends GoRouterGuard {
  const RoleGuard(this.requiredRoles);
  
  final List<UserRole> requiredRoles;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = context.read<UserCubit>().state.user;
    
    if (user == null) {
      resolver.redirect('/login');
      return;
    }
    
    final hasRequiredRole = requiredRoles.any(
      (role) => user.role.hasPermissionLevel(role),
    );
    
    if (hasRequiredRole) {
      resolver.next();
    } else {
      resolver.redirect('/unauthorized?required=${requiredRoles.first.name}');
    }
  }
}

// Permission-based guard
class PermissionGuard extends GoRouterGuard {
  const PermissionGuard(this.requiredPermissions);
  
  final List<String> requiredPermissions;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = context.read<UserCubit>().state.user;
    
    if (user == null) {
      resolver.redirect('/login');
      return;
    }
    
    final userPermissions = user.role.permissions;
    
    // Super admin has all permissions
    if (userPermissions.contains('*')) {
      resolver.next();
      return;
    }
    
    // Check if user has all required permissions
    final hasAllPermissions = requiredPermissions.every(
      userPermissions.contains,
    );
    
    if (hasAllPermissions) {
      resolver.next();
    } else {
      final missingPermissions = requiredPermissions
          .where((p) => !userPermissions.contains(p))
          .toList();
      
      resolver.redirect(
        '/unauthorized?missing=${missingPermissions.join(',')}',
      );
    }
  }
}

// Hierarchical role guard (minimum role level)
class MinimumRoleGuard extends GoRouterGuard {
  const MinimumRoleGuard(this.minimumRole);
  
  final UserRole minimumRole;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = context.read<UserCubit>().state.user;
    
    if (user == null) {
      resolver.redirect('/login');
      return;
    }
    
    if (user.role.hasPermissionLevel(minimumRole)) {
      resolver.next();
    } else {
      resolver.redirect('/unauthorized?required=${minimumRole.name}');
    }
  }
}

// Dynamic permission guard (checks permissions from external source)
class DynamicPermissionGuard extends GoRouterGuard {
  const DynamicPermissionGuard({
    required this.resource,
    required this.action,
  });
  
  final String resource;
  final String action;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = context.read<UserCubit>().state.user;
    
    if (user == null) {
      resolver.redirect('/login');
      return;
    }
    
    // Check dynamic permissions from API or database
    final hasPermission = await permissionService.hasPermission(
      userId: user.id,
      resource: resource,
      action: action,
      context: _buildPermissionContext(state),
    );
    
    if (hasPermission) {
      resolver.next();
    } else {
      resolver.redirect('/unauthorized?resource=$resource&action=$action');
    }
  }

  Map<String, dynamic> _buildPermissionContext(GoRouterState state) {
    return {
      'path': state.uri.path,
      'parameters': state.pathParameters,
      'query': state.uri.queryParameters,
    };
  }
}
```

## Route Definitions with RBAC

```dart
// lib/routes/rbac_routes.dart
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

// Public routes (no protection)
@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const HomeScreen();
  }
}

// User dashboard (authenticated users)
@TypedGoRoute<DashboardRoute>(path: '/dashboard')
class DashboardRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    MinimumRoleGuard(UserRole.user),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const DashboardScreen();
  }
}

// Content management (moderators and above)
@TypedGoRoute<ContentManagementRoute>(path: '/content')
class ContentManagementRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    PermissionGuard(['moderate_content', 'write_content']),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ContentManagementScreen();
  }
}

// User management (admins only)
@TypedGoRoute<UserManagementRoute>(path: '/users')
class UserManagementRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    RoleGuard([UserRole.admin, UserRole.superAdmin]),
    PermissionGuard(['manage_users']),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const UserManagementScreen();
  }
}

// System configuration (super admin only)
@TypedGoRoute<SystemConfigRoute>(path: '/system')
class SystemConfigRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    RoleGuard([UserRole.superAdmin]),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SystemConfigScreen();
  }
}

// Dynamic resource access
@TypedGoRoute<DocumentRoute>(path: '/document/:id')
class DocumentRoute extends GoRouteData with GuardedRoute {
  const DocumentRoute({required this.id});
  
  final String id;

  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    DynamicPermissionGuard(resource: 'document', action: 'read'),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return DocumentScreen(documentId: id);
  }
}

// Multi-level admin section
@TypedShellRoute<AdminShellRoute>(
  routes: [
    TypedGoRoute<AdminDashboardRoute>(path: '/dashboard'),
    TypedGoRoute<AdminUsersRoute>(path: '/users'),
    TypedGoRoute<AdminSettingsRoute>(path: '/settings'),
    TypedGoRoute<AdminLogsRoute>(path: '/logs'),
  ],
)
class AdminShellRoute extends ShellRouteData with GuardedShellRoute {
  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    MinimumRoleGuard(UserRole.admin),
  ]);

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget child) {
    return AdminLayout(child: child);
  }
}

// Admin dashboard (base admin access)
class AdminDashboardRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AdminDashboardScreen();
  }
}

// Admin user management (admin + user management permission)
class AdminUsersRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => PermissionGuard(['manage_users']);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AdminUsersScreen();
  }
}

// System settings (super admin only)
class AdminSettingsRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => RoleGuard([UserRole.superAdmin]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AdminSettingsScreen();
  }
}

// System logs (admin with log viewing permission)
class AdminLogsRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => PermissionGuard(['view_logs']);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AdminLogsScreen();
  }
}
```

## User Model with RBAC

```dart
// lib/models/user.dart
class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final List<String> additionalPermissions;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.additionalPermissions = const [],
    required this.createdAt,
    this.lastActiveAt,
  });

  // Get all effective permissions
  List<String> get effectivePermissions {
    final rolePermissions = role.permissions;
    if (rolePermissions.contains('*')) {
      return ['*']; // Super admin has all permissions
    }
    
    return [...rolePermissions, ...additionalPermissions];
  }

  // Check if user has specific permission
  bool hasPermission(String permission) {
    final permissions = effectivePermissions;
    return permissions.contains('*') || permissions.contains(permission);
  }

  // Check if user has any of the given permissions
  bool hasAnyPermission(List<String> permissions) {
    return permissions.any(hasPermission);
  }

  // Check if user has all of the given permissions
  bool hasAllPermissions(List<String> permissions) {
    return permissions.every(hasPermission);
  }

  // Check if user can perform action on resource
  bool canPerform(String action, String resource) {
    final permission = '${action}_$resource';
    return hasPermission(permission);
  }
}
```

## Permission Service

```dart
// lib/services/permission_service.dart
class PermissionService {
  final ApiClient _apiClient;
  final Map<String, bool> _permissionCache = {};
  
  PermissionService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<bool> hasPermission({
    required String userId,
    required String resource,
    required String action,
    Map<String, dynamic>? context,
  }) async {
    final cacheKey = '$userId:$resource:$action';
    
    // Check cache first
    if (_permissionCache.containsKey(cacheKey)) {
      return _permissionCache[cacheKey]!;
    }

    try {
      final result = await _apiClient.checkPermission(
        userId: userId,
        resource: resource,
        action: action,
        context: context,
      );
      
      // Cache the result
      _permissionCache[cacheKey] = result.hasPermission;
      
      return result.hasPermission;
    } catch (error) {
      // Fail securely - deny permission on error
      logger.error('Permission check failed: $error');
      return false;
    }
  }

  void clearCache() {
    _permissionCache.clear();
  }

  void clearUserCache(String userId) {
    _permissionCache.removeWhere((key, _) => key.startsWith('$userId:'));
  }
}
```

## Advanced RBAC Patterns

### Context-Aware Permissions

```dart
class ContextAwarePermissionGuard extends GoRouterGuard {
  const ContextAwarePermissionGuard({
    required this.permission,
    this.contextBuilder,
  });
  
  final String permission;
  final Map<String, dynamic> Function(GoRouterState)? contextBuilder;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = context.read<UserCubit>().state.user;
    
    if (user == null) {
      resolver.redirect('/login');
      return;
    }

    final permissionContext = contextBuilder?.call(state) ?? {};
    
    final hasPermission = await permissionService.hasPermission(
      userId: user.id,
      resource: permissionContext['resource'] ?? 'default',
      action: permission,
      context: permissionContext,
    );
    
    if (hasPermission) {
      resolver.next();
    } else {
      resolver.redirect('/unauthorized');
    }
  }
}

// Usage
@TypedGoRoute<EditDocumentRoute>(path: '/document/:id/edit')
class EditDocumentRoute extends GoRouteData with GuardedRoute {
  const EditDocumentRoute({required this.id});
  
  final String id;

  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    ContextAwarePermissionGuard(
      permission: 'edit',
      contextBuilder: (state) => {
        'resource': 'document',
        'resourceId': state.pathParameters['id'],
        'action': 'edit',
      },
    ),
  ]);
}
```

### Time-Based Role Access

```dart
class TimeBasedRoleGuard extends GoRouterGuard {
  const TimeBasedRoleGuard({
    required this.baseRole,
    required this.timeRestrictedRole,
    required this.allowedHours,
  });
  
  final UserRole baseRole;
  final UserRole timeRestrictedRole;
  final List<int> allowedHours;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = context.read<UserCubit>().state.user;
    
    if (user == null) {
      resolver.redirect('/login');
      return;
    }

    final now = DateTime.now();
    final isBusinessHours = allowedHours.contains(now.hour);
    
    final requiredRole = isBusinessHours ? baseRole : timeRestrictedRole;
    
    if (user.role.hasPermissionLevel(requiredRole)) {
      resolver.next();
    } else {
      if (isBusinessHours) {
        resolver.redirect('/unauthorized');
      } else {
        resolver.redirect('/outside-business-hours');
      }
    }
  }
}
```

### Department-Based Access

```dart
class DepartmentGuard extends GoRouterGuard {
  const DepartmentGuard(this.allowedDepartments);
  
  final List<String> allowedDepartments;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = context.read<UserCubit>().state.user;
    
    if (user == null) {
      resolver.redirect('/login');
      return;
    }

    final userDepartment = await userService.getUserDepartment(user.id);
    
    if (allowedDepartments.contains(userDepartment)) {
      resolver.next();
    } else {
      resolver.redirect('/department-restricted');
    }
  }
}
```

## Testing RBAC

```dart
void main() {
  group('Role-Based Access Control', () {
    late MockUserCubit userCubit;

    setUp(() {
      userCubit = MockUserCubit();
    });

    testWidgets('admin can access admin routes', (tester) async {
      when(() => userCubit.state).thenReturn(
        UserState(user: User(
          id: '1',
          email: 'admin@example.com',
          name: 'Admin User',
          role: UserRole.admin,
          createdAt: DateTime.now(),
        )),
      );

      await tester.pumpWidget(
        BlocProvider<UserCubit>.value(
          value: userCubit,
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [...AdminDashboardRoute().routes],
            ),
          ),
        ),
      );

      AdminDashboardRoute().go(tester.element(find.byType(MaterialApp)));
      await tester.pumpAndSettle();

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
    });

    testWidgets('regular user cannot access admin routes', (tester) async {
      when(() => userCubit.state).thenReturn(
        UserState(user: User(
          id: '2',
          email: 'user@example.com',
          name: 'Regular User',
          role: UserRole.user,
          createdAt: DateTime.now(),
        )),
      );

      await tester.pumpWidget(
        BlocProvider<UserCubit>.value(
          value: userCubit,
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                ...AdminDashboardRoute().routes,
                GoRoute(
                  path: '/unauthorized',
                  builder: (context, state) => const UnauthorizedScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      AdminDashboardRoute().go(tester.element(find.byType(MaterialApp)));
      await tester.pumpAndSettle();

      expect(find.byType(UnauthorizedScreen), findsOneWidget);
    });
  });
}
```

This comprehensive RBAC example demonstrates how to implement sophisticated role and permission-based access control using Go Router Guards, providing flexible and secure navigation protection for enterprise applications.

## Key Features Demonstrated

1. **Hierarchical Roles**: Role levels with inheritance
2. **Permission-Based Access**: Fine-grained permission checking
3. **Dynamic Permissions**: Runtime permission validation
4. **Context-Aware Guards**: Permissions based on route context
5. **Multi-Layer Protection**: Shell route + individual route guards
6. **Caching**: Performance optimization for permission checks
7. **Error Handling**: Secure fallback behavior
8. **Testing**: Comprehensive test coverage

## Next Steps

- 🔒 Explore [Permission Guards](/examples/permission-guards/)
- 🏗️ See [Multi-Layer Protection](/examples/multi-layer-protection/)
- 📋 Review [Best Practices](/guides/best-practices/)
- 🧪 Learn [Testing Strategies](/guides/testing-guards/)
