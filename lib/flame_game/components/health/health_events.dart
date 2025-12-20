import 'package:flame/components.dart';

/// Event emitted when a health component's health value changes
class HealthChangedEvent {
  HealthChangedEvent({
    required this.previousHealth,
    required this.currentHealth,
    required this.component,
  });

  final int previousHealth;
  final int currentHealth;
  final Component component;

  @override
  String toString() =>
      'HealthChangedEvent(component: ${component.hashCode}, $previousHealth → $currentHealth)';
}

/// Event emitted when a health component's health is depleted (drops below or equal to 0)
class HealthDepletedEvent {
  HealthDepletedEvent({required this.component});

  final Component component;

  @override
  String toString() => 'HealthDepletedEvent(component: ${component.hashCode})';
}
