package scenes;

import entities.*;
import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import openfl.Assets;

@:structInit class MapCoordinates {
    public var mapX:Int;
    public var mapY:Int;

    public function toKey():String {
        return '$mapX-$mapY';
    }

    static public function fromKey(key:String):MapCoordinates {
        var parts = key.split('-');
        return {mapX: Std.parseInt(parts[0]), mapY: Std.parseInt(parts[1])};
    }
}

@:structInit class SegmentIdentifier {
    public var id:Int;
    public var name:String;
    public var origin:MapCoordinates;
}

class GameScene extends Scene
{
    public static inline var CAMERA_BUFFER_X = 50;
    public static inline var CAMERA_SPEED = 1.5;
    public static inline var MAP_TILE_SIZE = 10;

    private var player:Player;
    private var lerpTimerX:Float;
    private var cameraStartX:Float;
    private var cameraTargetX:Float;
    private var currentSegment:Segment;
    private var currentCoordinates:MapCoordinates;
    private var map:Map<String, SegmentIdentifier>;

    override public function begin() {
        loadMap();
        lerpTimerX = 0;
        cameraStartX = getCameraTarget().x;
        cameraTargetX = getCameraTarget().x;
    }

    public function loadMap() {
        map = new Map<String, SegmentIdentifier>();

        // Load segments into map
        var xml = new haxe.xml.Access(Xml.parse(Assets.getText('maps/map.oel')));
        var id = 0;
        for(segment in xml.node.level.node.segments.nodes.segment) {
            var mapX = Std.int(Std.parseInt(segment.att.x) / MAP_TILE_SIZE);
            var mapY = Std.int(Std.parseInt(segment.att.y) / MAP_TILE_SIZE);
            var segmentWidth = Std.int(Std.parseInt(segment.att.width) / MAP_TILE_SIZE);
            var segmentHeight = Std.int(Std.parseInt(segment.att.height) / MAP_TILE_SIZE);
            for(widthX in 0...segmentWidth) {
                for(widthY in 0...segmentHeight) {
                    var coordinates:MapCoordinates = {mapX: mapX + widthX, mapY: mapY + widthY};
                    var identifier:SegmentIdentifier = {id: id, name: segment.att.name, origin: {mapX: mapX, mapY: mapY}};
                    map[coordinates.toKey()] = identifier;
                }
            }

            // Load start
            if(segment.att.name == "start") {
                var start = new Segment("start");
                start.offset(mapX, mapY);
                currentSegment = add(start);
                currentCoordinates = {mapX: mapX, mapY: mapY};
                for(entity in currentSegment.entities) {
                    if(entity.name == "player") {
                        player = cast(entity, Player);
                    }
                    add(entity);
                }
            }

            id++;
        }
    }

    public function loadSegment(coordinates:MapCoordinates) {
        var identifier = map[coordinates.toKey()];
        var segment = new Segment(identifier.name);
        segment.offset(identifier.origin.mapX, identifier.origin.mapY);
        remove(currentSegment);
        currentSegment = add(segment);
    }

    public function isTransition(oldCoordinates:MapCoordinates, newCoordinates:MapCoordinates) {
        if(oldCoordinates.toKey() == newCoordinates.toKey()) {
            return false;
        }
        if(!map.exists(oldCoordinates.toKey()) || !map.exists(newCoordinates.toKey())) {
            return false;
        }
        if(map[oldCoordinates.toKey()].id == map[newCoordinates.toKey()].id) {
            return false;
        }
        return true;
    }

    private function getCurrentCoordinates():MapCoordinates {
        return {
            mapX: Std.int(Math.floor(player.centerX / Segment.MIN_WIDTH)),
            mapY: Std.int(Math.floor(player.centerY / Segment.MIN_HEIGHT))
        };
    }

    override public function update() {
        var oldCoordinates:MapCoordinates = {mapX: currentCoordinates.mapX, mapY: currentCoordinates.mapY};
        currentCoordinates = getCurrentCoordinates();
        if(isTransition(oldCoordinates, currentCoordinates)) {
            loadSegment(currentCoordinates);
        }
        super.update();
        updateCamera();
    }

    private function updateCamera() {
        lerpTimerX += HXP.elapsed;
        cameraTargetX = getCameraTarget().x;
        if(player.sprite.flipX != player.prevFacing) {
            lerpTimerX = 0;
            cameraStartX = camera.x;
        }
        var linearLerp = Math.min(lerpTimerX * CAMERA_SPEED, 1);
        camera.x = MathUtil.lerp(
            cameraStartX,
            cameraTargetX,
            Math.sin(linearLerp * Math.PI / 2)
        );
        var cameraTargetY = player.centerY - HXP.height / 2;
        camera.y = getCameraTarget().y;
    }

    private function getCameraTarget() {
        var cameraBoundLeft = (
            player.centerX - HXP.width / 2 - CAMERA_BUFFER_X
        );
        var cameraBoundRight = (
            player.centerX - HXP.width / 2 + CAMERA_BUFFER_X
        );
        if(!player.sprite.flipX) {
            return new Vector2(cameraBoundRight, player.centerY - HXP.height / 2);
        }
        else {
            return new Vector2(cameraBoundLeft, player.centerY - HXP.height / 2);
        }
    }
}
