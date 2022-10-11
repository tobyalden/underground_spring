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
    private var lodgedNails:Array<Nail>;

    //public static inline var MAX_RUN_SPEED = 150;
    public function new(x:Float, y:Float) {
        super(x, y);
        type = "enemy";
        mask = new Hitbox(30, 30);
        graphic = new ColoredRect(30, 30, 0xFF0000);
        velocity = new Vector2(20, 0);
        health = 20;
        lodgedNails = [];
    }

    override public function update() {
        var nails = [];
        collideInto("nail", x, y, nails);
        for(_nail in nails) {
            var nail = cast(_nail, Nail);
            if(!nail.hasCollided) {
                nail.lodge(new Vector2(
                    nail.x - x,
                    nail.y - y
                ));
                lodgedNails.push(nail);
                takeHit();
            }
        }
        moveBy(
            velocity.x * HXP.elapsed,
            velocity.y * HXP.elapsed,
            ["walls"]
        );
        for(nail in lodgedNails) {
            nail.moveTo(
                x + nail.lodgePoint.x,
                y + nail.lodgePoint.y
            );
        }
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
        for(nail in lodgedNails) {
            nail.dislodge(
                new Vector2(centerX, centerY),
                300,
                Math.PI * 2 * Math.random()
            );
        }
    }

    override public function moveCollideX(e:Entity) {
        velocity.x = -velocity.x;
        return true;
    }
}
