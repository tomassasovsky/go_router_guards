# Changelog

## [2.0.0+1] - 2025-10-19

### Added

- **Middleware-Style Navigation Control**: Complete rewrite with resolver pattern
  - **NavigationResolver**: New class providing `next()`, `redirect(path)`, and `block()` methods
  - **GuardResult**: Sealed class with `AllowResult` and `RedirectResult` for type-safe guard outcomes
  - Clearer mental model aligned with Express.js-style middleware

- **Guard Composition Functions**: New top-level functions for combining guards
  - `guardAll(guards)` - Requires all guards to pass (AND logic)
  - `guardAnyOf(guards, fallbackRedirect)` - Requires at least one guard to pass (OR logic)
  - `guardOneOf(guards, fallbackRedirect)` - Requires exactly one guard to pass (XOR logic)

- **Ergonomic List Extensions**: Fluent API for guard composition
  - `[guard1, guard2].all()` - Combine guards with AND logic
  - `[guard1, guard2].anyOf(fallbackRedirect: '/login')` - Combine with OR logic
  - `[guard1, guard2].oneOf(fallbackRedirect: '/error')` - Combine with XOR logic

- **Direct Redirect Extensions**: Convert guard collections to GoRouter redirects
  - `guards.redirectAll()` - Build redirect function from multiple guards
  - `guards.redirectAnyOf(fallbackRedirect: '/login')` - Build OR redirect
  - `guards.redirectOneOf(fallbackRedirect: '/error')` - Build XOR redirect

- **Conditional Guards**: Simple condition-based guards without boilerplate
  - `guardWhen(condition, redirect)` - Guard when condition is true
  - `guardUnless(condition, redirect)` - Guard when condition is false
  - Async condition support with futures

- **Factory Constructors**: Convenient guard creation methods
  - `RouteGuard.allow()` - Always allows navigation
  - `RouteGuard.redirectTo(path)` - Always redirects to path
  - `RouteGuard.from(callback)` - Create guard from callback function

- **Enhanced Error Handling**
  - Empty guard list validation for `anyOf` and `oneOf` (throws `ArgumentError`)
  - `RouterNotMountedException` for better error messages
  - Defensive null-safety throughout

- **Route Guard Utils**: Helper functions for common patterns
  - Utility functions for creating reusable guard compositions

### Changed

- **API Redesign**: Expression-based system replaced with middleware-style resolver pattern
  - Guards now implement `onNavigation(resolver, context, state)` instead of `redirect(context, state)`
  - More intuitive control flow with explicit `resolver.next()` calls
  - Better separation of concerns between guard logic and navigation control

- **Simplified Mental Model**: Removed complex expression tree in favor of straightforward function composition
  - No more `Guards.guard()` wrapper - use guards directly
  - Clearer semantics: "all must pass" vs "at least one must pass"
  - Reduced API surface area for easier learning

- **Improved Type Safety**: Sealed `GuardResult` class ensures exhaustive pattern matching
  - Compile-time guarantees that all result types are handled
  - No more nullable string returns

- **Better Short-Circuit Logic**: Optimized execution with early returns
  - `guardAll` stops at first redirect
  - `guardAnyOf` stops at first allow
  - `guardOneOf` optimally handles exactly-one semantics

### Removed

- **Expression-Based System**: Removed `GuardExpression` class hierarchy
  - `Guards.guard()` - No longer needed, use guards directly
  - `Guards.all()`, `Guards.anyOf()`, `Guards.oneOf()` - Replaced with top-level functions
  - `ExecutionOrder` enum - Simplified to always use optimal execution order

### Breaking Changes

- **RouteGuard Interface Changed**
  ```dart
  // Before (v2.0)
  class MyGuard implements RouteGuard {
    @override
    FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
      if (condition) return '/redirect';
      return null;
    }
  }
  
  // After (v2.1)
  class MyGuard extends RouteGuard {
    @override
    FutureOr<void> onNavigation(
      NavigationResolver resolver,
      BuildContext context,
      GoRouterState state,
    ) {
      if (condition) {
        resolver.redirect('/redirect');
      } else {
        resolver.next();
      }
    }
  }
  ```

- **Guard Composition Syntax**
  ```dart
  // Before (v2.0)
  Guards.all([
    Guards.guard(AuthGuard()),
    Guards.guard(RoleGuard(['admin'])),
  ])
  
  // After (v2.1)
  guardAll([
    AuthGuard(),
    RoleGuard(['admin']),
  ])
  // or
  [AuthGuard(), RoleGuard(['admin'])].all()
  ```

- **GuardedRoute Mixin**
  ```dart
  // Before (v2.0)
  @override
  GuardExpression get guards => Guards.all([...]);
  
  // After (v2.1)
  @override
  RouteGuard get guard => guardAll([...]);
  ```

### Migration Guide

1. **Update Guard Implementation**
   - Change from `redirect()` returning `String?` to `onNavigation()` using `NavigationResolver`
   - Replace `return null` with `resolver.next()`
   - Replace `return '/path'` with `resolver.redirect('/path')`

2. **Update Guard Composition**
   - Replace `Guards.all([Guards.guard(g1), ...])` with `guardAll([g1, ...])` or `[g1, ...].all()`
   - Replace `Guards.anyOf([Guards.guard(g1), ...])` with `guardAnyOf([g1, ...])` or `[g1, ...].anyOf()`
   - Replace `Guards.oneOf([Guards.guard(g1), ...])` with `guardOneOf([g1, ...])` or `[g1, ...].oneOf()`

3. **Update Route Mixins**
   - Change `GuardExpression get guards` to `RouteGuard get guard` (singular)
   - Update guard composition to use new functions

4. **Update Redirect Builders**
   - Use `.toRedirect()` on any `RouteGuard` instance
   - Or use `.redirectAll()`, `.redirectAnyOf()`, `.redirectOneOf()` on guard collections

### Examples

```dart
// Middleware-style guard
class AuthGuard extends RouteGuard {
  @override
  void onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final isAuth = await checkAuth();
    if (isAuth) {
      resolver.next();
    } else {
      resolver.redirect('/login');
    }
  }
}

// Ergonomic composition with extensions
final adminGuard = [
  AuthGuard(),
  RoleGuard(['admin']),
].all();

// Direct redirect builder
GoRoute(
  path: '/admin',
  redirect: [AuthGuard(), RoleGuard(['admin'])].redirectAll(),
  builder: (context, state) => AdminScreen(),
)

// Conditional guards
final featureGuard = guardWhen(
  () => featureFlags.isEnabled('premium'),
  '/upgrade',
);

// Type-safe routes with guards
@TypedGoRoute<AdminRoute>(path: '/admin')
class AdminRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guard => [
    AuthGuard(),
    RoleGuard(['admin']),
  ].all();
  
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AdminScreen();
  }
}
```

## [1.0.0+2] - 2025-07-28

### Changed
- Removed all references to `Guards.guard()` in the codebase.

## [1.0.0+1] - 2025-07-28

### Added
- **Expression-Based Guard System**: Complete rewrite from chain-based to expression-based architecture
  - **GuardExpression**: Abstract base class for all guard expressions
  - **Multi-Expression Operators**: `all`, `anyOf`, `oneOf` for handling multiple guards efficiently
  - **Complex Boolean Logic**: Support for arbitrary boolean expressions like `(a & b) || (c & d) || e`
  - **Short-circuit Evaluation**: Performance optimization that stops execution early when possible

- **ExecutionOrder Enum**: Fine-grained control over guard execution
  - **leftToRight**: Execute expressions in the order they are provided (default)
  - **rightToLeft**: Execute expressions in reverse order
  - **parallel**: Execute expressions simultaneously for better performance

- **Guards Utility Class**: Fluent API for building guard expressions
  - `Guards.guard()` - Create guard expressions from RouteGuard
  - `Guards.all()` - Create AND expressions for multiple guards
  - `Guards.anyOf()` - Create OR expressions for multiple guards
  - `Guards.oneOf()` - Create XOR expressions for multiple guards
  - `Guards.allow()` - Always allow access (for testing)

- **GuardedRoute Mixin**: Seamless integration with Go Router type-safe routes
  - Override `guards` getter to define route protection
  - Automatic guard execution on route access
  - Type-safe navigation throughout

- **Modular Package Architecture**: Organized code into focused, maintainable files
  - `core.dart` - Fundamental interfaces and enums
  - `expressions.dart` - Basic guard expression wrapper
  - `multi_operators.dart` - Multi-expression logical operators
  - `utilities.dart` - Fluent API and utility guards
  - `route.dart` - Go Router integration

- **Robust Error Handling**: Comprehensive input validation and safe parallel execution
  - Empty list validation for multi-expression operators
  - Safe parallel execution with `eagerError: false`
  - BuildContext.mounted checks to prevent async context issues

- **Performance Optimizations**: Multiple performance improvements
  - Short-circuit evaluation in `And`, `Or`, `AndAll`, `OrAll`, and `XorAll`
  - Parallel execution option for better performance
  - Immutable design for better safety and performance

### Changed
- **API Simplification**: Removed confusing `Not` operator for cleaner mental model
  - Eliminated double-negative logic that was confusing for navigation
  - Focused API on positive assertions that align with routing conventions
  - Improved developer experience with more intuitive guard expressions

- **Package Structure**: Completely reorganized from monolithic to modular architecture
  - Split single large file into 6 focused, logical files
  - Improved maintainability and code organization
  - Better separation of concerns

### Removed
- **GuardChain API**: Completely removed the old chain-based API
  - `GuardChain` class no longer exists
  - Simplified API by removing backward compatibility complexity
  - Migration to expression-based system required

### Breaking Changes
- **GuardChain API Removed**: The old chain API has been completely removed
  - `GuardChain` class no longer exists
  - Use the expression-based system with `Guards` utility instead
  - This simplifies the API and removes backward compatibility complexity

### Migration Guide
- **GuardChain Migration**: Replace chain API with expression-based system
  ```dart
  // Before (removed)
  GuardChain()
    .add(AuthenticationGuard())
    .add(RoleGuard(['admin']))
  
  // After (recommended)
  Guards.all([
    Guards.guard(AuthenticationGuard()),
    Guards.guard(RoleGuard(['admin'])),
  ])
  ```

- **New Expression System**: Use the new expression-based system for complex logic
  ```dart
  // Complex logic: (auth & role) || admin
  Guards.anyOf([
    Guards.all([
      Guards.guard(AuthenticationGuard()),
      Guards.guard(RoleGuard(['admin'])),
    ]),
    Guards.guard(SuperAdminGuard()),
  ])
  ```

### Examples
```dart
// Type-safe route with complex guard logic
@TypedGoRoute<ProtectedRoute>(path: '/protected')
class ProtectedRoute extends GoRouteData with GuardedRoute {
  const ProtectedRoute();

  @override
  GuardExpression get guards => Guards.anyOf([
    Guards.all([
      Guards.guard(AuthenticationGuard()),
      Guards.guard(RoleGuard(['admin'])),
    ]),
    Guards.guard(SuperAdminGuard()),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ProtectedScreen();
  }
}

// Performance-optimized guards with parallel execution
class PerformanceOptimizedGuard extends GuardExpression {
  const PerformanceOptimizedGuard() : super(executionOrder: ExecutionOrder.parallel);
  
  @override
  FutureOr<String?> execute(BuildContext context, GoRouterState state) async {
    // Parallel execution for better performance
    return null;
  }
}
```

## [0.1.0+1] - 2025-07-28

### Added
- **RouteGuard Interface**: Abstract base class for creating custom route guards
  - Supports both synchronous and asynchronous guard operations
  - Returns `null` to allow access or a redirect path to deny access
  - Full type safety with Go Router integration

- **GuardChain System**: Chainable guard system for executing multiple guards in sequence
  - Add guards individually with `add()` method
  - Add multiple guards at once with `addAll()` method
  - Execute guards in order with early termination on first redirect
  - Chain management with `clear()`, `length`, `isEmpty`, and `isNotEmpty` properties

- **GuardedRoute Mixin**: Mixin for applying guards to GoRouteData classes
  - Easy integration with existing Go Router type-safe routes
  - Override `guards` getter to define route protection
  - Automatic guard execution on route access

- **Type-Safe Navigation**: Full integration with Go Router's type-safe routing
  - Use `Route().location` for type-safe redirects
  - Compile-time safety for route paths
  - Integration with `@TypedGoRoute` annotations

- **Comprehensive Testing**: Complete test coverage for all components
  - Unit tests for RouteGuard interface
  - GuardChain execution and management tests
  - GuardedRoute integration tests
  - Mock implementations for testing

- **Documentation**: Extensive documentation and examples
  - Quick start guide with type-safe route examples
  - Best practices for guard implementation
  - Migration guide from manual guards
  - Testing examples for guards and routes

### Features
- **Flexible Guard System**: Create guards for authentication, permissions, app state, or any custom conditions
- **Chainable Guards**: Combine multiple guards in a single route for complex protection logic
- **Performance Optimized**: Guards execute in order with early termination for optimal performance
- **Error Handling**: Robust error handling with graceful fallbacks
- **Extensible Architecture**: Easy to extend and customize for specific use cases

### Technical Details
- **SDK Requirements**: Flutter >=3.19.0, Dart SDK ^3.5.0
- **Dependencies**: go_router ^16.0.0
- **Development Tools**: build_runner, go_router_builder, mocktail, very_good_analysis
- **License**: MIT License
