# Changelog

## [1.0.0+1] - 2025-01-27

### Added
- **Expression-Based Guard System**: Complete rewrite from chain-based to expression-based architecture
  - **GuardExpression**: Abstract base class for all guard expressions
  - **Binary Operators**: `And`, `Or`, `Xor` for combining two guard expressions
  - **Multi-Expression Operators**: `AndAll`, `OrAll`, `XorAll` for handling multiple guards efficiently
  - **Complex Boolean Logic**: Support for arbitrary boolean expressions like `(a & b) || (c & d) || e`
  - **Short-circuit Evaluation**: Performance optimization that stops execution early when possible

- **ExecutionOrder Enum**: Fine-grained control over guard execution
  - **leftToRight**: Execute expressions in the order they are provided (default)
  - **rightToLeft**: Execute expressions in reverse order
  - **parallel**: Execute expressions simultaneously for better performance

- **Guards Utility Class**: Fluent API for building guard expressions
  - `Guards.guard()` - Create guard expressions from RouteGuard
  - `Guards.and()` - Create AND expressions
  - `Guards.or()` - Create OR expressions
  - `Guards.xor()` - Create XOR expressions with custom redirect path
  - `Guards.andAll()` - Create AND expressions for multiple guards
  - `Guards.orAll()` - Create OR expressions for multiple guards
  - `Guards.xorAll()` - Create XOR expressions for multiple guards
  - `Guards.allow()` - Always allow access (for testing)

- **GuardedRoute Mixin**: Seamless integration with Go Router type-safe routes
  - Override `guards` getter to define route protection
  - Automatic guard execution on route access
  - Type-safe navigation throughout

- **Modular Package Architecture**: Organized code into focused, maintainable files
  - `core.dart` - Fundamental interfaces and enums
  - `expressions.dart` - Basic guard expression wrapper
  - `operators.dart` - Binary logical operators
  - `multi_operators.dart` - Multi-expression logical operators
  - `utilities.dart` - Fluent API and utility guards
  - `route.dart` - Go Router integration

- **Robust Error Handling**: Comprehensive input validation and safe parallel execution
  - Empty list validation for multi-expression operators
  - Empty redirect path validation for XOR operators
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
