---
title: Permission Guards
description: Implement fine-grained permission-based access control with dynamic permission checking
---

import { Steps, Tabs, TabItem } from '@astrojs/starlight/components';

This example demonstrates implementing sophisticated permission-based access control that goes beyond simple role checking to provide fine-grained, dynamic permission management.

## Permission System Architecture

```dart
// lib/models/permission.dart
class Permission {
  final String id;
  final String name;
  final String description;
  final String resource;
  final String action;
  final Map<String, dynamic> constraints;

  const Permission({
    required this.id,
    required this.name,
    required this.description,
    required this.resource,
    required this.action,
    this.constraints = const {},
  });

  String get fullName => '${action}_$resource';

  bool matchesRequest({
    required String requestResource,
    required String requestAction,
    Map<String, dynamic>? context,
  }) {
    // Exact match
    if (resource == requestResource && action == requestAction) {
      return _checkConstraints(context);
    }

    // Wildcard matches
    if (resource == '*' && action == requestAction) {
      return _checkConstraints(context);
    }

    if (resource == requestResource && action == '*') {
      return _checkConstraints(context);
    }

    if (resource == '*' && action == '*') {
      return _checkConstraints(context);
    }

    return false;
  }

  bool _checkConstraints(Map<String, dynamic>? context) {
    if (constraints.isEmpty) return true;
    if (context == null) return constraints.isEmpty;

    for (final entry in constraints.entries) {
      final contextValue = context[entry.key];
      final constraintValue = entry.value;

      if (!_matchesConstraint(contextValue, constraintValue)) {
        return false;
      }
    }

    return true;
  }

  bool _matchesConstraint(dynamic contextValue, dynamic constraintValue) {
    if (constraintValue is List) {
      return constraintValue.contains(contextValue);
    }

    if (constraintValue is Map) {
      // Range constraint
      if (constraintValue.containsKey('min') || constraintValue.containsKey('max')) {
        final value = contextValue as num?;
        if (value == null) return false;

        final min = constraintValue['min'] as num?;
        final max = constraintValue['max'] as num?;

        if (min != null && value < min) return false;
        if (max != null && value > max) return false;

        return true;
      }

      // Pattern constraint
      if (constraintValue.containsKey('pattern')) {
        final pattern = constraintValue['pattern'] as String;
        final value = contextValue?.toString();
        if (value == null) return false;

        return RegExp(pattern).hasMatch(value);
      }
    }

    return contextValue == constraintValue;
  }
}
```

## Dynamic Permission Service

```dart
// lib/services/permission_service.dart
import 'dart:async';

class PermissionService {
  final ApiClient _apiClient;
  final Map<String, CachedPermissions> _userPermissionCache = {};
  static const Duration _cacheExpiry = Duration(minutes: 10);

  PermissionService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<bool> hasPermission({
    required String userId,
    required String resource,
    required String action,
    Map<String, dynamic>? context,
  }) async {
    try {
      final permissions = await _getUserPermissions(userId);
      
      for (final permission in permissions) {
        if (permission.matchesRequest(
          requestResource: resource,
          requestAction: action,
          context: context,
        )) {
          return true;
        }
      }

      return false;
    } catch (error) {
      logger.error('Permission check failed: $error');
      return false; // Fail securely
    }
  }

  Future<List<Permission>> _getUserPermissions(String userId) async {
    final cached = _userPermissionCache[userId];
    if (cached != null && !cached.isExpired) {
      return cached.permissions;
    }

    final permissions = await _apiClient.getUserPermissions(userId);
    _userPermissionCache[userId] = CachedPermissions(
      permissions: permissions,
      timestamp: DateTime.now(),
    );

    return permissions;
  }

  void clearUserCache(String userId) {
    _userPermissionCache.remove(userId);
  }

  void clearAllCache() {
    _userPermissionCache.clear();
  }

  Future<List<Permission>> getResourcePermissions({
    required String userId,
    required String resource,
  }) async {
    final allPermissions = await _getUserPermissions(userId);
    return allPermissions.where((p) => 
      p.resource == resource || p.resource == '*'
    ).toList();
  }

  Future<bool> canPerformBulkAction({
    required String userId,
    required String resource,
    required String action,
    required List<String> resourceIds,
  }) async {
    for (final resourceId in resourceIds) {
      final hasPermission = await this.hasPermission(
        userId: userId,
        resource: resource,
        action: action,
        context: {'resourceId': resourceId},
      );

      if (!hasPermission) {
        return false;
      }
    }

    return true;
  }
}

class CachedPermissions {
  final List<Permission> permissions;
  final DateTime timestamp;

  CachedPermissions({
    required this.permissions,
    required this.timestamp,
  });

  bool get isExpired =>
      DateTime.now().difference(timestamp) > PermissionService._cacheExpiry;
}
```

## Permission Guards

```dart
// lib/guards/permission_guards.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_guards/go_router_guards.dart';

// Basic permission guard
class PermissionGuard extends GoRouterGuard {
  const PermissionGuard({
    required this.resource,
    required this.action,
    this.contextBuilder,
  });

  final String resource;
  final String action;
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
      resource: resource,
      action: action,
      context: permissionContext,
    );

    if (hasPermission) {
      resolver.next();
    } else {
      resolver.redirect('/unauthorized?resource=$resource&action=$action');
    }
  }
}

// Resource ownership guard
class ResourceOwnershipGuard extends GoRouterGuard {
  const ResourceOwnershipGuard({
    required this.resourceType,
    required this.resourceIdParam,
  });

  final String resourceType;
  final String resourceIdParam;

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

    final resourceId = state.pathParameters[resourceIdParam];
    if (resourceId == null) {
      resolver.redirect('/not-found');
      return;
    }

    // Check if user owns the resource
    final isOwner = await resourceService.isOwner(
      userId: user.id,
      resourceType: resourceType,
      resourceId: resourceId,
    );

    if (isOwner) {
      resolver.next();
      return;
    }

    // If not owner, check if they have admin permission
    final hasAdminPermission = await permissionService.hasPermission(
      userId: user.id,
      resource: resourceType,
      action: 'admin',
      context: {'resourceId': resourceId},
    );

    if (hasAdminPermission) {
      resolver.next();
    } else {
      resolver.redirect('/unauthorized?reason=not_owner');
    }
  }
}

// Conditional permission guard
class ConditionalPermissionGuard extends GoRouterGuard {
  const ConditionalPermissionGuard({
    required this.permissions,
    this.requireAll = false,
  });

  final List<PermissionCheck> permissions;
  final bool requireAll;

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

    final results = await Future.wait(
      permissions.map((permission) async {
        final permissionContext = permission.contextBuilder?.call(state) ?? {};
        
        return await permissionService.hasPermission(
          userId: user.id,
          resource: permission.resource,
          action: permission.action,
          context: permissionContext,
        );
      }),
    );

    final hasPermission = requireAll 
        ? results.every((result) => result)
        : results.any((result) => result);

    if (hasPermission) {
      resolver.next();
    } else {
      final missingPermissions = permissions
          .asMap()
          .entries
          .where((entry) => !results[entry.key])
          .map((entry) => '${entry.value.action}_${entry.value.resource}')
          .join(',');
      
      resolver.redirect('/unauthorized?missing=$missingPermissions');
    }
  }
}

class PermissionCheck {
  final String resource;
  final String action;
  final Map<String, dynamic> Function(GoRouterState)? contextBuilder;

  const PermissionCheck({
    required this.resource,
    required this.action,
    this.contextBuilder,
  });
}

// Time-sensitive permission guard
class TimeSensitivePermissionGuard extends GoRouterGuard {
  const TimeSensitivePermissionGuard({
    required this.resource,
    required this.action,
    this.businessHoursOnly = false,
    this.allowedDays,
  });

  final String resource;
  final String action;
  final bool businessHoursOnly;
  final List<int>? allowedDays; // 1-7 (Monday-Sunday)

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

    // Check time restrictions
    if (businessHoursOnly) {
      if (now.hour < 9 || now.hour > 17) {
        resolver.redirect('/outside-business-hours');
        return;
      }
    }

    if (allowedDays != null) {
      if (!allowedDays!.contains(now.weekday)) {
        resolver.redirect('/not-allowed-today');
        return;
      }
    }

    // Check permission with time context
    final hasPermission = await permissionService.hasPermission(
      userId: user.id,
      resource: resource,
      action: action,
      context: {
        'currentTime': now.toIso8601String(),
        'isBusinessHours': now.hour >= 9 && now.hour <= 17,
        'dayOfWeek': now.weekday,
      },
    );

    if (hasPermission) {
      resolver.next();
    } else {
      resolver.redirect('/unauthorized?reason=time_restricted');
    }
  }
}

// Bulk action permission guard
class BulkActionGuard extends GoRouterGuard {
  const BulkActionGuard({
    required this.resource,
    required this.action,
    required this.resourceIdsParam,
  });

  final String resource;
  final String action;
  final String resourceIdsParam;

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

    final resourceIdsString = state.uri.queryParameters[resourceIdsParam];
    if (resourceIdsString == null) {
      resolver.redirect('/bad-request?missing=$resourceIdsParam');
      return;
    }

    final resourceIds = resourceIdsString.split(',');
    
    final canPerformBulkAction = await permissionService.canPerformBulkAction(
      userId: user.id,
      resource: resource,
      action: action,
      resourceIds: resourceIds,
    );

    if (canPerformBulkAction) {
      resolver.next();
    } else {
      resolver.redirect('/unauthorized?reason=bulk_action_denied');
    }
  }
}
```

## Route Applications

```dart
// lib/routes/permission_routes.dart
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

// Document viewing (read permission)
@TypedGoRoute<ViewDocumentRoute>(path: '/document/:id')
class ViewDocumentRoute extends GoRouteData with GuardedRoute {
  const ViewDocumentRoute({required this.id});
  
  final String id;

  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    PermissionGuard(
      resource: 'document',
      action: 'read',
      contextBuilder: (state) => {
        'documentId': state.pathParameters['id'],
      },
    ),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return DocumentViewScreen(documentId: id);
  }
}

// Document editing (write permission + ownership or admin)
@TypedGoRoute<EditDocumentRoute>(path: '/document/:id/edit')
class EditDocumentRoute extends GoRouteData with GuardedRoute {
  const EditDocumentRoute({required this.id});
  
  final String id;

  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    Guards.anyOf([
      ResourceOwnershipGuard(
        resourceType: 'document',
        resourceIdParam: 'id',
      ),
      PermissionGuard(
        resource: 'document',
        action: 'admin',
        contextBuilder: (state) => {
          'documentId': state.pathParameters['id'],
        },
      ),
    ]),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return DocumentEditScreen(documentId: id);
  }
}

// Financial reports (time-sensitive permissions)
@TypedGoRoute<FinancialReportsRoute>(path: '/reports/financial')
class FinancialReportsRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    TimeSensitivePermissionGuard(
      resource: 'financial_reports',
      action: 'read',
      businessHoursOnly: true,
      allowedDays: [1, 2, 3, 4, 5], // Monday to Friday
    ),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const FinancialReportsScreen();
  }
}

// Bulk document operations
@TypedGoRoute<BulkDocumentRoute>(path: '/documents/bulk')
class BulkDocumentRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    BulkActionGuard(
      resource: 'document',
      action: 'delete',
      resourceIdsParam: 'ids',
    ),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const BulkDocumentScreen();
  }
}

// Project management (multiple permission requirements)
@TypedGoRoute<ProjectManagementRoute>(path: '/project/:projectId/manage')
class ProjectManagementRoute extends GoRouteData with GuardedRoute {
  const ProjectManagementRoute({required this.projectId});
  
  final String projectId;

  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    ConditionalPermissionGuard(
      permissions: [
        PermissionCheck(
          resource: 'project',
          action: 'manage',
          contextBuilder: (state) => {
            'projectId': state.pathParameters['projectId'],
          },
        ),
        PermissionCheck(
          resource: 'team',
          action: 'read',
          contextBuilder: (state) => {
            'projectId': state.pathParameters['projectId'],
          },
        ),
      ],
      requireAll: true,
    ),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ProjectManagementScreen(projectId: projectId);
  }
}

// Department-specific access
@TypedGoRoute<DepartmentRoute>(path: '/department/:dept')
class DepartmentRoute extends GoRouteData with GuardedRoute {
  const DepartmentRoute({required this.dept});
  
  final String dept;

  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    PermissionGuard(
      resource: 'department',
      action: 'access',
      contextBuilder: (state) => {
        'department': state.pathParameters['dept'],
        'userDepartment': getCurrentUserDepartment(), // Would be implemented
      },
    ),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return DepartmentScreen(department: dept);
  }
}
```

## Advanced Permission Patterns

### Dynamic Permission Loading

```dart
class DynamicPermissionGuard extends GoRouterGuard {
  const DynamicPermissionGuard({
    required this.permissionLoader,
  });

  final Future<List<PermissionCheck>> Function(BuildContext, GoRouterState) 
      permissionLoader;

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

    try {
      // Load permissions dynamically based on context
      final requiredPermissions = await permissionLoader(context, state);
      
      for (final permission in requiredPermissions) {
        final permissionContext = permission.contextBuilder?.call(state) ?? {};
        
        final hasPermission = await permissionService.hasPermission(
          userId: user.id,
          resource: permission.resource,
          action: permission.action,
          context: permissionContext,
        );

        if (!hasPermission) {
          resolver.redirect(
            '/unauthorized?missing=${permission.action}_${permission.resource}',
          );
          return;
        }
      }

      resolver.next();
    } catch (error) {
      logger.error('Dynamic permission loading failed: $error');
      resolver.redirect('/error');
    }
  }
}

// Usage
@TypedGoRoute<DynamicRoute>(path: '/dynamic/:resourceType/:id')
class DynamicRoute extends GoRouteData with GuardedRoute {
  const DynamicRoute({required this.resourceType, required this.id});
  
  final String resourceType;
  final String id;

  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    DynamicPermissionGuard(
      permissionLoader: (context, state) async {
        final resourceType = state.pathParameters['resourceType']!;
        final id = state.pathParameters['id']!;
        
        // Load required permissions based on resource type
        final permissions = await permissionConfigService
            .getRequiredPermissions(resourceType);
        
        return permissions.map((p) => PermissionCheck(
          resource: resourceType,
          action: p,
          contextBuilder: (_) => {'resourceId': id},
        )).toList();
      },
    ),
  ]);
}
```

### Cache-Aware Permission Guard

```dart
class CacheAwarePermissionGuard extends GoRouterGuard {
  const CacheAwarePermissionGuard({
    required this.resource,
    required this.action,
    this.cacheKey,
    this.contextBuilder,
  });

  final String resource;
  final String action;
  final String? cacheKey;
  final Map<String, dynamic> Function(GoRouterState)? contextBuilder;

  static final Map<String, bool> _permissionCache = {};

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

    final effectiveCacheKey = cacheKey ?? 
        '${user.id}:$resource:$action:${state.uri.path}';

    // Check cache first
    if (_permissionCache.containsKey(effectiveCacheKey)) {
      if (_permissionCache[effectiveCacheKey]!) {
        resolver.next();
      } else {
        resolver.redirect('/unauthorized');
      }
      return;
    }

    // Check permission and cache result
    final permissionContext = contextBuilder?.call(state) ?? {};
    
    final hasPermission = await permissionService.hasPermission(
      userId: user.id,
      resource: resource,
      action: action,
      context: permissionContext,
    );

    _permissionCache[effectiveCacheKey] = hasPermission;

    if (hasPermission) {
      resolver.next();
    } else {
      resolver.redirect('/unauthorized');
    }
  }

  static void clearCache([String? pattern]) {
    if (pattern != null) {
      _permissionCache.removeWhere((key, _) => key.contains(pattern));
    } else {
      _permissionCache.clear();
    }
  }
}
```

## Testing Permission Guards

```dart
void main() {
  group('Permission Guards', () {
    late MockPermissionService permissionService;
    late MockUserCubit userCubit;

    setUp(() {
      permissionService = MockPermissionService();
      userCubit = MockUserCubit();
      GetIt.instance.registerSingleton<PermissionService>(permissionService);
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    testWidgets('PermissionGuard allows with valid permission', (tester) async {
      when(() => userCubit.state).thenReturn(
        UserState(user: testUser),
      );
      
      when(() => permissionService.hasPermission(
        userId: any(named: 'userId'),
        resource: 'document',
        action: 'read',
        context: any(named: 'context'),
      )).thenAnswer((_) async => true);

      final guard = PermissionGuard(
        resource: 'document',
        action: 'read',
      );

      final result = await guard.executeWithResolver(
        MockBuildContext(),
        MockGoRouterState(pathParameters: {'id': '123'}),
      );

      expect(result.continueNavigation, isTrue);
    });

    testWidgets('PermissionGuard blocks without permission', (tester) async {
      when(() => userCubit.state).thenReturn(
        UserState(user: testUser),
      );
      
      when(() => permissionService.hasPermission(
        userId: any(named: 'userId'),
        resource: 'document',
        action: 'delete',
        context: any(named: 'context'),
      )).thenAnswer((_) async => false);

      final guard = PermissionGuard(
        resource: 'document',
        action: 'delete',
      );

      final result = await guard.executeWithResolver(
        MockBuildContext(),
        MockGoRouterState(),
      );

      expect(result.continueNavigation, isFalse);
      expect(result.redirectPath, contains('/unauthorized'));
    });

    test('ConditionalPermissionGuard requires all permissions', () async {
      when(() => permissionService.hasPermission(
        userId: any(named: 'userId'),
        resource: 'project',
        action: 'read',
        context: any(named: 'context'),
      )).thenAnswer((_) async => true);

      when(() => permissionService.hasPermission(
        userId: any(named: 'userId'),
        resource: 'project',
        action: 'write',
        context: any(named: 'context'),
      )).thenAnswer((_) async => false);

      final guard = ConditionalPermissionGuard(
        permissions: [
          PermissionCheck(resource: 'project', action: 'read'),
          PermissionCheck(resource: 'project', action: 'write'),
        ],
        requireAll: true,
      );

      final result = await guard.executeWithResolver(
        MockBuildContext(),
        MockGoRouterState(),
      );

      expect(result.continueNavigation, isFalse);
    });
  });
}
```

## Performance Monitoring

```dart
class PerformanceMonitoredPermissionGuard extends GoRouterGuard {
  const PerformanceMonitoredPermissionGuard({
    required this.resource,
    required this.action,
    this.contextBuilder,
  });

  final String resource;
  final String action;
  final Map<String, dynamic> Function(GoRouterState)? contextBuilder;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final stopwatch = Stopwatch()..start();
    final guardName = 'PermissionGuard($resource:$action)';

    try {
      final user = context.read<UserCubit>().state.user;
      
      if (user == null) {
        _recordMetric(guardName, stopwatch.elapsedMilliseconds, 'unauthorized');
        resolver.redirect('/login');
        return;
      }

      final permissionContext = contextBuilder?.call(state) ?? {};
      
      final hasPermission = await permissionService.hasPermission(
        userId: user.id,
        resource: resource,
        action: action,
        context: permissionContext,
      );

      if (hasPermission) {
        _recordMetric(guardName, stopwatch.elapsedMilliseconds, 'allowed');
        resolver.next();
      } else {
        _recordMetric(guardName, stopwatch.elapsedMilliseconds, 'denied');
        resolver.redirect('/unauthorized');
      }
    } catch (error) {
      _recordMetric(guardName, stopwatch.elapsedMilliseconds, 'error');
      logger.error('Permission guard error: $error');
      resolver.redirect('/error');
    } finally {
      stopwatch.stop();
    }
  }

  void _recordMetric(String guardName, int durationMs, String result) {
    analyticsService.recordEvent('guard_execution', {
      'guard_type': guardName,
      'duration_ms': durationMs,
      'result': result,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
```

This comprehensive permission guard system provides fine-grained, dynamic access control that can adapt to complex business requirements while maintaining performance and security.

## Key Features Demonstrated

1. **Fine-Grained Permissions**: Resource and action-based permission checking
2. **Dynamic Context**: Context-aware permission validation
3. **Performance Optimization**: Caching and bulk operations
4. **Time-Based Access**: Business hours and day restrictions
5. **Resource Ownership**: Owner-based access control
6. **Bulk Operations**: Efficient multi-resource permission checking
7. **Error Handling**: Secure failure modes
8. **Performance Monitoring**: Analytics and metrics collection

## Next Steps

- 🏗️ See [Multi-Layer Protection](/examples/multi-layer-protection/)
- 📋 Review [Best Practices](/guides/best-practices/)
- 🧪 Explore [Testing Strategies](/guides/testing-guards/)
- ⚡ Learn [Performance Optimization](/guides/performance/)
