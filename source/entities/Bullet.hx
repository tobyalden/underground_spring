package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import scenes.*;

typedef BulletOptions = {
    var width:Int;
    var height:Int;
    var angle:Float;
    var speed:Float;
    var shotByPlayer:Bool;
    var collidesWithWalls:Bool;
    @:optional var bulletType:String;
    @:optional var callback:Bullet->Void;
    @:optional var callbackDelay:Float;
    @:optional var color:Int;
}

class Bullet extends Entity
{
    public var velocity:Vector2;
    public var sprite:ColoredRect;
    public var angle:Float;
    public var speed:Float;
    public var bulletOptions:BulletOptions;

    public function new(x:Float, y:Float, bulletOptions:BulletOptions) {
        super(x - bulletOptions.width / 2, y - bulletOptions.height / 2);
        this.bulletOptions = bulletOptions;
        type = bulletOptions.shotByPlayer ? "playerbullet" : "hazard";
        this.angle = bulletOptions.angle - Math.PI / 2;
        this.speed = bulletOptions.speed;
        mask = new Hitbox(bulletOptions.width, bulletOptions.height);
        var color = bulletOptions.color == null ? 0xFFFFFF : bulletOptions.color;
        sprite = new ColoredRect(width, height, color);
        graphic = sprite;
        velocity = new Vector2();
        var callbackDelay = (
            bulletOptions.callbackDelay == null ? 0 : bulletOptions.callbackDelay
        );
        if(bulletOptions.callback != null) {
            addTween(new Alarm(callbackDelay, function() {
                bulletOptions.callback(this);
            }), true);
        }
    }

    override public function moveCollideX(_:Entity) {
        onCollision();
        return true;
    }

    override public function moveCollideY(_:Entity) {
        onCollision();
        return true;
    }

    public function onCollision() {
        scene.remove(this);
    }

    override public function update() {
        velocity.x = Math.cos(angle);
        velocity.y = Math.sin(angle);
        velocity.normalize(speed);
        if(bulletOptions.collidesWithWalls) {
            moveBy(velocity.x * HXP.elapsed, velocity.y * HXP.elapsed, "walls");
        }
        else {
            moveBy(velocity.x * HXP.elapsed, velocity.y * HXP.elapsed);
        }
        super.update();
    }
}
