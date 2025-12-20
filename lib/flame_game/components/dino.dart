import 'package:dino_run_in_flutter/flame_game/components/health/health_component.dart';
import 'package:dino_run_in_flutter/flame_game/components/health/health_providers.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/animation.dart';
import 'package:riverpod/riverpod.dart';

import '../../audio/sounds.dart';
import '../effects/hurt_effect.dart';
import '../effects/jump_effect.dart';
import '../endless_runner.dart';
import '../endless_world.dart';
import 'point.dart';

/// The [Player] is the component that the physical player of the game is
/// controlling.
class Player extends SpriteAnimationGroupComponent<PlayerState>
    with
        CollisionCallbacks,
        HasWorldReference<EndlessWorld>,
        HasGameReference<EndlessRunner>,
        RiverpodComponentMixin {
  Player({required this.addScore, required this.resetScore, super.position})
    : super(size: Vector2.all(150), anchor: Anchor.center, priority: 1);

  final void Function({int amount}) addScore;
  final VoidCallback resetScore;

  // Sprite frame size in pixels
  static const double _frameSize = 24;

  // Determine how high the player can jump, multiplied by player's height.
  final double _jumpStrength = 2;

  // Whether the player has already used their double jump.
  bool _hasUsedDoubleJump = false;

  // The current velocity that the player has that comes from being affected by
  // the gravity. Defined in virtual pixels/s².
  double _gravityVelocity = 0;

  // Used to store the last position of the player, so that we later can
  // determine which direction that the player is moving.
  final Vector2 _lastPosition = Vector2.zero();

  // Whether the player is currently in the air, this can be used to restrict
  // movement for example.
  bool get inAir => (position.y + size.y / 2) < world.groundLevel;

  // When the player has velocity pointing downwards it is counted as falling,
  // this is used to set the correct animation for the player.
  bool get isFalling => _lastPosition.y < position.y;

  @override
  Future<void> onLoad() async {
    final assetPath = 'dinos/blue_doux.png';

    // This defines the different animation states that the player can be in.
    // Sprite sheet layout: 1 row with 24 frames (24x24 each)
    // Idle (0-3), Running (4-9), Kicking (10-13), Hurting (14-17), Sprinting (18-23);
    // Jump (single frame 7), Fall (single frame 10)
    animations = {
      PlayerState.idle: await game.loadSpriteAnimation(
        assetPath,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.1,
          textureSize: Vector2.all(_frameSize),
          texturePosition: Vector2(0 * _frameSize, 0),
        ),
      ),
      PlayerState.running: await game.loadSpriteAnimation(
        assetPath,
        SpriteAnimationData.sequenced(
          amount: 6,
          stepTime: 0.08,
          textureSize: Vector2.all(_frameSize),
          texturePosition: Vector2(4 * _frameSize, 0),
        ),
      ),
      PlayerState.kicking: await game.loadSpriteAnimation(
        assetPath,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.08,
          textureSize: Vector2.all(_frameSize),
          texturePosition: Vector2(10 * _frameSize, 0),
        ),
      ),
      PlayerState.hurting: await game.loadSpriteAnimation(
        assetPath,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.08,
          textureSize: Vector2.all(_frameSize),
          texturePosition: Vector2(14 * _frameSize, 0),
          loop: false,
        ),
      ),
      PlayerState.sprinting: await game.loadSpriteAnimation(
        assetPath,
        SpriteAnimationData.sequenced(
          amount: 6,
          stepTime: 0.08,
          textureSize: Vector2.all(_frameSize),
          texturePosition: Vector2(18 * _frameSize, 0),
          loop: false,
        ),
      ),
      PlayerState.jumping: SpriteAnimation.spriteList([
        await game.loadSprite(
          assetPath,
          srcSize: Vector2.all(_frameSize),
          srcPosition: Vector2(7 * _frameSize, 0),
        ),
      ], stepTime: double.infinity),
      PlayerState.falling: SpriteAnimation.spriteList([
        await game.loadSprite(
          assetPath,
          srcSize: Vector2.all(_frameSize),
          srcPosition: Vector2(10 * _frameSize, 0),
        ),
      ], stepTime: double.infinity),
    };
    // The starting state will be that the player is running.
    current = PlayerState.running;
    _lastPosition.setFrom(position);

    add(HealthComponent(initialHealth: 500));
  }

  @override
  void onMount() async {
    addToGameWidgetBuild(() {
      ref.listen(healthChangedEventProvider, (previous, healthChanged) {
        healthChanged.whenData((value) {
          if (this == value.component &&
              value.previousHealth > value.currentHealth) {
            current = PlayerState.hurting;

            game.audioController.playSfx(SfxType.damage);
            resetScore();
            add(HurtEffect());
          }
        });
      });
    });
    super.onMount();
  }

  @override
  void update(double dt) {
    super.update(dt);
    // When we are in the air the gravity should affect our position and pull
    // us closer to the ground.
    if (inAir) {
      _gravityVelocity += world.gravity * dt;
      position.y += _gravityVelocity;
      if (isFalling) {
        current = PlayerState.falling;
      }
    }

    final belowGround = position.y + size.y / 2 > world.groundLevel;
    // If the player's new position would overshoot the ground level after
    // updating its position we need to move the player up to the ground level
    // again.
    if (belowGround) {
      position.y = world.groundLevel - size.y / 2;
      _gravityVelocity = 0;
      current = PlayerState.running;
      _hasUsedDoubleJump = false;
    }

    _lastPosition.setFrom(position);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Point) {
      // When the player collides with a point it should gain a point and remove
      // the `Point` from the game.
      game.audioController.playSfx(SfxType.score);
      other.removeFromParent();
      addScore();
    }
  }

  void jump() {
    current = PlayerState.jumping;
    // Since `towards` is normalized we need to scale (multiply) that vector by
    // the length that we want the jump to have.
    final jumpEffect = JumpEffect(
      Vector2(0, -1)..scaleTo(_jumpStrength * size.y),
    );

    final canJump = !inAir || (inAir && !_hasUsedDoubleJump);
    if (canJump) {
      game.audioController.playSfx(SfxType.jump);
      add(jumpEffect);
      if (inAir) {
        _hasUsedDoubleJump = true;
      }
    }
  }
}

enum PlayerState {
  idle,
  running,
  kicking,
  hurting,
  sprinting,
  jumping,
  falling,
}
