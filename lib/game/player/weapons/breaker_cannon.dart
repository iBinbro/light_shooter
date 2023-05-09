import 'dart:math';

import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import 'package:light_shooter/game/player/weapons/bullet_capsule.dart';
import 'package:light_shooter/game/util/player_spritesheet.dart';

class BreakerCannon extends GameComponent
    with Follower, UseSpriteAnimation, ChangeNotifier {
  double dt = 0;
  final double timeToReload = 5;
  final Color flash = const Color(0xFF73eff7).withOpacity(0.5);
  final bool withScreenEffect;
  final AttackFromEnum attackFrom;
  final PlayerColor color;
  final bool blockShootWithoutBullet;
  SpriteAnimation? _normalAnimation;
  SpriteAnimation? _reloadAnimation;
  int _countBullet = 5;
  bool reloading = false;
  double currentTimeReload = 0;
  BreakerCannon(
    this.color, {
    this.withScreenEffect = true,
    this.blockShootWithoutBullet = true,
    this.attackFrom = AttackFromEnum.PLAYER_OR_ALLY,
  }) {
    size = Vector2.all(64);
    setupFollower(offset: Vector2(0, 16));
  }

  @override
  void update(double dt) {
    this.dt = dt;
    isFlipHorizontally =
        (followerTarget as Movement).lastDirectionHorizontal != Direction.right;

    if (reloading) {
      currentTimeReload += dt;
      if (currentTimeReload >= timeToReload) {
        reloading = false;
        _countBullet = 5;
        animation = _normalAnimation;
      } else {
        animation = _reloadAnimation;
      }
      notifyListeners();
    }
    super.update(dt);
  }

  @override
  Future<void>? onLoad() async {
    _reloadAnimation = await PlayerSpriteSheet.gunReload(color);
    animation = _normalAnimation = await PlayerSpriteSheet.gun(color);
    return super.onLoad();
  }

  bool execShootAndChangeAngle(double radAngle, double damage) {
    changeAngle(radAngle);
    if (checkInterval('SHOOT_INTERVAL', 500, dt)) {
      execShoot(radAngle, damage);
      return true;
    }
    return false;
  }

  void execShoot(double radAngle, double damage) {
    if (_countBullet <= 0 && blockShootWithoutBullet) {
      return;
    }
    playSpriteAnimationOnce(
      PlayerSpriteSheet.gunShot(color),
    );
    simpleAttackRangeByAngle(
      animation: PlayerSpriteSheet.bullet,
      size: Vector2.all(32),
      angle: radAngle,
      damage: damage,
      speed: 300,
      collision: CollisionConfig(
        collisions: [
          CollisionArea.rectangle(
            size: Vector2.all(16),
            align: Vector2.all(16) / 2,
          )
        ],
      ),
      marginFromOrigin: -3,
      attackFrom: attackFrom,
    );
    if (withScreenEffect) {
      gameRef.camera.shake(intensity: 1);
      gameRef.colorFilter?.config.color = flash;
      gameRef.colorFilter?.animateTo(Colors.transparent);
    }

    gameRef.add(BulletCapsule(center, _getAnglecapsule(radAngle)));
    _countBullet--;
    if (_countBullet == 0) {
      currentTimeReload = 0;
      reloading = true;
    }
    notifyListeners();
  }

  void changeAngle(double radAngle) {
    angle = calculeNewAngle(radAngle);
  }

  double calculeNewAngle(double radAngle) {
    return radAngle + ((isFlipHorizontally && radAngle != 0) ? pi : 0);
  }

  double _getAnglecapsule(double radAngle) {
    double angle = radAngle + pi / 2;
    Direction angleDirection = BonfireUtil.getDirectionFromAngle(angle);
    if (angleDirection == Direction.down ||
        angleDirection == Direction.downLeft ||
        angleDirection == Direction.downRight) {
      angle += pi;
    }
    return angle;
  }

  void reload() {
    playSpriteAnimationOnce(
      PlayerSpriteSheet.gunReload(color),
    );
  }

  void addBullet(int count) {
    _countBullet = count;
  }

  int get countBullet => _countBullet;
}