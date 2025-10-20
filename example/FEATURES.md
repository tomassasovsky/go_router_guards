# Simple Example Features

This example showcases all major use cases of `go_router_guards` with type-safe routing.

## What's Included

### ✅ Type-Safe Routing
- Uses `GoRouteData` with `@TypedGoRoute` annotations
- Code generation with `build_runner`
- Type-safe navigation with `.go()`, `.push()`, `.replace()`

### ✅ Guard Types Demonstrated

1. **Authentication Guard** (`AuthGuard`)
   - Redirects to `/login` if not authenticated
   - Used in: Profile, Admin, Premium, Settings, Reports, Dashboard

2. **Role Guard** (`RoleGuard`)
   - Checks user roles (admin, premium, vip)
   - Blocks navigation if requirements not met
   - Used in: Admin, Premium, Reports

3. **Permission Guard** (`PermissionGuard`)
   - Fine-grained access control
   - Redirects to `/unauthorized` if permission missing
   - Used in: Settings, Reports

4. **Async Guard** (`AsyncAuthGuard`)
   - Demonstrates async operations (e.g., server validation)
   - Used in: Dashboard

5. **Conditional Guard** (`ConditionalGuard`)
   - Applies guards only to specific paths
   - Used in: Secret Info route

### ✅ Guard Combinations

- **`.all()`** - All guards must pass
  ```dart
  [AuthGuard(), RoleGuard(['admin'])].all()
  ```

- **`.anyOf()`** - At least one guard must pass
  ```dart
  [RoleGuard(['premium']), RoleGuard(['vip'])].anyOf()
  ```

- **Nested combinations** - Complex logic
  ```dart
  [
    AuthGuard(),
    [RoleGuard(['admin']), PermissionGuard('view_reports')].anyOf()
  ].all()
  ```

### ✅ Interactive Testing

The home screen provides controls to:
- Toggle authentication (login/logout)
- Add/remove roles (admin, premium, vip)
- Grant/revoke permissions (view_settings, view_reports)

Navigate to different routes to see guards in action!

## Project Structure

```
simple_example/
├── lib/
│   ├── main.dart           # App entry point
│   ├── app_state.dart      # State management (auth, roles, permissions)
│   ├── guards.dart         # Guard implementations
│   ├── router.dart         # Type-safe route definitions
│   ├── router.g.dart       # Generated code
│   └── screens.dart        # UI screens
├── pubspec.yaml           # Dependencies
├── build.yaml             # Build configuration
├── analysis_options.yaml  # Linter rules
└── README.md              # Documentation
```

## Routes Overview

| Route | Path | Guards | Behavior |
|-------|------|--------|----------|
| Home | `/` | None | Public |
| Login | `/login` | None | Public |
| Profile | `/profile` | Auth | Redirect to login |
| Admin | `/admin` | Auth + Admin role | Block if no admin |
| Premium | `/premium` | Auth + (Premium OR VIP) | Block if neither role |
| Settings | `/settings` | Auth + Permission | Redirect if no permission |
| Reports | `/reports` | Auth + (Admin OR Permission) | Redirect with fallback |
| Dashboard | `/dashboard` | Async Auth | Async check before access |
| Info | `/info` | None | Public |
| Secret Info | `/info/secret` | Conditional Auth | Only this path protected |
| Unauthorized | `/unauthorized` | None | Public error page |

## Running the Example

```bash
# Install dependencies
flutter pub get

# Generate code
dart run build_runner build

# Run the app
flutter run
```

## Key Learnings

1. **Type-safe routes** are cleaner and catch errors at compile time
2. **Guard composition** allows complex authorization logic without nested callbacks
3. **Conditional guards** enable flexible path-based protection
4. **Async guards** support real-world scenarios (API calls, token validation)
5. **Multiple guard behaviors** (allow, redirect, block) cover all use cases

