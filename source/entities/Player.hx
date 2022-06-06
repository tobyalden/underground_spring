package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Player extends Entity
{
    public static inline var RUN_SPEED = 150;
    public static inline var RUN_ACCEL = 500;
    public static inline var AIR_ACCEL = 300;
    public static inline var GRAVITY = 520;
    public static inline var JUMP_POWER = 260;
    public static inline var JUMP_CANCEL = 50;
    public static inline var MAX_FALL_SPEED = 400;

    public static inline var SHOT_SPEED = 300;
    public static inline var SHOT_KNOCKBACK = 100;

    public var sprite(default, null):Spritemap;
    public var prevFacing(default, null):Bool;
    private var velocity:Vector2;
    private var jumpDirectionBuffer:Alarm;

    public function new(x:Float, y:Float) {
        super(x, y);
        name = "player";
        mask = new Hitbox(12, 24);
        sprite = new Spritemap("graphics/player.png", 16, 32);
        sprite.x = -2;
        sprite.y = -8;
        sprite.add("idle", [0]);
        sprite.add("run", [1, 2, 3, 2], 8);
        sprite.add("jump", [4]);
        sprite.add("fall", [5]);
        sprite.add("crouch", [6]);
        sprite.play("idle");
        graphic = sprite;
        velocity = new Vector2();
        jumpDirectionBuffer = new Alarm(0.1);
        addTween(jumpDirectionBuffer);
    }

    override public function update() {
        combat();
        movement();
        animation();
        super.update();
    }

    private function movement() {
        if(isOnGround() || jumpDirectionBuffer.active && velocity.x == 0) {
            if(Input.check("left") && !isOnLeftWall()) {
                velocity.x -= RUN_ACCEL * HXP.elapsed;
            }
            else if(Input.check("right") && !isOnRightWall()) {
                velocity.x += RUN_ACCEL * HXP.elapsed;
            }
            else {
                velocity.x = MathUtil.approach(velocity.x, 0, RUN_ACCEL * HXP.elapsed);
            }
        }
        else {
            if(Input.check("left") && !isOnLeftWall()) {
                velocity.x -= AIR_ACCEL * HXP.elapsed;
            }
            else if(Input.check("right") && !isOnRightWall()) {
                velocity.x += AIR_ACCEL * HXP.elapsed;
            }
            else {
                velocity.x = MathUtil.approach(velocity.x, 0, AIR_ACCEL * HXP.elapsed);
            }
        }

        velocity.x = MathUtil.clamp(velocity.x, -RUN_SPEED, RUN_SPEED);

        if(isOnGround()) {
            velocity.y = 0;
            if(Input.pressed("jump")) {
                velocity.y = -JUMP_POWER;
                jumpDirectionBuffer.start();
            }
        }
        else {
            var gravity:Float = GRAVITY;
            if(Math.abs(velocity.y) < JUMP_CANCEL) {
                gravity *= 0.5;
            }
            velocity.y += gravity * HXP.elapsed;
            if(Input.released("jump") && velocity.y < -JUMP_CANCEL) {
                velocity.y = -JUMP_CANCEL;
            }
        }

        velocity.y = Math.min(velocity.y, MAX_FALL_SPEED);

        moveBy(velocity.x * HXP.elapsed, velocity.y * HXP.elapsed, ["walls"]);
    }

    private function combat() {
        if(Input.pressed("shoot")) {
            var bulletVelocity = new Vector2(sprite.flipX ? -1 : 1, 0);
            bulletVelocity.normalize(SHOT_SPEED);
            var bullet = new Bullet(
                centerX, centerY,
                {
                    width: 8,
                    height: 4,
                    angle: sprite.flipX ? -Math.PI / 2: Math.PI / 2,
                    speed: 800,
                    shotByPlayer: true,
                    collidesWithWalls: true
                }
            );
            HXP.scene.add(bullet);
            velocity.x += SHOT_KNOCKBACK * (sprite.flipX ? 1 : -1);
        }
    }

    override public function moveCollideX(e:Entity) {
        velocity.x = 0;
        return true;
    }

    override public function moveCollideY(e:Entity) {
        if(velocity.y < 0) {
            velocity.y = JUMP_CANCEL;
        }
        return true;
    }

    private function isOnGround() {
        return collide("walls", x, y + 1) != null;
    }

    private function isOnLeftWall() {
        return collide("walls", x - 1, y) != null;
    }

    private function isOnRightWall() {
        return collide("walls", x + 1, y) != null;
    }

    private function animation() {
        prevFacing = sprite.flipX;
        if(Input.check("left")) {
            sprite.flipX = true;
        }
        else if(Input.check("right")) {
            sprite.flipX = false;
        }

        if(isOnGround()) {
            if(velocity.x != 0) {
                sprite.play("run");
            }
            else {
                sprite.play("idle");
            }
        }
        else {
            if(velocity.y < JUMP_CANCEL) {
                sprite.play("jump");
            }
            else {
                sprite.play("fall");
            }
        }
    }
}
