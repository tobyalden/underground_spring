package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import openfl.Assets;

class Level extends Entity
{
    private var walls:Grid;
    private var tiles:Tilemap;
    public var entities(default, null):Array<Entity>;

    public function new(levelName:String) {
        super(0, 0);
        type = "walls";
        loadLevel(levelName);
        updateGraphic();
        mask = walls;
    }

    override public function update() {
        super.update();
    }

    private function loadLevel(levelName:String) {
        var xml = new haxe.xml.Access(Xml.parse(Assets.getText('levels/${levelName}.oel')));

        // Load walls
        walls = new Grid(Std.parseInt(xml.node.level.att.width), Std.parseInt(xml.node.level.att.height), 10, 10);
        walls.loadFromString(xml.node.level.node.walls.innerData, "", "\n");

        // Load entities
        entities = new Array<Entity>();
        for(player in xml.node.level.node.entities.nodes.player) {
            entities.push(new Player(Std.parseInt(player.att.x), Std.parseInt(player.att.y) + 6));
        }
    }

    public function updateGraphic() {
        tiles = new Tilemap(
            'graphics/tiles.png',
            walls.width, walls.height, walls.tileWidth, walls.tileHeight
        );
        for(tileX in 0...walls.columns) {
            for(tileY in 0...walls.rows) {
                if(walls.getTile(tileX, tileY)) {
                    tiles.setTile(tileX, tileY, 0);
                }
            }
        }
        graphic = tiles;
    }
}

