# Testing Instructions for Enhanced Guards

This document provides comprehensive instructions for testing the enhanced guards system, including both automated tests and manual testing scenarios.

## 🧪 Automated Tests

### Running Tests

```bash
# Run all tests
flutter test

# Run only enhanced guards tests
flutter test test/enhanced_guards_test.dart

# Run tests with coverage
flutter test --coverage

# Run specific test
flutter test test/enhanced_guards_test.dart --plain-name "NavigationResolver should allow navigation with next()"
```

### Test Coverage

The enhanced guards system includes **91 automated tests** covering:

#### NavigationResolver Tests
- ✅ Creating resolver with context and state
- ✅ `next()` method functionality
- ✅ `redirect()` method functionality  
- ✅ `block()` method functionality (redirects to current location)
- ✅ Preventing double resolution
- ✅ `nextOrBack()` method behavior

#### RouteGuardEnhanced Tests
- ✅ Interface implementation
- ✅ `onNavigation` method execution
- ✅ Fallback to legacy `redirect` method
- ✅ Factory constructor functionality:
  - `simple()` factory
  - `redirect()` factory
  - `redirectIf()` factory
  - `redirectIfAsync()` factory

#### GuardsEnhanced Factory Tests
- ✅ All factory methods:
  - `simple()`
  - `redirectIf()` and `redirectIfAsync()`
  - `allow()` and `block()`
  - `authenticated()` and `authenticatedAsync()`
  - `hasRole()` and `hasRoleAsync()`
  - `all()` and `anyOf()`
  - `conditional()`

#### Integration Tests
- ✅ GuardedRoute mixin with enhanced guards
- ✅ Backward compatibility with legacy guards
- ✅ Error handling and edge cases

## 🎯 Manual Testing

### Setup for Manual Testing

1. **Navigate to the example directory:**
   ```bash
   cd example
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Create the manual test app main file:**
   ```bash
   # Create a new main file for testing
   cp lib/main.dart lib/main_backup.dart
   ```

4. **Update `lib/main.dart` to use the manual test app:**
   ```dart
   import 'package:flutter/material.dart';
   import 'package:flutter_bloc/flutter_bloc.dart';
   import 'manual_test_app.dart';

   void main() {
     runApp(const ManualTestApp());
   }

   class ManualTestApp extends StatelessWidget {
     const ManualTestApp({super.key});

     @override
     Widget build(BuildContext context) {
       return MultiBlocProvider(
         providers: [
           BlocProvider(create: (context) => AuthCubit()),
           BlocProvider(create: (context) => UserCubit()),
         ],
         child: MaterialApp.router(
           title: 'Enhanced Guards Manual Test',
           theme: ThemeData(
             colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
             useMaterial3: true,
           ),
           routerConfig: manualTestRouter,
         ),
       );
     }
   }
   ```

5. **Run the manual test app:**
   ```bash
   flutter run
   ```

### Manual Test Scenarios

The manual test app provides an interactive way to test all enhanced guard features:

#### 🏠 Home Screen Features
- **Status Display**: Shows current authentication and role status
- **Test Controls**: Buttons to toggle authentication, admin role, and premium role
- **Test Routes**: Buttons to navigate to different protected routes

#### 🔒 Guard Test Scenarios

##### 1. **Simple Guards Test** (`/factory-guards`)
**What it tests**: `GuardsEnhanced.simple()` with redirect and block behavior

**Test Steps**:
1. Click "Factory Guards" (should redirect to login if not authenticated)
2. Login, then try again (should redirect to unauthorized if not admin/moderator)
3. Toggle "Admin" role and try again (should succeed)

**Expected Behavior**:
- ❌ Unauthenticated → Login page
- ❌ Authenticated but no admin role → Unauthorized page  
- ✅ Authenticated + admin role → Success page

##### 2. **Custom Logic Test** (`/custom-logic`)
**What it tests**: Custom business logic with time-based conditions

**Test Steps**:
1. Note the current hour in the status display
2. Click "Custom Logic"
3. If it's an even hour and you're not admin, you should be redirected to maintenance
4. Toggle admin role and try again during even hours

**Expected Behavior**:
- ❌ Even hour + not admin → Maintenance page
- ✅ Odd hour OR admin → Success page

##### 3. **Conditional Guards Test** (`/conditional/admin`)
**What it tests**: `GuardsEnhanced.conditional()` with path-based logic

**Test Steps**:
1. Click "Conditional Guards" (goes to `/conditional/admin`)
2. Should require both authentication AND admin role
3. Try `/conditional/user` manually (should only require authentication)

**Expected Behavior**:
- Admin section: Requires auth + admin role
- User section: Only requires authentication

##### 4. **Flexible Access Test** (`/flexible-access`)
**What it tests**: `GuardsEnhanced.anyOf()` with multiple access conditions

**Test Steps**:
1. Click "Flexible Access" without any special roles
2. Toggle "Admin" role and try again
3. Remove admin, add "Premium" role and try again
4. Test during December (change system date if needed)

**Expected Behavior**:
- ✅ Admin role → Access granted
- ✅ Premium role → Access granted  
- ✅ December → Access granted
- ❌ None of the above → Access denied

##### 5. **Async Guards Test** (`/async-guard`)
**What it tests**: Async validation with external service simulation

**Test Steps**:
1. Must be authenticated first
2. Click "Async Guards"
3. Wait for the async validation (simulates network calls)
4. May succeed or fail randomly (simulates external service)

**Expected Behavior**:
- Shows loading/delay behavior
- Either succeeds or redirects to subscription required
- Handles errors gracefully

##### 6. **Blocking Guard Test** (`/blocking`)
**What it tests**: `resolver.block()` functionality

**Test Steps**:
1. Note the current minute in the status display
2. Click "Blocking Guard"
3. If minute is odd, should be blocked (stay on current page)
4. If minute is even, should succeed

**Expected Behavior**:
- Odd minutes: Stays on current page (blocked)
- Even minutes: Access granted

##### 7. **Legacy Guards Test** (`/legacy`)
**What it tests**: Backward compatibility with original guard system

**Test Steps**:
1. Click "Legacy Guards"
2. Should behave exactly like the old guard system
3. Requires authentication + user role (which everyone has by default)

**Expected Behavior**:
- Same behavior as original guards
- Demonstrates backward compatibility

### 🕒 Time-Based Testing

Some guards depend on time conditions:

#### Testing Different Hours
- **Custom Logic**: Even hours require admin access
- **Business Hours**: 9-17 for some guards (if implemented)

#### Testing Different Minutes  
- **Blocking Guard**: Odd minutes are blocked

#### Testing Different Months
- **Flexible Access**: December allows special access

### 🎭 Role-Based Testing

Test different role combinations:

#### Default State
- Roles: `['user']`
- Authenticated: `false`

#### Authenticated User
- Roles: `['user']`  
- Authenticated: `true`

#### Admin User
- Roles: `['user', 'admin']`
- Authenticated: `true`

#### Premium User  
- Roles: `['user', 'premium']`
- Authenticated: `true`

#### Super User
- Roles: `['user', 'admin', 'premium']`
- Authenticated: `true`

### 🔄 State Transition Testing

Test guard behavior when state changes:

1. **Start unauthenticated** → try protected route → should redirect to login
2. **Login** → try same route → should succeed (if roles match)
3. **Change roles** → try different routes → see different behaviors
4. **Logout** → try protected routes → should redirect to login again

### 📱 Navigation Flow Testing

Test the complete navigation flows:

#### Redirect After Login
1. Try to access protected route while unauthenticated
2. Should redirect to login with `?redirect=` parameter
3. After login, should redirect back to original destination

#### Error Handling
1. Test routes that simulate errors
2. Check graceful error handling and user feedback

#### Back Button Behavior
1. Test browser back button behavior
2. Ensure guards work correctly on back navigation

## 🐛 Debugging Tips

### Common Issues

1. **Guards not executing**: Check that routes have `redirect: (context, state) => route.executeGuards(context, state)`

2. **Infinite redirects**: Ensure guard logic has proper exit conditions

3. **State not updating**: Make sure BLoC providers are properly set up

4. **Type errors**: Verify guard types match (RouteGuard vs RouteGuardEnhanced)

### Debug Output

Add debug prints to guards for troubleshooting:

```dart
GuardsEnhanced.simple((resolver, context, state) {
  print('Guard executing for: ${state.fullPath}');
  // ... guard logic
  print('Guard result: allowing/redirecting/blocking');
});
```

### Flutter Inspector

Use Flutter Inspector to:
- Check widget tree structure
- Verify BLoC state values
- Debug navigation issues

## ✅ Testing Checklist

### Before Release
- [ ] All automated tests pass (`flutter test`)
- [ ] Manual test app runs without errors
- [ ] All guard types tested (legacy + enhanced)
- [ ] All factory methods tested
- [ ] Error scenarios tested
- [ ] Time-based conditions tested
- [ ] Role-based access tested
- [ ] Navigation flows tested
- [ ] Backward compatibility verified
- [ ] Performance tested (no significant delays)
- [ ] Documentation examples work

### Performance Testing
- [ ] Guards execute quickly (< 100ms for sync guards)
- [ ] Async guards show appropriate loading states
- [ ] No memory leaks during route transitions
- [ ] Smooth navigation experience

## 🚀 Next Steps

After testing:

1. **Report Issues**: Document any bugs or unexpected behaviors
2. **Performance Metrics**: Note any performance concerns
3. **UX Feedback**: Evaluate user experience of guard behaviors
4. **Documentation**: Update docs based on testing findings
5. **Examples**: Create additional examples for specific use cases

---

**Happy Testing! 🎉**

This comprehensive test suite ensures the enhanced guards system works reliably across all scenarios and maintains full backward compatibility with existing code. 