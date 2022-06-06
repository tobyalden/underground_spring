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
    public var exits:ExitIds;
}

@:structInit class ExitIds {
    public var top:Int = -1;
    public var bottom:Int = -1;
    public var left:Int = -1;
    public var right:Int = -1;
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

                    // Look up exit IDs
                    var segmentXml = new haxe.xml.Access(Xml.parse(Assets.getText('segments/${segment.att.name}.oel')));
                    var exits:ExitIds = {};
                    for(horizontalExit in segmentXml.node.level.node.entities.nodes.horizontalExit) {
                        if(Std.parseInt(horizontalExit.att.x) == 0) {
                            exits.left = Std.parseInt(horizontalExit.att.id);
                        }
                        else {
                            exits.right = Std.parseInt(horizontalExit.att.id);
                        }
                    }
                    for(verticalExit in segmentXml.node.level.node.entities.nodes.verticalExit) {
                        if(Std.parseInt(verticalExit.att.y) == 0) {
                            exits.top = Std.parseInt(verticalExit.att.id);
                        }
                        else {
                            exits.bottom = Std.parseInt(verticalExit.att.id);
                        }
                    }

                    var identifier:SegmentIdentifier = {
                        id: id,
                        name: segment.att.name,
                        origin: {mapX: mapX, mapY: mapY},
                        exits: exits
                    };
                    map[coordinates.toKey()] = identifier;
                }
            }

            // Load start
            if(segment.att.name == "start") {
                var start = new Segment("start");
                start.offset(mapX, mapY);
                for(entity in start.entities) {
                    add(entity);
                }
                player = add(new Player(start.playerStart.x, start.playerStart.y));
                currentSegment = add(start);
                currentCoordinates = {mapX: mapX, mapY: mapY};
            }

            id++;
        }
    }

    public function loadSegment(coordinates:MapCoordinates) {
        var identifier = map[coordinates.toKey()];
        var segment = new Segment(identifier.name);
        segment.offset(identifier.origin.mapX, identifier.origin.mapY);
        for(entity in currentSegment.entities) {
            remove(entity);
        }
        remove(currentSegment);
        currentSegment = add(segment);
        for(entity in currentSegment.entities) {
            add(entity);
        }
    }

    public function isTransition(oldCoordinates:MapCoordinates) {
        if(oldCoordinates.toKey() == currentCoordinates.toKey()) {
            return false;
        }
        if(!map.exists(oldCoordinates.toKey()) || !map.exists(currentCoordinates.toKey())) {
            return false;
        }
        if(map[oldCoordinates.toKey()].id == map[currentCoordinates.toKey()].id) {
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

    private function getSegmentExit(oldCoordinates:MapCoordinates) {
        var exitId = -1;
        if(oldCoordinates.mapX > currentCoordinates.mapX) {
            exitId = map[currentCoordinates.toKey()].exits.right;
        }
        else if(oldCoordinates.mapX < currentCoordinates.mapX) {
            exitId = map[currentCoordinates.toKey()].exits.left;
        }
        else if(oldCoordinates.mapY > currentCoordinates.mapY) {
            exitId = map[currentCoordinates.toKey()].exits.bottom;
        }
        else if(oldCoordinates.mapY < currentCoordinates.mapY) {
            exitId = map[currentCoordinates.toKey()].exits.top;
        }
        return currentSegment.getExitById(exitId);
    }

    override public function update() {
        var oldCoordinates:MapCoordinates = {mapX: currentCoordinates.mapX, mapY: currentCoordinates.mapY};
        currentCoordinates = getCurrentCoordinates();
        if(isTransition(oldCoordinates)) {
            loadSegment(currentCoordinates);
            var exit = getSegmentExit(oldCoordinates);
            player.moveTo(exit.centerX - player.width / 2, exit.centerY - player.height / 2);
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
        camera.x = MathUtil.clamp(camera.x, currentSegment.x, currentSegment.x + currentSegment.width - Segment.MIN_WIDTH);
        camera.y = MathUtil.clamp(camera.y, currentSegment.y, currentSegment.y + currentSegment.height - Segment.MIN_HEIGHT);
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
