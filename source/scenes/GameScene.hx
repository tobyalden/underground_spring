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

typedef SegmentCoordinates = {
    var segmentX:Int;
    var segmentY:Int;
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
    private var map:Map<SegmentCoordinates, String>;

    override public function begin() {
        loadMap();
        lerpTimerX = 0;
        cameraStartX = getCameraTarget().x;
        cameraTargetX = getCameraTarget().x;
    }

    public function loadMap() {
        map = new Map<SegmentCoordinates, String>();

        // Load segments into map
        var xml = new haxe.xml.Access(Xml.parse(Assets.getText('maps/map.oel')));
        for(segment in xml.node.level.node.segments.nodes.segment) {
            var segmentX = Std.int(Std.parseInt(segment.att.x) / MAP_TILE_SIZE);
            var segmentY = Std.int(Std.parseInt(segment.att.y) / MAP_TILE_SIZE);
            var segmentWidth = Std.int(Std.parseInt(segment.att.width) / MAP_TILE_SIZE);
            var segmentHeight = Std.int(Std.parseInt(segment.att.height) / MAP_TILE_SIZE);
            for(widthX in 0...segmentWidth) {
                for(widthY in 0...segmentHeight) {
                    map[{segmentX: segmentX + widthX, segmentY: segmentY + widthY}] = segment.att.name;
                }
            }

            // Load start
            if(segment.att.name == "start") {
                trace('loading start');
                currentSegment = add(new Segment(segmentX, segmentY, "start"));
                for(entity in currentSegment.entities) {
                    if(entity.name == "player") {
                        player = cast(entity, Player);
                    }
                    add(entity);
                    trace("adding player");
                }
            }
        }
    }

    override public function update() {
        if(player.centerX < currentSegment.x) {
            //currentSegment.segmentX, currentSegment.segmentY
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
