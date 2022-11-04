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
    // TODO: this playerStart is kind of messy, can probably be replaced by something better (an entity, maybe)
    public var playerStart(default, null):Vector2 = null;
    private var walls:Grid;
    private var tiles:Tilemap;
    private var exits:Map<Int, Exit>;

    public function new(fileName:String) {
        super(0, 0);
        type = "walls";
        loadFromFile(fileName);
        updateGraphic();
        mask = walls;
    }

    override public function update() {
        super.update();
    }

    private function loadFromFile(fileName:String) {
        var xml = new haxe.xml.Access(Xml.parse(Assets.getText('segments/${fileName}.oel')));

        // Load walls
        walls = new Grid(
            Std.parseInt(xml.node.level.att.width),
            Std.parseInt(xml.node.level.att.height),
            TILE_SIZE,
            TILE_SIZE
        );
        walls.loadFromString(xml.node.level.node.walls.innerData, "", "\n");

        // Load entities & exits
        entities = new Array<Entity>();
        exits = new Map<Int, Exit>();
        for(player in xml.node.level.node.entities.nodes.player) {
            playerStart = new Vector2(Std.parseInt(player.att.x), Std.parseInt(player.att.y) + 6);
        }
        for(horizontalExit in xml.node.level.node.entities.nodes.horizontalExit) {
            var exit = new Exit(Std.parseInt(horizontalExit.att.x), Std.parseInt(horizontalExit.att.y), true);
            entities.push(exit);
            exits[Std.parseInt(horizontalExit.att.id)] = exit;
        }
        for(verticalExit in xml.node.level.node.entities.nodes.verticalExit) {
            var exit = new Exit(Std.parseInt(verticalExit.att.x), Std.parseInt(verticalExit.att.y), false);
            entities.push(exit);
            exits[Std.parseInt(verticalExit.att.id)] = exit;
        }
        for(vine in xml.node.level.node.entities.nodes.vine) {
            var vine = new Vine(Std.parseInt(vine.att.x) + 4, Std.parseInt(vine.att.y), Std.parseInt(vine.att.height));
            entities.push(vine);
        }
        for(chaser in xml.node.level.node.entities.nodes.chaser) {
            var chaser = new Chaser(Std.parseInt(chaser.att.x), Std.parseInt(chaser.att.y));
            entities.push(chaser);
        }
        for(boss in xml.node.level.node.entities.nodes.boss) {
            var boss = new Boss(Std.parseInt(boss.att.x), Std.parseInt(boss.att.y));
            entities.push(boss);
        }
    }

    public function getExitById(exitId:Int) {
        return exits.exists(exitId) ? exits[exitId] : null;
    }

    public function offset(segmentX:Int, segmentY:Int) {
        moveTo(segmentX * MIN_WIDTH, segmentY * MIN_HEIGHT);
        for(entity in entities) {
            entity.x += segmentX * MIN_WIDTH;
            entity.y += segmentY * MIN_HEIGHT;
        }
        if(playerStart != null) {
            playerStart.x += segmentX * MIN_WIDTH;
            playerStart.y += segmentY * MIN_HEIGHT;
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

