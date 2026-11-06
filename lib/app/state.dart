import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navigation and theme belong to the app, independently of window layout.
enum AppDestination { tracks, albums, artists, settings }

class DestinationController extends Notifier<AppDestination> {
  @override
  AppDestination build() => AppDestination.tracks;

  void select(AppDestination destination) => state = destination;
}

final destinationProvider =
    NotifierProvider<DestinationController, AppDestination>(
      DestinationController.new,
    );

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void select(ThemeMode mode) => state = mode;
}

final themeProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);
