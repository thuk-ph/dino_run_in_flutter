import 'package:flame/components.dart';

/// Event emitted when an attack hitbox deals damage to a target
class AttackHitEvent {
  AttackHitEvent({
    required this.attacker,
    required this.target,
    required this.damageDealt,
  });

  final Component attacker;
  final Component target;
  final int damageDealt;

  @override
  String toString() =>
      'AttackHitEvent(attacker: ${attacker.hashCode}, target: ${target.hashCode}, damage: $damageDealt)';
}
