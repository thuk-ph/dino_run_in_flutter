import 'package:dino_run_in_flutter/flame_game/components/health/health_providers.dart';
import 'package:dino_run_in_flutter/flame_game/endless_runner.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/painting.dart';
import 'package:logging/logging.dart';

/// A component that manages health for any component in the game.
///
/// Emits events through Riverpod when health changes or is depleted.
/// Supports defense to reduce incoming damage.
class HealthComponent extends CircleHitbox
    with
        HasGameReference<EndlessRunner>,
        RiverpodComponentMixin,
        ParentIsA<Component> {
  HealthComponent({required int initialHealth, int defense = 0})
    : _maxHealth = initialHealth,
      _health = initialHealth,
      _defense = defense,
      super() {
    _testColor = Paint()..color = const Color.fromARGB(100, 0, 255, 0);
  }

  final Logger _logger = Logger('HealthComponent');
  final int _maxHealth;
  final int _maxDamage = 9999;
  final int _maxDefense = 9999;
  int _health;
  int _defense;
  late final Paint _testColor;
  bool _isDead = false;

  /// Current health value
  int get health => _health;

  /// Maximum health this entity can have
  int get maxHealth => _maxHealth;

  /// Current defense value (reduces incoming damage)
  int get defense => _defense;

  /// Whether this entity's health is depleted
  bool get isDead => _isDead;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(size.toRect(), _testColor);
  }

  /// Reduces health by damage amount (accounting for defense).
  ///
  /// Returns the actual damage dealt.
  int takeDamage(int strength) {
    if (_isDead) return 0;

    final actualDamage = _calculateDamage(strength);
    final previousHealth = _health;
    _health -= actualDamage;

    // Emit health changed event
    _emitHealthChanged(previousHealth);

    // Check if health is depleted
    if (_health <= 0) {
      _isDead = true;
      _emitHealthDepleted();
    }

    return actualDamage;
  }

  /// Restores health by the given amount (capped at maxHealth).
  void heal(int amount) {
    if (_isDead || amount <= 0) return;

    final previousHealth = _health;
    _health = (_health + amount).clamp(0, _maxHealth);

    if (_health != previousHealth) {
      _emitHealthChanged(previousHealth);
    }
  }

  /// Changes the defense value (can be used by effects).
  void setDefense(int newDefense) {
    _defense = newDefense.clamp(0, _maxDefense);
  }

  /// Adds to the current defense value.
  void addDefense(int defenseBump) {
    _defense = (_defense + defenseBump).clamp(0, _maxDefense);
  }

  /// Calculates actual damage taken accounting for defense.
  ///
  /// Should always return a non-negative value.
  int _calculateDamage(int strength) {
    return (strength - _defense).clamp(0, _maxDamage);
  }

  /// Emits a health changed event through Riverpod.
  void _emitHealthChanged(int previousHealth) {
    ref
        .read(healthChangedEventProvider.notifier)
        .emitHealthChanged(
          previousHealth: previousHealth,
          currentHealth: _health,
          component: parent,
        );
    _logger.info('Health changed from $previousHealth to $_health for $parent');
  }

  /// Emits a health depleted event through Riverpod.
  void _emitHealthDepleted() {
    ref
        .read(healthDepletedEventProvider.notifier)
        .emitHealthDepleted(component: parent);
    _logger.info('Health depleted for $parent');
  }

  @override
  String toString() =>
      'HealthComponent(health: $_health/$_maxHealth, defense: $_defense, isDead: $_isDead)';
}
