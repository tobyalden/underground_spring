package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Chaser extends Entity
{
    //public static inline var MAX_RUN_SPEED = 150;
    public function new(x:Float, y:Float) {
        super(x, y);
        type = "enemy";
        mask = new Hitbox(30, 30);
        graphic = new ColoredRect(30, 30, 0xFF0000);
    }
}
