package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;

class Exit extends Entity
{
    public function new(x:Float, y:Float, isHorizontal:Bool) {
        super(x, y);
        if(isHorizontal) {
            mask = new Hitbox(10, 40);
        }
        else {
            mask = new Hitbox(40, 10);
        }
        graphic = new ColoredRect(width, height, 0xFFFF00);
    }
}
