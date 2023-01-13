package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Chaser extends CombatEntity
{
    private var velocity:Vector2;
    private var health:Int;

    public static inline var MAX_RUN_SPEED = 150;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "enemy";
        mask = new Hitbox(30, 30);
        graphic = new ColoredRect(width, height, 0xFF0000);
        velocity = new Vector2(150, 0);
        health = 8;
    }

    override public function update() {
        var nails = [];
        collideInto("nail", x, y, nails);
        for(_nail in nails) {
            var nail = cast(_nail, Nail);
            if(!nail.hasCollided) {
                takeHit();
            }
        }
        moveBy(
            velocity.x * HXP.elapsed,
            velocity.y * HXP.elapsed,
            ["walls"]
        );
        super.update();
    }

    private function takeHit() {
        health -= 1;
        if(health <= 0) {
            die();
        }
    }

    private function die() {
        HXP.scene.remove(this);
        explode();
    }

    override public function moveCollideX(e:Entity) {
        velocity.x = -velocity.x;
        return true;
    }
}
