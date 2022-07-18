package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.masks.*;

class Vine extends Entity
{
    public function new(x:Float, y:Float, height:Int) {
        super(x, y);
        type = "vine";
        mask = new Hitbox(2, height);
        graphic = new TiledImage("graphics/vine.png", 10, height);
        graphic.x -= 4;
    }
}

