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

class GameScene extends Scene
{
    public static inline var CAMERA_BUFFER_X = 50;
    public static inline var CAMERA_SPEED = 1.5;

    private var level:Level;
    private var player:Player;
    private var lerpTimerX:Float;
    private var cameraStartX:Float;
    private var cameraTargetX:Float;

    override public function begin() {
        level = add(new Level("level"));
        for(entity in level.entities) {
            if(entity.name == "player") {
                player = cast(entity, Player);
            }
            add(entity);
        }
        lerpTimerX = 0;
        cameraStartX = 0;
        cameraTargetX = 0;
    }

    override public function update() {
        super.update();
        updateCamera();
    }

    private function updateCamera() {
        lerpTimerX += HXP.elapsed;
        var cameraBoundLeft = (
            player.centerX - HXP.width / 2 - CAMERA_BUFFER_X
        );
        var cameraBoundRight = (
            player.centerX - HXP.width / 2 + CAMERA_BUFFER_X
        );
        if(!player.sprite.flipX) {
            cameraTargetX = cameraBoundRight;
        }
        else {
            cameraTargetX = cameraBoundLeft;
        }
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
        camera.x = Math.round(camera.x);
    }
}
