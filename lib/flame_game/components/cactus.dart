import 'dart:math';

import 'package:dino_run_in_flutter/flame_game/components/attack/attack_hitbox.dart';
import 'package:dino_run_in_flutter/flame_game/endless_runner.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import '../endless_world.dart';

/// The [Cactus] component can represent two different types of obstacles
/// that the player can run into.
class Cactus extends SpriteComponent
    with HasGameReference<EndlessRunner>, HasWorldReference<EndlessWorld> {
  Cactus.small({super.position})
    : super(size: Vector2.all(128), anchor: Anchor.bottomLeft);

  Cactus.tall({super.position})
    : super(size: Vector2(192, 128), anchor: Anchor.bottomLeft);

  /// Generates a random obstacle of type [ObstacleType].
  factory Cactus.random({
    Vector2? position,
    Random? random,
    bool canSpawnTall = true,
  }) {
    final values = canSpawnTall
        ? const [CactusType.small, CactusType.tall]
        : const [CactusType.small];
    final cactusType = values.random(random);
    return switch (cactusType) {
      CactusType.small => Cactus.small(position: position),
      CactusType.tall => Cactus.tall(position: position),
    };
  }

  @override
  Future<void> onLoad() async {
    final assetPath = 'cactus/cactus_sprite_sheet.png';
    final double frameSize = 64;

    // Since all the obstacles reside in the same image, srcSize and srcPosition
    // are used to determine what part of the image that should be used.
    sprite = await game.loadSprite(
      assetPath,
      srcSize: Vector2.all(frameSize),
      srcPosition: Vector2(0 * frameSize, 0),
    );
    // When adding a RectangleHitbox without any arguments it automatically
    // fills up the size of the component.
    add(AttackHitbox(strength: 1));
  }

  @override
  void update(double dt) {
    // We need to move the component to the left together with the speed that we
    // have set for the world.
    // `dt` here stands for delta time and it is the time, in seconds, since the
    // last update ran. We need to multiply the speed by `dt` to make sure that
    // the speed of the obstacles are the same no matter the refresh rate/speed
    // of your device.
    position.x -= world.speed * dt;

    // When the component is no longer visible on the screen anymore, we
    // remove it.
    // The position is defined from the upper left corner of the component (the
    // anchor) and the center of the world is in (0, 0), so when the components
    // position plus its size in X-axis is outside of minus half the world size
    // we know that it is no longer visible and it can be removed.
    if (position.x + size.x < -world.size.x / 2) {
      removeFromParent();
    }
  }
}

enum CactusType { small, tall }
