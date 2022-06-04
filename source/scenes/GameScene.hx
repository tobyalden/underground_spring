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

@:structInit class SegmentCoordinates {
    var segmentX:Int;
    var segmentY:Int;

    public function toKey():String {
        return '$segmentX-$segmentY';
    }

    static public function fromKey(key:String):SegmentCoordinates {
        var parts = key.split('-');
        return {segmentX: Std.parseInt(parts[0]), segmentY: Std.parseInt(parts[1])};
    }
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
    private var currentSegmentX:Int;
    private var currentSegmentY:Int;
    private var currentSegment:Segment;
    private var map:Map<String, String>;

    override public function begin() {
        loadMap();
        lerpTimerX = 0;
        cameraStartX = getCameraTarget().x;
        cameraTargetX = getCameraTarget().x;
    }

    public function loadMap() {
        map = new Map<String, String>();

        // Load segments into map
        var xml = new haxe.xml.Access(Xml.parse(Assets.getText('maps/map.oel')));
        for(segment in xml.node.level.node.segments.nodes.segment) {
            var segmentX = Std.int(Std.parseInt(segment.att.x) / MAP_TILE_SIZE);
            var segmentY = Std.int(Std.parseInt(segment.att.y) / MAP_TILE_SIZE);
            var segmentWidth = Std.int(Std.parseInt(segment.att.width) / MAP_TILE_SIZE);
            var segmentHeight = Std.int(Std.parseInt(segment.att.height) / MAP_TILE_SIZE);
            for(widthX in 0...segmentWidth) {
                for(widthY in 0...segmentHeight) {
                    var coordinates:SegmentCoordinates = {segmentX: segmentX + widthX, segmentY: segmentY + widthY};
                    map[coordinates.toKey()] = segment.att.name;
                }
            }

            // Load start
            if(segment.att.name == "start") {
                trace('loading start');
                var start = new Segment("start");
                start.offset(segmentX, segmentY);
                currentSegment = add(start);
                currentSegmentX = segmentX;
                currentSegmentY = segmentY;
                for(entity in currentSegment.entities) {
                    if(entity.name == "player") {
                        player = cast(entity, Player);
                    }
                    add(entity);
                }
            }
        }
        trace('loaded map: $map');
    }

    override public function update() {
        if(player.centerX < currentSegment.x) {
            var coordinates:SegmentCoordinates = {segmentX: currentSegmentX - 1, segmentY: currentSegmentY};
            if(map.exists(coordinates.toKey())) {
                var segment = new Segment(map[coordinates.toKey()]);
                segment.offset(currentSegmentX - segment.getWidthInMapTiles(), currentSegmentY);
                remove(currentSegment);
                currentSegment = add(segment);
            }
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
