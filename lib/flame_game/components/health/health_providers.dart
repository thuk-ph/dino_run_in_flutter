import 'package:flame/components.dart';
import "package:riverpod/riverpod.dart";
import 'package:dino_run_in_flutter/flame_game/components/health/health_events.dart';

final healthChangedEventProvider =
    StreamNotifierProvider<HealthChangedEventNotifier, HealthChangedEvent>(
      HealthChangedEventNotifier.new,
    );

final healthDepletedEventProvider =
    StreamNotifierProvider<HealthDepletedEventNotifier, HealthDepletedEvent>(
      HealthDepletedEventNotifier.new,
    );

class HealthChangedEventNotifier extends StreamNotifier<HealthChangedEvent> {
  @override
  Stream<HealthChangedEvent> build() {
    return Stream.empty();
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
    state = AsyncValue.data(event);
  }
}

class HealthDepletedEventNotifier extends StreamNotifier<HealthDepletedEvent> {
  @override
  Stream<HealthDepletedEvent> build() {
    return Stream.empty();
  }

  void emitHealthDepleted({required Component component}) {
    final event = HealthDepletedEvent(component: component);
    state = AsyncValue.data(event);
  }
}
