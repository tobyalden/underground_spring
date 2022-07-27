package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.masks.*;

class UI extends Entity
{
    private var hearts:Graphiclist;

    public function new() {
        super(0, 0);
        hearts = new Graphiclist([]);
        for(i in 0...10) {
            var heart = new Image("graphics/heart.png");
            hearts.add(heart);
            heart.x = i * (heart.width + 2);
        }
        hearts.x = 10;
        hearts.y = 10;
        var allSprites = new Graphiclist([hearts]);
        graphic = allSprites;
        graphic.scrollX = 0;
        graphic.scrollY = 0;
    }

    override public function update() {
        var player = cast(HXP.scene.getInstance("player"), Player);
        for(i in 0...hearts.count) {
            hearts.get(i).visible = i < player.health;
        }
        super.update();
    }
}


