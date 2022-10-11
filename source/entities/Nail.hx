package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import scenes.*;

class Nail extends Entity
{
    public static inline var GRAVITY = 600;
    public static inline var MAX_COLLECT_SPEED = 400;
    public static inline var TIME_TO_MAX_COLLECT_SPEED = 2;

    public var hasFired(default, null):Bool;
    public var hasCollided(default, null):Bool;
    public var hasLodged(default, null):Bool;
    public var lodgePoint(default, null):Vector2;
    public var sprite:Image;
    private var velocity:Vector2;
    private var angle:Float;
    private var speed:Float;
    private var spinSpeed:Float;

    public function new() {
        super();
        layer = 10;
        type = "nail";
        angle = 0;
        speed = 0;
        mask = new Hitbox(2, 2);
        sprite = new Image("graphics/nail.png");
        sprite.centerOrigin();
        sprite.x = 1;
        sprite.y = 1;
        graphic = sprite;
        velocity = new Vector2();
        spinSpeed = 0;
        collect();
        hasLodged = false;
    }

    public function fire(position:Vector2, speed:Float, angle:Float) {
        moveTo(position.x, position.y);
        this.speed = speed;
        this.angle = angle;
        sprite.x = 1;
        sprite.y = 1;
        sprite.angle = angle * -180 / Math.PI;
        layer = -10;
        hasFired = true;
    }

    public function dislodge(position:Vector2, speed:Float, angle:Float) {
        moveTo(position.x, position.y);
        this.speed = speed;
        this.angle = angle;
        velocity.x = Math.cos(angle);
        velocity.y = Math.sin(angle);
        velocity.normalize(speed);
        sprite.angle = angle * -180 / Math.PI;
        hasCollided = true;
        hasLodged = false;
        randomizeSpinSpeed();
    }

    public function collect() {
        hasFired = false;
        hasCollided = false;
        sprite.angle = -90;
    }

    override public function update() {
        collidable = hasFired;
        if(hasCollided) {
            sprite.alpha = 0.75;
        }
        else if(hasFired) {
            sprite.alpha = 1;
        }
        else {
            sprite.alpha = 0.5;
        }
        if(hasLodged) {
        }
        else if(hasFired) {
            if(hasCollided) {
                if(Input.check("collect")) {
                    var player = HXP.scene.getInstance("player");
                    var towardsPlayer = new Vector2(
                        player.centerX - centerX,
                        player.centerY - centerY
                    );
                    var lerpFactor = (
                        Math.min(Main.getTimeHeld("collect"), TIME_TO_MAX_COLLECT_SPEED)
                        / TIME_TO_MAX_COLLECT_SPEED
                    );
                    towardsPlayer.normalize(MAX_COLLECT_SPEED * lerpFactor);
                    velocity.x = MathUtil.lerp(
                        velocity.x, towardsPlayer.x, lerpFactor
                    );
                    velocity.y = MathUtil.lerp(
                        velocity.y, towardsPlayer.y, lerpFactor
                    );
                    sprite.angle = MathUtil.lerp(
                        sprite.angle,
                        MathUtil.angle(centerX, centerY, player.centerX, player.centerY),
                        lerpFactor
                    );
                }
                else {
                    sprite.angle += spinSpeed;
                    velocity.y += GRAVITY * HXP.elapsed;
                }
            }
            else {
                velocity.x = Math.cos(angle);
                velocity.y = Math.sin(angle);
                velocity.normalize(speed);
            }
            moveBy(velocity.x * HXP.elapsed, velocity.y * HXP.elapsed, "walls");
        }
        super.update();
    }

    override public function moveCollideX(_:Entity) {
        velocity.x = -velocity.x / 4;
        velocity.y = -40;
        onCollision();
        return true;
    }

    override public function moveCollideY(_:Entity) {
        velocity.x = velocity.x / 2;
        velocity.y = -velocity.y / 4;
        onCollision();
        if(velocity.length < 10) {
            velocity.x = 0;
            velocity.y = 0;
            spinSpeed = 0;
        }
        return true;
    }

    public function lodge(newLodgePoint:Vector2) {
        hasCollided = true;
        hasLodged = true;
        lodgePoint = newLodgePoint;
    }

    public function randomizeSpinSpeed() {
        spinSpeed = 10 + Math.random() * 20;
        if(velocity.x < 0) {
            spinSpeed = -spinSpeed;
        }
    }

    public function onCollision() {
        hasCollided = true;
        randomizeSpinSpeed();
    }
}
