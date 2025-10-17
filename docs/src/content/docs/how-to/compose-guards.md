---
title: Compose guards
description: Combine guards with AND, OR, and XOR
---

## AND (all must pass)

```dart
final adminGuard = guardAll([
  const AuthGuard(),
  const RoleGuard(['admin']),
]);
```

## OR (any may pass)

```dart
final premiumAccess = guardAnyOf([
  const SubscriptionGuard(),
  const RoleGuard(['staff']),
]);
```

## XOR (exactly one must pass)

```dart
final exclusive = guardOneOf([
  const DevelopmentModeGuard(),
  const ProductionAccessGuard(),
]);
```

## Apply to a route

```dart
GoRoute(
  path: '/admin',
  builder: (c, s) => const AdminScreen(),
  redirect: adminGuard.toRedirect(),
)
```


