---
title: Router‑level guard
description: Apply a global redirect with ConditionalGuard
---

Use `ConditionalGuard` to protect many routes at once while excluding public paths.

## Example

```dart
final router = GoRouter(
  routes: $appRoutes,
  redirect: ConditionalGuard(
    guard: const AuthGuard(),
    excludedPaths: ['/', '/login', '/register'],
  ).toRedirect(),
);
```

## Tips

- Prefer excluding known public routes over complex include rules.
- Use `includedPatterns` or wildcard strings when you need pattern matching.


