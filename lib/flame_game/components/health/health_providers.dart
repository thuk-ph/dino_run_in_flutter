import 'dart:async';

import 'package:flame/components.dart';
import "package:riverpod/riverpod.dart";
import 'package:dino_run_in_flutter/flame_game/components/health/health_events.dart';

final healthChangedEventProvider =
    AsyncNotifierProvider<HealthChangedEventNotifier, HealthChangedEvent>(
      HealthChangedEventNotifier.new,
    );

final healthDepletedEventProvider =
    AsyncNotifierProvider<HealthDepletedEventNotifier, HealthDepletedEvent>(
      HealthDepletedEventNotifier.new,
    );

class HealthChangedEventNotifier extends AsyncNotifier<HealthChangedEvent> {
  @override
  FutureOr<HealthChangedEvent> build() {
    return HealthChangedEvent(
      previousHealth: 0,
      currentHealth: 0,
      component: Component(),
    );
  }

  void emitHealthChanged({
    required int previousHealth,
    required int currentHealth,
    required Component component,
  }) {
    final event = HealthChangedEvent(
      previousHealth: previousHealth,
      currentHealth: currentHealth,
      component: component,
    );
    state = AsyncData(event);
  }
}

class HealthDepletedEventNotifier extends AsyncNotifier<HealthDepletedEvent> {
  @override
  FutureOr<HealthDepletedEvent> build() {
    return HealthDepletedEvent(component: Component());
  }

  void emitHealthDepleted({required Component component}) {
    final event = HealthDepletedEvent(component: component);
    state = AsyncData(event);
  }
}
