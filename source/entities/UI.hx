package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.text.*;
import haxepunk.graphics.tile.*;
import haxepunk.masks.*;
import haxepunk.math.*;

class UI extends Entity
{
    public var roomInfo:Text;
    private var hearts:Graphiclist;
    private var fuel:Image;

    public function new() {
        super(0, 0);
        layer = -10;
        hearts = new Graphiclist([]);
        for(i in 0...10) {
            var heart = new Image("graphics/heart.png");
            hearts.add(heart);
            heart.x = i * (heart.width + 2);
        }
        hearts.x = 10;
        hearts.y = 10;
        
        fuel = new Image("graphics/fuel.png");
        fuel.x = hearts.x;
        fuel.y = hearts.y + cast(hearts.get(0), Image).height + 6;

        roomInfo = new Text("debug", {size: 24, color: 0x00FF00});
        roomInfo.y = HXP.height - roomInfo.height;

        var allSprites = new Graphiclist([hearts, fuel, roomInfo]);
        graphic = allSprites;
        graphic.scrollX = 0;
        graphic.scrollY = 0;
    }

    override public function update() {
        var player = cast(HXP.scene.getInstance("player"), Player);
        for(i in 0...hearts.count) {
            hearts.get(i).visible = i < player.health;
        }
        fuel.scaleX = player.fuel / 100;
        super.update();
    }
}


