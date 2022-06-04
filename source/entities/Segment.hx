package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import openfl.Assets;

class Segment extends Entity
{
    public static inline var TILE_SIZE = 20;
    public static inline var MIN_WIDTH = 480;
    public static inline var MIN_HEIGHT = 360;

    public var entities(default, null):Array<Entity>;
    private var walls:Grid;
    private var tiles:Tilemap;

    public function new(segmentName:String) {
        super(0, 0);
        type = "walls";
        loadSegment(segmentName);
        updateGraphic();
        mask = walls;
    }

    override public function update() {
        super.update();
    }

    private function loadSegment(segmentName:String) {
        var xml = new haxe.xml.Access(Xml.parse(Assets.getText('segments/${segmentName}.oel')));

        // Load walls
        walls = new Grid(
            Std.parseInt(xml.node.level.att.width),
            Std.parseInt(xml.node.level.att.height),
            TILE_SIZE,
            TILE_SIZE
        );
        walls.loadFromString(xml.node.level.node.walls.innerData, "", "\n");

        // Load entities
        entities = new Array<Entity>();
        for(player in xml.node.level.node.entities.nodes.player) {
            entities.push(new Player(Std.parseInt(player.att.x), Std.parseInt(player.att.y) + 6));
        }
    }

    public function getWidthInMapTiles() {
        return Std.int(walls.width / MIN_WIDTH);
    }

    public function offset(segmentX:Int, segmentY:Int) {
        trace('offsetting to $segmentX, $segmentY');
        moveTo(segmentX * MIN_WIDTH, segmentY * MIN_HEIGHT);
        for(entity in entities) {
            entity.x += segmentX * MIN_WIDTH;
            entity.y += segmentY * MIN_HEIGHT;
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

