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
    public static inline var MAX_RUN_SPEED = 150;
    public static inline var RUN_ACCEL = 500;
    public static inline var AIR_ACCEL = 300;
    public static inline var GRAVITY = 520;
    public static inline var JUMP_POWER = 260;
    public static inline var JUMP_CANCEL = 50;
    public static inline var MAX_FALL_SPEED = 400;
    public static inline var JUMP_DIRECTION_BUFFER = 0.3;

    public static inline var CLIMB_UP_SPEED = 80;
    public static inline var CLIMB_DOWN_SPEED = CLIMB_UP_SPEED * 1.5;
    public static inline var CLIMB_COOLDOWN = 0.25;

    public static inline var FLIGHT_ACCEL = 1000;
    public static inline var MAX_FLIGHT_SPEED = 250;

    public static inline var SHOT_COOLDOWN = 0.25;
    public static inline var SHOT_BUFFER = 5;

    public var sprite(default, null):Spritemap;
    public var prevFacing(default, null):Bool;
    public var health(default, null):Int;

    private var velocity:Vector2;
    private var jumpDirectionBuffer:Alarm;

    private var isClimbing:Bool;
    private var climbCooldown:Alarm;

    private var isFlying:Bool;

    private var shotCooldown:Alarm;

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
        sprite.add("climb", [7]);
        sprite.play("idle");
        graphic = sprite;
        velocity = new Vector2();
        jumpDirectionBuffer = new Alarm(JUMP_DIRECTION_BUFFER);
        addTween(jumpDirectionBuffer);
        climbCooldown = new Alarm(CLIMB_COOLDOWN);
        addTween(climbCooldown);
        isFlying = false;
        shotCooldown = new Alarm(SHOT_COOLDOWN);
        addTween(shotCooldown);
        health = 3;
    }

    override public function update() {
        isFlying = Input.check("fly") && !isClimbing;

        var vine = collide("vine", x, y);
        if(isClimbing) {
            if(vine == null) {
                isClimbing = false;
            }
        }
        else {
            if(vine != null && Input.check("up") && !climbCooldown.active && !isFlying) {
                x = vine.centerX - width / 2;
                isClimbing = true;
            }
        }

        if(isClimbing) {
            climb();
        }
        if(!isClimbing) {
            if(isFlying) {
                flightMovement();
            }
            else {
                movement();
            }
        }
        moveBy(
            velocity.x * HXP.elapsed,
            velocity.y * HXP.elapsed,
            ["walls"]
        );
        combat();
        animation();
        super.update();
    }

    private function climb() {
        velocity.x = 0;
        if(Input.check("up")) {
            velocity.y = -CLIMB_UP_SPEED;
        }
        else if(Input.check("down")) {
            velocity.y = CLIMB_DOWN_SPEED;
        }
        else {
            velocity.y = 0;
        }

        if(Input.pressed("jump")) {
            isClimbing = false;
            if(!Input.check("down")) {
                velocity.y = -JUMP_POWER;
            }
            climbCooldown.start();
        }
    }

    private function flightMovement() {
        if(Input.check("left")) {
            velocity.x -= FLIGHT_ACCEL * HXP.elapsed;
        }
        else if(Input.check("right")) {
            velocity.x += FLIGHT_ACCEL * HXP.elapsed;
        }
        else {
            velocity.x = MathUtil.approach(velocity.x, 0, HXP.elapsed * FLIGHT_ACCEL);
        }
        if(Input.check("up")) {
            velocity.y -= FLIGHT_ACCEL * HXP.elapsed;
        }
        else if(Input.check("down")) {
            velocity.y += FLIGHT_ACCEL * HXP.elapsed;
        }
        else {
            velocity.y = MathUtil.approach(velocity.y, 0, HXP.elapsed * FLIGHT_ACCEL);
        }
        if(velocity.length > MAX_FLIGHT_SPEED) {
            velocity.normalize(MAX_FLIGHT_SPEED);
        }
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

        velocity.x = MathUtil.clamp(velocity.x, -MAX_FLIGHT_SPEED, MAX_FLIGHT_SPEED);
        var decel = isOnGround() ? RUN_ACCEL * 2 : AIR_ACCEL;
        if(Math.abs(velocity.x) > MAX_RUN_SPEED) {
            velocity.x = MathUtil.approach(
                velocity.x,
                MAX_RUN_SPEED * MathUtil.sign(velocity.x),
                decel * HXP.elapsed
            );
        }

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

    }

    private function combat() {
        if(Main.inputPressedBuffer("shoot", SHOT_BUFFER) && !shotCooldown.active) {
            var bullet = new Bullet(
                centerX, centerY,
                {
                    width: 16,
                    height: 8,
                    angle: sprite.flipX ? -Math.PI / 2: Math.PI / 2,
                    speed: 500,
                    shotByPlayer: true,
                    collidesWithWalls: true
                }
            );
            HXP.scene.add(bullet);
            shotCooldown.start();
        }
    }

    override public function moveCollideX(e:Entity) {
        velocity.x = 0;
        return true;
    }

    override public function moveCollideY(e:Entity) {
        if(velocity.y < 0 && !isFlying) {
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

        if(isClimbing) {
            sprite.play("climb");
        }
        else if(isOnGround()) {
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
