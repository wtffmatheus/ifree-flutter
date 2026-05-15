import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark);

  void toggle() {
    state =
        state == ThemeMode.dark
            ? ThemeMode.light
            : ThemeMode.dark;
  }

  void set(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
      (ref) => ThemeModeNotifier(),
    );

class UserRoleNotifier extends StateNotifier<String> {
  UserRoleNotifier() : super('freelancer');

  void set(String role) {
    state = role;
  }
}

final userRoleProvider =
    StateNotifierProvider<UserRoleNotifier, String>(
      (ref) => UserRoleNotifier(),
    );