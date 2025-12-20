import 'package:flame/components.dart';
import 'package:riverpod/riverpod.dart';
import 'package:dino_run_in_flutter/flame_game/components/attack/attack_events.dart';

final attackHitEventProvider =
    StreamNotifierProvider<AttackHitEventNotifier, AttackHitEvent>(
      AttackHitEventNotifier.new,
    );

class AttackHitEventNotifier extends StreamNotifier<AttackHitEvent> {
  @override
  Stream<AttackHitEvent> build() {
    return Stream.empty();
  }

  void emitAttackHit({
    required Component attacker,
    required Component target,
    required int damageDealt,
  }) {
    final event = AttackHitEvent(
      attacker: attacker,
      target: target,
      damageDealt: damageDealt,
    );
    state = AsyncValue.data(event);
  }
}
