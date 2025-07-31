import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_guards_example/router.dart';

// Example screens
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to the Home Screen!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ProtectedRoute().go(context),
              child: const Text('Go to Protected Route'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => AdminRoute().go(context),
              child: const Text('Go to Admin Route'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => context.read<AuthCubit>().toggleAuth(),
              child: const Text('Toggle Authentication'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => context.read<UserCubit>().toggleAdmin(),
              child: const Text('Toggle Admin Role'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Login Screen'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<AuthCubit>().login();
                HomeRoute().go(context);
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProtectedScreen extends StatelessWidget {
  const ProtectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Protected')),
      body: const Center(
        child: Text(
          'This is a protected route. '
          'If you see this, you are authenticated!',
        ),
      ),
    );
  }
}

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: const Center(
        child: Text(
          'This is an admin-only route. '
          'If you see this, you are an admin!',
        ),
      ),
    );
  }
}

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unauthorized')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You are not authorized to access this route.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => HomeRoute().go(context),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// Example state management
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState(isAuthenticated: false));

  void login() => emit(const AuthState(isAuthenticated: true));
  void logout() => emit(const AuthState(isAuthenticated: false));
  void toggleAuth() => emit(AuthState(isAuthenticated: !state.isAuthenticated));
}

class AuthState {
  const AuthState({required this.isAuthenticated});

  final bool isAuthenticated;
}

class UserCubit extends Cubit<UserState> {
  UserCubit() : super(const UserState(roles: ['user']));

  void toggleAdmin() {
    final newRoles = state.roles.contains('admin')
        ? state.roles.where((role) => role != 'admin').toList()
        : [...state.roles, 'admin'];
    emit(UserState(roles: newRoles));
  }

  void togglePremium() {
    final newRoles = state.roles.contains('premium')
        ? state.roles.where((role) => role != 'premium').toList()
        : [...state.roles, 'premium'];
    emit(UserState(roles: newRoles));
  }
}

class UserState {
  const UserState({required this.roles});

  final List<String> roles;
}
