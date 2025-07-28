# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0+1] - 2025-07-28

### Added
- **RouteGuard Interface**: Abstract base class for creating custom route guards
  - Supports both synchronous and asynchronous guard operations
  - Returns `null` to allow access or a redirect path to deny access
  - Full type safety with Go Router integration

- **GuardExpression System**: Expression-based guard system with logical operators
  - **Guard**: Wraps individual RouteGuard as expressions
  - **And**: Both expressions must pass for access to be granted
  - **Or**: At least one expression must pass for access to be granted
  - **Xor**: Exactly one expression must pass for access to be granted
  - Support for complex boolean logic like `(a & b) || c`

- **ExecutionOrder Enum**: Control how guard expressions are executed
  - **leftToRight**: Execute expressions in the order they are added (default)
  - **rightToLeft**: Execute expressions in reverse order
  - **parallel**: Execute expressions simultaneously for better performance

- **Guards Utility Class**: Fluent API for building guard expressions
  - `Guards.guard()` - Create guard expressions from RouteGuard
  - `Guards.and()` - Create AND expressions
  - `Guards.or()` - Create OR expressions
  - `Guards.xor()` - Create XOR expressions with custom redirect path

  - `Guards.allow()` - Always allow access (for testing)

- **Immutable GuardChain**: Copy-on-write guard chain system
  - Immutable design for better safety and performance
  - Method chaining with new instances returned
  - Backward compatibility with existing code
  - Const constructors for better performance

- **GuardedRoute Mixin**: Easy integration with Go Router type-safe routes
  - Override `guards` getter to define route protection
  - Automatic guard execution on route access
  - Type-safe navigation throughout

- **Comprehensive Testing**: Complete test coverage for all components
  - Unit tests for all logical operators
  - Execution order testing
  - Complex expression testing
  - Backward compatibility tests
  - Mock implementations for testing

- **Documentation**: Extensive documentation and examples
  - Quick start guide with type-safe route examples
  - Best practices for guard implementation
  - Migration guide from manual guards
  - Testing examples for guards and routes

### Features
- **Complex Boolean Logic**: Support for any boolean expression like `(a & b) || (c & d) || e`
- **Execution Order Control**: Choose how guards are executed for optimal performance
- **Type Safety**: Full type-safe navigation with compile-time safety
- **Performance Optimized**: Short-circuit evaluation and parallel execution options
- **Immutable Design**: Safe, predictable behavior with copy-on-write semantics
- **Extensible Architecture**: Easy to extend and customize for specific use cases

### Technical Details
- **SDK Requirements**: Flutter >=3.19.0, Dart SDK ^3.5.0
- **Dependencies**: go_router ^16.0.0
- **Development Tools**: build_runner, go_router_builder, mocktail, very_good_analysis
- **License**: MIT License

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
  Guards.and(
    Guards.guard(AuthenticationGuard()),
    Guards.guard(RoleGuard(['admin'])),
  )
  ```

- **New Expression System**: Use the new expression-based system for complex logic
  ```dart
  // Complex logic: (auth & role) || admin
  Guards.or(
    Guards.and(
      Guards.guard(AuthenticationGuard()),
      Guards.guard(RoleGuard(['admin'])),
    ),
    Guards.guard(SuperAdminGuard()),
  )
  ```

### Examples
```dart
// Type-safe route with complex guard logic
@TypedGoRoute<ProtectedRoute>(path: '/protected')
class ProtectedRoute extends GoRouteData with GuardedRoute {
  const ProtectedRoute();

  @override
  GuardExpression get guards => Guards.or(
    Guards.and(
      Guards.guard(AuthenticationGuard()),
      Guards.guard(RoleGuard(['admin'])),
    ),
    Guards.guard(SuperAdminGuard()),
  );

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ProtectedScreen();
  }
}

// Custom guard with execution order control
class PerformanceOptimizedGuard extends GuardExpression {
  const PerformanceOptimizedGuard() : super(executionOrder: ExecutionOrder.parallel);
  
  @override
  FutureOr<String?> execute(BuildContext context, GoRouterState state) async {
    // Parallel execution for better performance
    return null;
  }
}
```
