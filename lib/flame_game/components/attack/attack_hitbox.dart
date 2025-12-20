import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:dino_run_in_flutter/flame_game/components/attack/attack_providers.dart';
import 'package:dino_run_in_flutter/flame_game/components/health/health_component.dart';

/// A hitbox component that deals damage to entities with [HealthComponent].
///
/// Emits [AttackHitEvent] through Riverpod when damage is dealt.
class AttackHitbox extends RectangleHitbox
    with RiverpodComponentMixin, ParentIsA<Component> {
  AttackHitbox({required int strength}) : _strength = strength, super() {
    _collisionActiveColor = Paint()
      ..color = const Color.fromARGB(100, 255, 0, 0);
    _collisionDeactiveColor = Paint()
      ..color = const Color.fromARGB(100, 255, 225, 0);
  }

  final int _strength;
  late final Paint _collisionActiveColor;
  late final Paint _collisionDeactiveColor;
  final Map<ShapeHitbox, bool> _hitTargets = {};

  /// The damage strength of this attack
  int get strength => _strength;

  @override
  Future<void> onLoad() async {
    scale = Vector2.all(0.8);
    return super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final hitAnyTarget = _hitTargets.values.any((hit) => hit);
    final paint = hitAnyTarget
        ? _collisionDeactiveColor
        : _collisionActiveColor;
    canvas.drawRect(size.toRect(), paint);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, ShapeHitbox other) {
    super.onCollisionStart(intersectionPoints, other);

    // Prevent multiple hits on the same target in one collision
    if (_hitTargets[other] == true) return;

    if (other is HealthComponent) {
      final damageDealt = other.takeDamage(_strength);
      _hitTargets[other] = true;

      // Emit attack hit event
      _emitAttackHit(target: other, damageDealt: damageDealt);
    }
  }

  @override
  void onCollisionEnd(ShapeHitbox other) {
    super.onCollisionEnd(other);

    _hitTargets.remove(other);
  }

  /// Emits an attack hit event through Riverpod.
  void _emitAttackHit({required Component target, required int damageDealt}) {
    ref
        .read(attackHitEventProvider.notifier)
        .emitAttackHit(
          attacker: parent,
          target: target,
          damageDealt: damageDealt,
        );
  }

  @override
  String toString() => 'AttackHitbox(strength: $_strength, size: $size)';
}
