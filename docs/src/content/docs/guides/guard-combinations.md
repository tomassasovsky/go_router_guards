---
title: Guard Combinations
description: Learn how to combine multiple guards with logical operators for complex protection scenarios
---

import { Tabs, TabItem } from '@astrojs/starlight/components';

Guard combinations allow you to create sophisticated protection logic by composing simple guards with logical operators. This approach promotes reusability and makes complex authorization scenarios easy to manage.

## The Guards Utility

The `Guards` class provides three main combination methods:

| Method | Logic | Description |
|--------|-------|-------------|
| `Guards.all()` | AND | All guards must pass |
| `Guards.anyOf()` | OR | At least one guard must pass |
| `Guards.oneOf()` | XOR | Exactly one guard must pass |

## Guards.all() - AND Logic

All guards must pass for navigation to continue. This is the most common combination pattern.

### Basic Usage

```dart
final adminGuard = Guards.all([
  AuthGuard(),
  RoleGuard(['admin']),
]);
```

### Complex Authorization

```dart
final superAdminGuard = Guards.all([
  AuthGuard(),                    // Must be logged in
  RoleGuard(['admin']),          // Must have admin role
  PermissionGuard(['super_admin']), // Must have super admin permission
  SubscriptionGuard(),           // Must have active subscription
  FeatureFlagGuard('admin_panel'), // Feature must be enabled
]);
```

### Route-Level Application

<Tabs>
  <TabItem label="Type-Safe Routes">
```dart
@TypedGoRoute<AdminDashboardRoute>(path: '/admin/dashboard')
class AdminDashboardRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    RoleGuard(['admin']),
    PermissionGuard(['dashboard_access']),
  ]);
}
```
  </TabItem>
  
  <TabItem label="Traditional Routes">
```dart
GoRoute(
  path: '/admin/dashboard',
  builder: (context, state) => const AdminDashboard(),
  redirect: RouteGuardUtils.createGuardRedirect(
    Guards.all([
      AuthGuard(),
      RoleGuard(['admin']),
      PermissionGuard(['dashboard_access']),
    ]),
  ),
)
```
  </TabItem>
</Tabs>

## Guards.anyOf() - OR Logic

At least one guard must pass. Useful for multiple valid access paths.

### Multiple Authentication Methods

```dart
final accessGuard = Guards.anyOf([
  AdminGuard(),           // Admins can always access
  SubscriptionGuard(),    // OR users with subscription
  TrialGuard(),          // OR users on trial
]);
```

### Flexible Role Requirements

```dart
final moderationGuard = Guards.anyOf([
  RoleGuard(['admin']),      // Admins can moderate
  RoleGuard(['moderator']),  // OR moderators can moderate
  PermissionGuard(['moderate']), // OR users with permission
]);
```

### Fallback Access Patterns

```dart
final premiumContentGuard = Guards.anyOf([
  SubscriptionGuard(['premium', 'enterprise']), // Premium subscribers
  PromotionalAccessGuard(),                     // OR promotional access
  StaffAccessGuard(),                          // OR staff access
]);
```

### Route Example

```dart
@TypedGoRoute<PremiumRoute>(path: '/premium')
class PremiumRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(), // Must be authenticated
    Guards.anyOf([ // AND one of these conditions
      SubscriptionGuard(['premium']),
      RoleGuard(['admin', 'staff']),
      PromotionalAccessGuard(),
    ]),
  ]);
}
```

## Guards.oneOf() - XOR Logic

Exactly one guard must pass. Useful for mutually exclusive conditions.

### Environment-Based Access

```dart
final environmentGuard = Guards.oneOf([
  DevelopmentModeGuard(),  // Either in development
  StaffAccessGuard(),     // OR staff access (but not both)
]);
```

### Exclusive Feature Access

```dart
final betaFeatureGuard = Guards.oneOf([
  BetaTesterGuard(),      // Either beta tester
  InternalUserGuard(),    // OR internal user
]);
```

### A/B Testing

```dart
final experimentGuard = Guards.oneOf([
  ExperimentGroupAGuard(), // User in experiment group A
  ExperimentGroupBGuard(), // OR user in experiment group B
]);
```

## Nested Combinations

Combine the combination methods for complex logic:

### Complex Business Logic

```dart
final complexGuard = Guards.all([
  AuthGuard(), // Must be authenticated
  Guards.anyOf([ // AND one of these role conditions
    RoleGuard(['admin']),
    Guards.all([ // OR all of these conditions
      RoleGuard(['user']),
      SubscriptionGuard(['premium']),
      FeatureFlagGuard('advanced_features'),
    ]),
  ]),
  Guards.oneOf([ // AND exactly one environment condition
    ProductionAccessGuard(),
    DevelopmentModeGuard(),
  ]),
]);
```

### Multi-Tenant Access

```dart
final tenantGuard = Guards.all([
  AuthGuard(),
  TenantMemberGuard(), // Must be member of the tenant
  Guards.anyOf([ // AND one of these permission sets
    TenantAdminGuard(),
    Guards.all([
      TenantUserGuard(),
      FeatureEnabledForTenantGuard('feature_name'),
    ]),
  ]),
]);
```

## Custom Combination Logic

For complex scenarios, create custom combination guards:

### Majority Guard

Requires majority of guards to pass:

```dart
class MajorityGuard extends RouteGuard {
  const MajorityGuard(this.guards);
  
  final List<RouteGuard> guards;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    Object context,
    Object state,
  ) async {
    int passedCount = 0;
    
    for (final guard in guards) {
      final result = await guard.executeWithResolver(context, state);
      if (result.continueNavigation) {
        passedCount++;
      }
    }
    
    final majority = (guards.length / 2).ceil();
    
    if (passedCount >= majority) {
      resolver.next();
    } else {
      resolver.redirect('/insufficient-permissions');
    }
  }
}

// Usage
final majorityGuard = MajorityGuard([
  RoleGuard(['admin']),
  PermissionGuard(['edit']),
  SubscriptionGuard(),
  FeatureFlagGuard('editing'),
]);
```

### Weighted Guard

Different guards have different weights:

```dart
class WeightedGuard extends RouteGuard {
  const WeightedGuard(this.weightedGuards, {required this.threshold});
  
  final Map<RouteGuard, int> weightedGuards;
  final int threshold;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    Object context,
    Object state,
  ) async {
    int totalWeight = 0;
    
    for (final entry in weightedGuards.entries) {
      final result = await entry.key.executeWithResolver(context, state);
      if (result.continueNavigation) {
        totalWeight += entry.value;
      }
    }
    
    if (totalWeight >= threshold) {
      resolver.next();
    } else {
      resolver.redirect('/insufficient-access');
    }
  }
}

// Usage
final weightedGuard = WeightedGuard({
  RoleGuard(['admin']): 10,      // Admin role worth 10 points
  SubscriptionGuard(): 5,        // Subscription worth 5 points
  PermissionGuard(['read']): 3,  // Read permission worth 3 points
  FeatureFlagGuard('beta'): 2,   // Beta access worth 2 points
}, threshold: 8); // Need at least 8 points
```

### Conditional Combination

Combine guards based on runtime conditions:

```dart
class ConditionalCombinationGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = context.read<UserCubit>().state.user;
    
    RouteGuard guard;
    
    if (user?.isNewUser == true) {
      // New users need lighter requirements
      guard = Guards.anyOf([
        TrialGuard(),
        TutorialCompletedGuard(),
      ]);
    } else if (user?.isPremium == true) {
      // Premium users get full access
      guard = SubscriptionGuard();
    } else {
      // Regular users need multiple conditions
      guard = Guards.all([
        AuthGuard(),
        RoleGuard(['user']),
        UsageLimitGuard(),
      ]);
    }
    
    await guard.onNavigation(resolver, context, state);
  }
}
```

## Real-World Examples

### E-commerce Admin Panel

```dart
final ecommerceAdminGuard = Guards.all([
  AuthGuard(), // Must be logged in
  Guards.anyOf([ // AND one of these conditions
    RoleGuard(['super_admin']), // Super admin has full access
    Guards.all([ // OR limited admin with permissions
      RoleGuard(['admin']),
      PermissionGuard(['manage_products', 'view_orders']),
    ]),
    Guards.all([ // OR store manager with store access
      RoleGuard(['store_manager']),
      StoreAccessGuard(),
      FeatureFlagGuard('multi_store_management'),
    ]),
  ]),
  Guards.oneOf([ // AND exactly one access method
    DirectLoginGuard(),     // Direct login
    ImpersonationGuard(),   // Or admin impersonation
  ]),
]);
```

### Content Management System

```dart
final cmsGuard = Guards.all([
  AuthGuard(),
  Guards.anyOf([
    // Content creators
    Guards.all([
      RoleGuard(['content_creator']),
      PermissionGuard(['create_content']),
    ]),
    // Editors
    Guards.all([
      RoleGuard(['editor']),
      PermissionGuard(['edit_content', 'publish_content']),
    ]),
    // Admins (full access)
    RoleGuard(['admin']),
  ]),
  // Must have content feature enabled
  FeatureFlagGuard('content_management'),
]);
```

### Multi-Tenant SaaS Application

```dart
final saasGuard = Guards.all([
  AuthGuard(),
  TenantMemberGuard(),
  Guards.anyOf([
    // Tenant admin
    TenantRoleGuard(['admin']),
    // Power user with subscription
    Guards.all([
      TenantRoleGuard(['power_user']),
      TenantSubscriptionGuard(['pro', 'enterprise']),
    ]),
    // Regular user with specific permission
    Guards.all([
      TenantRoleGuard(['user']),
      TenantPermissionGuard(['access_feature']),
      TenantFeatureFlagGuard('user_advanced_access'),
    ]),
  ]),
]);
```

## Testing Guard Combinations

### Unit Testing

```dart
void main() {
  group('Guard Combinations', () {
    test('Guards.all passes when all guards pass', () async {
      final guard = Guards.all([
        _MockPassingGuard(),
        _MockPassingGuard(),
        _MockPassingGuard(),
      ]);

      final result = await guard.executeWithResolver(
        MockContext(),
        MockState(),
      );

      expect(result.continueNavigation, isTrue);
    });

    test('Guards.all fails when any guard fails', () async {
      final guard = Guards.all([
        _MockPassingGuard(),
        _MockFailingGuard(),
        _MockPassingGuard(),
      ]);

      final result = await guard.executeWithResolver(
        MockContext(),
        MockState(),
      );

      expect(result.continueNavigation, isFalse);
    });

    test('Guards.anyOf passes when at least one guard passes', () async {
      final guard = Guards.anyOf([
        _MockFailingGuard(),
        _MockPassingGuard(),
        _MockFailingGuard(),
      ]);

      final result = await guard.executeWithResolver(
        MockContext(),
        MockState(),
      );

      expect(result.continueNavigation, isTrue);
    });
  });
}
```

### Integration Testing

```dart
void main() {
  testWidgets('Complex guard combination works in routes', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/complex',
              builder: (context, state) => const ComplexScreen(),
              redirect: RouteGuardUtils.createGuardRedirect(
                Guards.all([
                  AuthGuard(),
                  Guards.anyOf([
                    RoleGuard(['admin']),
                    SubscriptionGuard(),
                  ]),
                ]),
              ),
            ),
          ],
        ),
      ),
    );

    // Test various combinations of auth state and roles
    // ... test implementation
  });
}
```

## Performance Considerations

### Early Exit Optimization

Guards automatically optimize execution:

```dart
// Guards.all() stops on first failure
final guard = Guards.all([
  FastGuard(),      // Executes first
  SlowGuard(),      // May not execute if FastGuard fails
  ExpensiveGuard(), // May not execute if earlier guards fail
]);

// Guards.anyOf() stops on first success
final guard = Guards.anyOf([
  QuickCheckGuard(), // Executes first
  SlowFallbackGuard(), // Only executes if QuickCheckGuard fails
]);
```

### Guard Ordering

Order guards by execution time for optimal performance:

```dart
// ✅ Good - fast checks first
final optimizedGuard = Guards.all([
  LocalCacheGuard(),    // Fastest - in-memory check
  DatabaseGuard(),      // Medium - database query
  ExternalAPIGuard(),   // Slowest - network call
]);

// ❌ Bad - slow checks first
final inefficientGuard = Guards.all([
  ExternalAPIGuard(),   // Slowest first
  DatabaseGuard(),      // Medium
  LocalCacheGuard(),    // Fastest last (may not execute)
]);
```

## Best Practices

### 1. Logical Organization

```dart
// ✅ Good - logically organized
final guard = Guards.all([
  // Authentication layer
  AuthGuard(),
  
  // Authorization layer
  Guards.anyOf([
    RoleGuard(['admin']),
    PermissionGuard(['access']),
  ]),
  
  // Business logic layer
  SubscriptionGuard(),
]);
```

### 2. Reusable Combinations

```dart
class AppGuards {
  // Common combinations
  static RouteGuard get authenticated => AuthGuard();
  
  static RouteGuard get admin => Guards.all([
    authenticated,
    RoleGuard(['admin']),
  ]);
  
  static RouteGuard get moderator => Guards.all([
    authenticated,
    Guards.anyOf([
      RoleGuard(['admin', 'moderator']),
      PermissionGuard(['moderate']),
    ]),
  ]);
  
  static RouteGuard get premiumUser => Guards.all([
    authenticated,
    Guards.anyOf([
      SubscriptionGuard(['premium', 'enterprise']),
      RoleGuard(['staff', 'admin']),
    ]),
  ]);
}
```

### 3. Clear Documentation

```dart
/// Access control for user management features.
/// 
/// Requires:
/// 1. User authentication
/// 2. One of:
///    - Admin role
///    - HR role with user_management permission
///    - Manager role with team_management permission
final userManagementGuard = Guards.all([
  AuthGuard(),
  Guards.anyOf([
    RoleGuard(['admin']),
    Guards.all([
      RoleGuard(['hr']),
      PermissionGuard(['user_management']),
    ]),
    Guards.all([
      RoleGuard(['manager']),
      PermissionGuard(['team_management']),
    ]),
  ]),
]);
```

### 4. Error Handling

```dart
final robustGuard = Guards.all([
  SafeGuard(AuthGuard()),      // Wrapped for error handling
  SafeGuard(RoleGuard(['admin'])),
  SafeGuard(PermissionGuard(['access'])),
]);

class SafeGuard extends RouteGuard {
  const SafeGuard(this.guard);
  final RouteGuard guard;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    Object context,
    Object state,
  ) async {
    try {
      await guard.onNavigation(resolver, context, state);
    } catch (error) {
      // Log error and allow navigation to prevent app breakage
      logger.error('Guard failed: $error');
      resolver.next();
    }
  }
}
```

## Next Steps

Now that you understand guard combinations:

1. ⚙️ Learn about [Conditional Guards](/guides/conditional-guards/)
2. 📋 Review [Best Practices](/guides/best-practices/)
3. 📖 See real [Examples](/examples/multi-layer-protection/)
4. 🔄 Explore [Traditional Routes](/guides/traditional-routes/)
